-- ==============================================================================
-- DATABASE TABLE DEFINITIONS SCRIPT: tables.sql
-- Project: Freelance & Client Management System with Freelancer Income & Client Analytics
-- Architecture: 3NF Normalized Relational Schema
-- ==============================================================================

USE freelance_management;

-- ------------------------------------------------------------------------------
-- 1. Table: roles
-- Purpose: System permission roles defining access control levels.
-- Dependency Level: 0 (Parent Entity)
-- ------------------------------------------------------------------------------
CREATE TABLE roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL,
    description VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_roles_role_name UNIQUE (role_name)
);

-- ------------------------------------------------------------------------------
-- 2. Table: users
-- Purpose: Stores user authentication credentials, profiles, and account states.
-- Dependency Level: 0 (Parent Entity)
-- ------------------------------------------------------------------------------
CREATE TABLE users (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT chk_users_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED'))
);

-- ------------------------------------------------------------------------------
-- 3. Table: user_roles
-- Purpose: Junction table establishing Many-to-Many mapping between users & roles.
-- Dependency Level: 1 (Depends on users, roles)
-- ------------------------------------------------------------------------------
CREATE TABLE user_roles (
    user_id BIGINT NOT NULL,
    role_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles (role_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ------------------------------------------------------------------------------
-- 4. Table: skills
-- Purpose: Technical competencies and domain skills possessed by freelancers.
-- Dependency Level: 0 (Parent Entity)
-- ------------------------------------------------------------------------------
CREATE TABLE skills (
    skill_id INT AUTO_INCREMENT PRIMARY KEY,
    skill_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    CONSTRAINT uq_skills_name UNIQUE (skill_name)
);

-- ------------------------------------------------------------------------------
-- 5. Table: freelancer_skills
-- Purpose: Junction table mapping skills to freelancer users with proficiency levels.
-- Dependency Level: 1 (Depends on users, skills)
-- ------------------------------------------------------------------------------
CREATE TABLE freelancer_skills (
    user_id BIGINT NOT NULL,
    skill_id INT NOT NULL,
    proficiency_level VARCHAR(20) NOT NULL DEFAULT 'INTERMEDIATE',
    PRIMARY KEY (user_id, skill_id),
    CONSTRAINT fk_freelancer_skills_user FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_freelancer_skills_skill FOREIGN KEY (skill_id) REFERENCES skills (skill_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_freelancer_skills_level CHECK (proficiency_level IN ('BEGINNER', 'INTERMEDIATE', 'EXPERT'))
);

-- ------------------------------------------------------------------------------
-- 6. Table: clients
-- Purpose: Corporate and individual client profiles, billing metadata, and terms.
-- Dependency Level: 0 (Parent Entity)
-- ------------------------------------------------------------------------------
CREATE TABLE clients (
    client_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(200) NOT NULL,
    tax_identifier VARCHAR(50) NULL,
    currency_code CHAR(3) NOT NULL DEFAULT 'INR',
    payment_terms_days INT NOT NULL DEFAULT 30,
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    billing_address TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_clients_payment_terms CHECK (payment_terms_days >= 0),
    CONSTRAINT chk_clients_status CHECK (status IN ('LEAD', 'ACTIVE', 'INACTIVE', 'FLAGGED_LATE'))
);

-- ------------------------------------------------------------------------------
-- 7. Table: client_contacts
-- Purpose: Contact individuals associated with client companies (1:N with clients).
-- Dependency Level: 1 (Depends on clients)
-- ------------------------------------------------------------------------------
CREATE TABLE client_contacts (
    contact_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    client_id BIGINT NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(30) NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_client_contacts_client FOREIGN KEY (client_id) REFERENCES clients (client_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ------------------------------------------------------------------------------
-- 8. Table: expense_categories
-- Purpose: Standardized category classifications for business overhead and expenses.
-- Dependency Level: 0 (Parent Entity)
-- ------------------------------------------------------------------------------
CREATE TABLE expense_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    is_tax_deductible BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_expense_categories_name UNIQUE (category_name)
);

-- ------------------------------------------------------------------------------
-- 9. Table: projects
-- Purpose: Service contracts, budgets, billing models, and timelines per client.
-- Dependency Level: 1 (Depends on clients)
-- ------------------------------------------------------------------------------
CREATE TABLE projects (
    project_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    client_id BIGINT NOT NULL,
    project_name VARCHAR(200) NOT NULL,
    description TEXT NULL,
    billing_model VARCHAR(30) NOT NULL DEFAULT 'FIXED_PRICE',
    hourly_rate DECIMAL(10, 2) NULL,
    total_budget DECIMAL(12, 2) NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PROPOSED',
    start_date DATE NOT NULL,
    target_end_date DATE NULL,
    actual_end_date DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_projects_client FOREIGN KEY (client_id) REFERENCES clients (client_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_projects_billing_model CHECK (billing_model IN ('FIXED_PRICE', 'HOURLY', 'RETAINER')),
    CONSTRAINT chk_projects_hourly_rate CHECK (hourly_rate IS NULL OR hourly_rate >= 0.00),
    CONSTRAINT chk_projects_total_budget CHECK (total_budget IS NULL OR total_budget >= 0.00),
    CONSTRAINT chk_projects_status CHECK (status IN ('PROPOSED', 'ACTIVE', 'ON_HOLD', 'COMPLETED', 'CANCELLED'))
);

-- ------------------------------------------------------------------------------
-- 10. Table: milestones
-- Purpose: Phase deliverables and payment thresholds for fixed-price contracts.
-- Dependency Level: 2 (Depends on projects)
-- ------------------------------------------------------------------------------
CREATE TABLE milestones (
    milestone_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_id BIGINT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    due_date DATE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    approved_at TIMESTAMP NULL,
    CONSTRAINT fk_milestones_project FOREIGN KEY (project_id) REFERENCES projects (project_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_milestones_amount CHECK (amount >= 0.00),
    CONSTRAINT chk_milestones_status CHECK (status IN ('PENDING', 'IN_PROGRESS', 'SUBMITTED', 'APPROVED', 'INVOICED'))
);

-- ------------------------------------------------------------------------------
-- 11. Table: tasks
-- Purpose: Work breakdown structure (WBS) items under projects.
-- Dependency Level: 2 (Depends on projects)
-- ------------------------------------------------------------------------------
CREATE TABLE tasks (
    task_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_id BIGINT NOT NULL,
    task_name VARCHAR(200) NOT NULL,
    estimated_hours DECIMAL(6, 2) NULL DEFAULT 0.00,
    status VARCHAR(30) NOT NULL DEFAULT 'TODO',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tasks_project FOREIGN KEY (project_id) REFERENCES projects (project_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_tasks_estimated_hours CHECK (estimated_hours IS NULL OR estimated_hours >= 0.00),
    CONSTRAINT chk_tasks_status CHECK (status IN ('TODO', 'IN_PROGRESS', 'COMPLETED'))
);

-- ------------------------------------------------------------------------------
-- 12. Table: time_entries
-- Purpose: Billable and non-billable time logs linked to tasks and freelancers.
-- Dependency Level: 3 (Depends on tasks, users)
-- ------------------------------------------------------------------------------
CREATE TABLE time_entries (
    time_entry_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    task_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    entry_date DATE NOT NULL,
    hours_logged DECIMAL(5, 2) NOT NULL,
    is_billable BOOLEAN NOT NULL DEFAULT TRUE,
    is_invoiced BOOLEAN NOT NULL DEFAULT FALSE,
    work_description TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_time_entries_task FOREIGN KEY (task_id) REFERENCES tasks (task_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_time_entries_user FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_time_entries_hours CHECK (hours_logged > 0.00 AND hours_logged <= 24.00)
);

-- ------------------------------------------------------------------------------
-- 13. Table: invoices
-- Purpose: Financial billing headers issued to clients.
-- Dependency Level: 2 (Depends on clients, projects)
-- ------------------------------------------------------------------------------
CREATE TABLE invoices (
    invoice_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    invoice_number VARCHAR(50) NOT NULL,
    client_id BIGINT NOT NULL,
    project_id BIGINT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    currency_code CHAR(3) NOT NULL DEFAULT 'INR',
    subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    tax_rate_percent DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    late_fee_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_invoices_number UNIQUE (invoice_number),
    CONSTRAINT fk_invoices_client FOREIGN KEY (client_id) REFERENCES clients (client_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_invoices_project FOREIGN KEY (project_id) REFERENCES projects (project_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_invoices_amounts CHECK (subtotal >= 0.00 AND tax_amount >= 0.00 AND discount_amount >= 0.00 AND late_fee_amount >= 0.00 AND total_amount >= 0.00),
    CONSTRAINT chk_invoices_tax_rate CHECK (tax_rate_percent >= 0.00 AND tax_rate_percent <= 100.00),
    CONSTRAINT chk_invoices_status CHECK (status IN ('DRAFT', 'ISSUED', 'PARTIALLY_PAID', 'PAID', 'OVERDUE', 'VOID'))
);

-- ------------------------------------------------------------------------------
-- 14. Table: invoice_items
-- Purpose: Itemized line items on invoices for milestones or billable hours.
-- Dependency Level: 4 (Depends on invoices, milestones, time_entries)
-- ------------------------------------------------------------------------------
CREATE TABLE invoice_items (
    item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    invoice_id BIGINT NOT NULL,
    milestone_id BIGINT NULL,
    time_entry_id BIGINT NULL,
    description VARCHAR(255) NOT NULL,
    quantity DECIMAL(8, 2) NOT NULL DEFAULT 1.00,
    unit_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    line_total DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_invoice_items_invoice FOREIGN KEY (invoice_id) REFERENCES invoices (invoice_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_invoice_items_milestone FOREIGN KEY (milestone_id) REFERENCES milestones (milestone_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_invoice_items_time_entry FOREIGN KEY (time_entry_id) REFERENCES time_entries (time_entry_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_invoice_items_quantity CHECK (quantity > 0.00),
    CONSTRAINT chk_invoice_items_price CHECK (unit_price >= 0.00),
    CONSTRAINT chk_invoice_items_line_total CHECK (line_total >= 0.00)
);

-- ------------------------------------------------------------------------------
-- 15. Table: payments
-- Purpose: Incoming monetary transactions settled against invoices.
-- Dependency Level: 3 (Depends on invoices)
-- ------------------------------------------------------------------------------
CREATE TABLE payments (
    payment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    invoice_id BIGINT NOT NULL,
    payment_date DATE NOT NULL,
    amount_paid DECIMAL(12, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL DEFAULT 'BANK_TRANSFER',
    transaction_reference VARCHAR(100) NULL,
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payments_invoice FOREIGN KEY (invoice_id) REFERENCES invoices (invoice_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_payments_amount CHECK (amount_paid > 0.00)
);

-- ------------------------------------------------------------------------------
-- 16. Table: expenses
-- Purpose: Outgoing operational and project expenses for profit margin calculation.
-- Dependency Level: 2 (Depends on expense_categories, projects, clients)
-- ------------------------------------------------------------------------------
CREATE TABLE expenses (
    expense_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    project_id BIGINT NULL,
    client_id BIGINT NULL,
    expense_date DATE NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    currency_code CHAR(3) NOT NULL DEFAULT 'INR',
    description TEXT NULL,
    receipt_ref VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_expenses_category FOREIGN KEY (category_id) REFERENCES expense_categories (category_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_expenses_project FOREIGN KEY (project_id) REFERENCES projects (project_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_expenses_client FOREIGN KEY (client_id) REFERENCES clients (client_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_expenses_amount CHECK (amount > 0.00)
);

-- ------------------------------------------------------------------------------
-- 17. Table: project_reviews
-- Purpose: Client ratings and feedback for completed projects.
-- Dependency Level: 2 (Depends on projects, clients, users)
-- ------------------------------------------------------------------------------
CREATE TABLE project_reviews (
    review_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    project_id BIGINT NOT NULL,
    client_id BIGINT NOT NULL,
    freelancer_id BIGINT NOT NULL,
    rating DECIMAL(2, 1) NOT NULL,
    feedback_text TEXT NULL,
    review_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_reviews_project UNIQUE (project_id),
    CONSTRAINT fk_reviews_project FOREIGN KEY (project_id) REFERENCES projects (project_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_client FOREIGN KEY (client_id) REFERENCES clients (client_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_freelancer FOREIGN KEY (freelancer_id) REFERENCES users (user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_reviews_rating CHECK (rating >= 1.0 AND rating <= 5.0)
);

-- ------------------------------------------------------------------------------
-- 18. Table: audit_logs
-- Purpose: Security logging and audit trail for financial/system transactions.
-- Dependency Level: 1 (Depends on users)
-- ------------------------------------------------------------------------------
CREATE TABLE audit_logs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NULL,
    action_type VARCHAR(50) NOT NULL,
    entity_affected VARCHAR(50) NOT NULL,
    entity_id BIGINT NULL,
    change_summary TEXT NULL,
    ip_address VARCHAR(45) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_logs_user FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE SET NULL ON UPDATE CASCADE
);
