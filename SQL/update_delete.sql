-- ==============================================================================
-- DATABASE BUSINESS TRANSACTIONS SCRIPT: update_delete.sql
-- Project: Freelance & Client Management System with Freelancer Income & Client Analytics
-- Purpose: Realistic UPDATE and DELETE operations simulating business lifecycle events.
-- ==============================================================================

USE freelance_management;

-- ------------------------------------------------------------------------------
-- 1. SCENARIO: Project Completion & Actual End Date Finalization
-- Business Context: Project #4 ("GraphQL API Gateway Development") deliverables have been 
-- successfully accepted by the client. The project status is updated to 'COMPLETED'
-- and the actual completion date is stamped.
-- ------------------------------------------------------------------------------
UPDATE projects
SET 
    status = 'COMPLETED',
    actual_end_date = '2025-07-28'
WHERE project_id = 4;

-- ------------------------------------------------------------------------------
-- 2. SCENARIO: Invoice Settlement & Status Transition to PAID
-- Business Context: Client #18 settled the full balance of pending Invoice #30 (INV-2025-030).
-- The invoice status transitions from 'ISSUED' to 'PAID'.
-- ------------------------------------------------------------------------------
UPDATE invoices
SET 
    status = 'PAID'
WHERE invoice_id = 30;

-- ------------------------------------------------------------------------------
-- 3. SCENARIO: Client Primary Contact Information Update
-- Business Context: Client contact Jennifer Adams at Nexus Tech Solutions changed her email 
-- address and direct office phone extension.
-- ------------------------------------------------------------------------------
UPDATE client_contacts
SET 
    email = 'jennifer.adams@nexustech-global.io',
    phone_number = '+1-415-555-9900'
WHERE contact_id = 2;

-- ------------------------------------------------------------------------------
-- 4. SCENARIO: Freelancer Hourly Billing Rate Adjustment
-- Business Context: Following a annual rate renegotiation, the billable hourly rate for
-- Project #4 is increased from $105.00/hr to $120.00/hr.
-- ------------------------------------------------------------------------------
UPDATE projects
SET 
    hourly_rate = 120.00
WHERE project_id = 4 AND billing_model = 'HOURLY';

-- ------------------------------------------------------------------------------
-- 5. SCENARIO: Project Cancellation & Scope Freeze
-- Business Context: Client #4 halted Project #7 ("FastAPI Microservices Overhaul") due to 
-- corporate budget reallocation. The project state transitions to 'CANCELLED'.
-- ------------------------------------------------------------------------------
UPDATE projects
SET 
    status = 'CANCELLED',
    actual_end_date = '2025-07-20'
WHERE project_id = 7;

-- ------------------------------------------------------------------------------
-- 6. SCENARIO: Expense Amount Accounting Correction
-- Business Context: An accounting audit identified that hardware expense #4 (MacBook Pro)
-- was entered with an incorrect tax offset. The expense amount is corrected from $2499.00 to $2399.00.
-- ------------------------------------------------------------------------------
UPDATE expenses
SET 
    amount = 2399.00,
    description = 'MacBook Pro M3 Max Workstation (Corrected post-audit invoice)'
WHERE expense_id = 4;

-- ------------------------------------------------------------------------------
-- 7. SCENARIO: Client Credit Risk Flagging for Overdue Invoices
-- Business Context: Client #22 (Prime Real Estate Tech) has defaulted past 30 days on pending
-- invoice balance. The CRM client status is flagged as 'FLAGGED_LATE'.
-- ------------------------------------------------------------------------------
UPDATE clients
SET 
    status = 'FLAGGED_LATE'
WHERE client_id = 22;

-- ------------------------------------------------------------------------------
-- 8. SCENARIO: Applying Late Payment Fee to Overdue Invoice
-- Business Context: Invoice #36 (INV-2025-036) is 30 days overdue. A 2% late penalty fee
-- ($235.40) is applied to the invoice balance.
-- ------------------------------------------------------------------------------
UPDATE invoices
SET 
    late_fee_amount = 235.40,
    total_amount = total_amount + 235.40,
    status = 'OVERDUE'
WHERE invoice_id = 36;

-- ------------------------------------------------------------------------------
-- 9. SCENARIO: Deleting Unworked Task Under Restructured Project
-- Business Context: Task #18 ("Setup GraphQL Subscription WebSockets") was declared out of scope
-- during project backlog grooming and has zero logged billable time entries.
-- ------------------------------------------------------------------------------
DELETE FROM tasks
WHERE task_id = 18 AND status = 'TODO';

-- ------------------------------------------------------------------------------
-- 10. SCENARIO: Deleting Outdated Freelancer Skill Assignment
-- Business Context: Freelancer #6 removed 'FastAPI Microservices' (Skill ID #10) from their primary
-- public profile portfolio.
-- ------------------------------------------------------------------------------
DELETE FROM freelancer_skills
WHERE user_id = 6 AND skill_id = 10;

-- ------------------------------------------------------------------------------
-- 11. SCENARIO: Deleting Unissued Draft Invoice & Associated Items
-- Business Context: Draft invoice #80 was generated in error and must be purged before billing run.
-- Line items are deleted first, followed by the invoice header.
-- ------------------------------------------------------------------------------
DELETE FROM invoice_items
WHERE invoice_id = 80;

DELETE FROM invoices
WHERE invoice_id = 80 AND status = 'DRAFT';
