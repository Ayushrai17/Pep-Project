-- ==============================================================================
-- DATABASE TRIGGERS SCRIPT: triggers.sql
-- Project: Freelance & Client Management System with Freelancer Income & Client Analytics
-- Purpose: Enforces automated data integrity rules, audit logging, and state synchronization.
-- ==============================================================================

USE freelance_management;

DELIMITER //

-- ------------------------------------------------------------------------------
-- Trigger 1: trg_validate_payment_before_insert
-- Timing / Event: BEFORE INSERT ON payments
-- Purpose: Prevents overpayment beyond total invoice amount and blocks payments on DRAFT or VOID invoices.
-- ------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_validate_payment_before_insert//
CREATE TRIGGER trg_validate_payment_before_insert
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE v_invoice_status VARCHAR(30);
    DECLARE v_invoice_total DECIMAL(12, 2);
    DECLARE v_already_paid DECIMAL(12, 2);

    -- Fetch current invoice total and status
    SELECT status, total_amount INTO v_invoice_status, v_invoice_total
    FROM invoices
    WHERE invoice_id = NEW.invoice_id;

    -- Block payment on DRAFT or VOID invoices
    IF v_invoice_status IN ('DRAFT', 'VOID') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Trigger Error: Cannot record payment on an unissued (DRAFT) or cancelled (VOID) invoice.';
    END IF;

    -- Calculate total payments recorded so far
    SELECT COALESCE(SUM(amount_paid), 0.00) INTO v_already_paid
    FROM payments
    WHERE invoice_id = NEW.invoice_id;

    -- Prevent payment if it exceeds total payable amount
    IF (v_already_paid + NEW.amount_paid) > (v_invoice_total + 0.01) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Trigger Error: Payment amount exceeds the remaining unpaid invoice balance.';
    END IF;
END//


-- ------------------------------------------------------------------------------
-- Trigger 2: trg_auto_update_project_status_after_milestone
-- Timing / Event: AFTER UPDATE ON milestones
-- Purpose: Automatically updates parent project status to 'COMPLETED' when all milestone deliverables are approved.
-- ------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_auto_update_project_status_after_milestone//
CREATE TRIGGER trg_auto_update_project_status_after_milestone
AFTER UPDATE ON milestones
FOR EACH ROW
BEGIN
    DECLARE v_pending_milestones INT DEFAULT 0;

    -- Check if any unapproved/pending milestones remain for this project
    SELECT COUNT(*) INTO v_pending_milestones
    FROM milestones
    WHERE project_id = NEW.project_id
      AND status NOT IN ('APPROVED', 'INVOICED');

    -- If all milestones are approved/invoiced, transition project status to COMPLETED
    IF v_pending_milestones = 0 THEN
        UPDATE projects
        SET 
            status = 'COMPLETED',
            actual_end_date = COALESCE(actual_end_date, CURRENT_DATE())
        WHERE project_id = NEW.project_id AND status = 'ACTIVE';
    END IF;
END//


-- ------------------------------------------------------------------------------
-- Trigger 3: trg_log_expense_changes_after_update
-- Timing / Event: AFTER UPDATE ON expenses
-- Purpose: Automatically logs modifications to financial expense records into audit_logs for compliance.
-- ------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_log_expense_changes_after_update//
CREATE TRIGGER trg_log_expense_changes_after_update
AFTER UPDATE ON expenses
FOR EACH ROW
BEGIN
    -- Log audit trail entry if expense amount or category was modified
    IF (OLD.amount <> NEW.amount) OR (OLD.category_id <> NEW.category_id) THEN
        INSERT INTO audit_logs (
            user_id, action_type, entity_affected, entity_id, change_summary, created_at
        ) VALUES (
            NULL,
            'EXPENSE_MODIFIED',
            'expenses',
            NEW.expense_id,
            CONCAT('Expense #', NEW.expense_id, ' updated. Old Amount: $', OLD.amount, ', New Amount: $', NEW.amount, '; Old Category: ', OLD.category_id, ', New Category: ', NEW.category_id),
            CURRENT_TIMESTAMP
        );
    END IF;
END//

DELIMITER ;
