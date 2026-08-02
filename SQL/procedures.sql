-- ==============================================================================
-- STORED PROCEDURES SCRIPT: procedures.sql
-- Project: Freelance & Client Management System with Freelancer Income & Client Analytics
-- Purpose: Encapsulates transactional business logic, parameter validation, and status handling.
-- ==============================================================================

USE freelance_management;

DELIMITER //

-- ------------------------------------------------------------------------------
-- Procedure 1: sp_add_project
-- Purpose: Safely onboards a new project contract for an active client with validation.
-- Parameters:
--   IN p_client_id BIGINT          : Target client ID
--   IN p_project_name VARCHAR(200) : Project title
--   IN p_description TEXT          : Scope summary
--   IN p_billing_model VARCHAR(30) : FIXED_PRICE, HOURLY, or RETAINER
--   IN p_hourly_rate DECIMAL(10,2) : Rate per hour (if applicable)
--   IN p_total_budget DECIMAL(12,2): Total contract budget cap
--   IN p_start_date DATE           : Project start date
--   IN p_target_end_date DATE      : Target completion date
--   OUT p_new_project_id BIGINT    : Returns the generated project ID
-- ------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_add_project//
CREATE PROCEDURE sp_add_project(
    IN p_client_id BIGINT,
    IN p_project_name VARCHAR(200),
    IN p_description TEXT,
    IN p_billing_model VARCHAR(30),
    IN p_hourly_rate DECIMAL(10,2),
    IN p_total_budget DECIMAL(12,2),
    IN p_start_date DATE,
    IN p_target_end_date DATE,
    OUT p_new_project_id BIGINT
)
BEGIN
    DECLARE v_client_exists INT DEFAULT 0;
    DECLARE v_client_status VARCHAR(30);

    -- 1. Validate client existence & status
    SELECT COUNT(*), MAX(status) INTO v_client_exists, v_client_status
    FROM clients
    WHERE client_id = p_client_id;

    IF v_client_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Invalid Client ID. Client record does not exist.';
    END IF;

    IF v_client_status = 'INACTIVE' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Cannot create project for an INACTIVE client.';
    END IF;

    -- 2. Validate billing model enum
    IF p_billing_model NOT IN ('FIXED_PRICE', 'HOURLY', 'RETAINER') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Invalid Billing Model. Must be FIXED_PRICE, HOURLY, or RETAINER.';
    END IF;

    -- 3. Validate dates
    IF p_target_end_date IS NOT NULL AND p_target_end_date < p_start_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Target completion date cannot be earlier than start date.';
    END IF;

    -- 4. Execute Insert Transaction
    INSERT INTO projects (
        client_id, project_name, description, billing_model,
        hourly_rate, total_budget, status, start_date, target_end_date
    ) VALUES (
        p_client_id, p_project_name, p_description, p_billing_model,
        p_hourly_rate, p_total_budget, 'PROPOSED', p_start_date, p_target_end_date
    );

    SET p_new_project_id = LAST_INSERT_ID();
END//


-- ------------------------------------------------------------------------------
-- Procedure 2: sp_generate_invoice
-- Purpose: Generates a new invoice header record with tax and discount validation.
-- Parameters:
--   IN p_client_id BIGINT             : Target client ID
--   IN p_project_id BIGINT            : Linked project ID (optional)
--   IN p_invoice_number VARCHAR(50)   : Unique invoice document number
--   IN p_issue_date DATE              : Invoice issue date
--   IN p_due_date DATE                : Payment deadline date
--   IN p_tax_rate_percent DECIMAL(5,2): Tax percentage (0.00 - 100.00)
--   IN p_discount_amount DECIMAL(12,2): Flat discount amount
--   OUT p_new_invoice_id BIGINT       : Returns generated invoice ID
-- ------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_generate_invoice//
CREATE PROCEDURE sp_generate_invoice(
    IN p_client_id BIGINT,
    IN p_project_id BIGINT,
    IN p_invoice_number VARCHAR(50),
    IN p_issue_date DATE,
    IN p_due_date DATE,
    IN p_tax_rate_percent DECIMAL(5,2),
    IN p_discount_amount DECIMAL(12,2),
    OUT p_new_invoice_id BIGINT
)
BEGIN
    DECLARE v_client_exists INT DEFAULT 0;
    DECLARE v_client_currency CHAR(3);

    -- 1. Validate Client & Fetch Currency
    SELECT COUNT(*), MAX(currency_code) INTO v_client_exists, v_client_currency
    FROM clients
    WHERE client_id = p_client_id;

    IF v_client_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Target client does not exist.';
    END IF;

    -- 2. Validate Invoice Dates
    IF p_due_date < p_issue_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Invoice due date cannot be prior to issue date.';
    END IF;

    -- 3. Validate Tax Rate Range
    IF p_tax_rate_percent < 0.00 OR p_tax_rate_percent > 100.00 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Tax rate percentage must be between 0.00 and 100.00.';
    END IF;

    -- 4. Execute Insert Header
    INSERT INTO invoices (
        invoice_number, client_id, project_id, issue_date, due_date,
        currency_code, subtotal, tax_rate_percent, tax_amount, discount_amount,
        late_fee_amount, total_amount, status
    ) VALUES (
        p_invoice_number, p_client_id, p_project_id, p_issue_date, p_due_date,
        v_client_currency, 0.00, p_tax_rate_percent, 0.00, p_discount_amount,
        0.00, 0.00, 'DRAFT'
    );

    SET p_new_invoice_id = LAST_INSERT_ID();
END//


-- ------------------------------------------------------------------------------
-- Procedure 3: sp_record_payment
-- Purpose: Records a payment transaction against an invoice and updates invoice status.
-- Parameters:
--   IN p_invoice_id BIGINT             : Target invoice ID
--   IN p_payment_date DATE             : Payment settlement date
--   IN p_amount_paid DECIMAL(12,2)     : Amount paid
--   IN p_payment_method VARCHAR(50)    : Settlement method
--   IN p_transaction_reference VARCHAR : Reference code / Txn ID
--   IN p_notes TEXT                    : Reconciliation notes
--   OUT p_new_payment_id BIGINT        : Returns payment transaction ID
-- ------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_record_payment//
CREATE PROCEDURE sp_record_payment(
    IN p_invoice_id BIGINT,
    IN p_payment_date DATE,
    IN p_amount_paid DECIMAL(12,2),
    IN p_payment_method VARCHAR(50),
    IN p_transaction_reference VARCHAR(100),
    IN p_notes TEXT,
    OUT p_new_payment_id BIGINT
)
BEGIN
    DECLARE v_invoice_exists INT DEFAULT 0;
    DECLARE v_invoice_status VARCHAR(30);
    DECLARE v_total_invoice_amount DECIMAL(12,2);
    DECLARE v_prior_payments_sum DECIMAL(12,2);
    DECLARE v_new_total_paid DECIMAL(12,2);

    -- 1. Validate Invoice Existence & Current Status
    SELECT COUNT(*), MAX(status), MAX(total_amount)
    INTO v_invoice_exists, v_invoice_status, v_total_invoice_amount
    FROM invoices
    WHERE invoice_id = p_invoice_id;

    IF v_invoice_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Invoice record not found.';
    END IF;

    IF v_invoice_status = 'VOID' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Cannot record payment against a VOID invoice.';
    END IF;

    IF v_invoice_status = 'PAID' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Invoice is already fully settled (PAID).';
    END IF;

    IF p_amount_paid <= 0.00 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Payment amount must be greater than 0.00.';
    END IF;

    -- 2. Insert Payment Record
    INSERT INTO payments (
        invoice_id, payment_date, amount_paid, payment_method, transaction_reference, notes
    ) VALUES (
        p_invoice_id, p_payment_date, p_amount_paid, p_payment_method, p_transaction_reference, p_notes
    );

    SET p_new_payment_id = LAST_INSERT_ID();

    -- 3. Calculate Cumulative Payments & Update Invoice Status
    SELECT COALESCE(SUM(amount_paid), 0.00) INTO v_prior_payments_sum
    FROM payments
    WHERE invoice_id = p_invoice_id;

    IF v_prior_payments_sum >= v_total_invoice_amount THEN
        UPDATE invoices SET status = 'PAID' WHERE invoice_id = p_invoice_id;
    ELSE
        UPDATE invoices SET status = 'PARTIALLY_PAID' WHERE invoice_id = p_invoice_id;
    END IF;
END//

DELIMITER ;
