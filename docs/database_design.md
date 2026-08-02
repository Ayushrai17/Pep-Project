# Relational Database Architecture Specification (3NF Normalized)

## Project Title
**Freelance & Client Management System with Freelancer Income & Client Analytics (FCMS Analytics)**

---

## 1. List of All Entities (Tables)

1. **`roles`**: System roles defining permissions (Admin, Accountant, Client).
2. **`users`**: Authentication credentials and profile details for system actors.
3. **`user_roles`**: Mapping table establishing many-to-many relationship between users and roles.
4. **`clients`**: Corporate and individual client profiles with billing configurations.
5. **`client_contacts`**: Key point-of-contact individuals associated with client companies.
6. **`projects`**: Service contracts and projects assigned to clients.
7. **`milestones`**: Project phase deliverables, payment thresholds, and approval statuses.
8. **`tasks`**: Work items under projects for activity tracking and hour estimation.
9. **`time_entries`**: Granular billable and non-billable time logs linked to tasks and users.
10. **`invoices`**: Financial invoice headers generated for clients.
11. **`invoice_items`**: Line-item details representing milestone payouts or aggregated billable hours on invoices.
12. **`payments`**: Payment transactions recorded against outstanding invoices.
13. **`expense_categories`**: Standardized classifications for business and project expenses.
14. **`expenses`**: Outgoing costs incurred, linked to projects, categories, and tax deductibility flags.
15. **`audit_logs`**: System audit trail logging critical operational and financial events.

---

## 2. Table Rationale & Architectural Purpose

| Table Name | Why the Table Exists (Architectural Purpose) |
| :--- | :--- |
| **`roles`** | Centralizes system permission sets to avoid hardcoding access controls in application logic. |
| **`users`** | Encapsulates user identity, security credentials, and baseline user account attributes. |
| **`user_roles`** | Normalizes user-role assignment (3NF compliance) to support multi-role assignments without multi-valued columns. |
| **`clients`** | Stores core client business metadata, payment terms, default currency, and risk indicators. |
| **`client_contacts`** | Decouples individual contacts from company accounts, allowing multiple points of contact per client company without duplicate client data. |
| **`projects`** | Acts as the operational hub linking clients to budgets, billing types (`Fixed`, `Hourly`, `Retainer`), and timelines. |
| **`milestones`** | Tracks fixed-price project progress, deliverable approval state, and payment trigger thresholds. |
| **`tasks`** | Organizes work breakdown structures (WBS) under projects for granular time logging and effort estimation. |
| **`time_entries`** | Captures exact time spent by freelancers on tasks; forms the foundation for hourly billing and Effective Hourly Rate (EHR) calculations. |
| **`invoices`** | Stores financial transaction headers, tax rates, payment due dates, and official invoice lifecycle status. |
| **`invoice_items`** | Provides 1NF atomic itemization of invoice charges (milestone payouts, billable hour packages, or custom fees). |
| **`payments`** | Tracks incoming monetary transactions, payment methods, transaction reference IDs, and partial invoice settlements. |
| **`expense_categories`** | Standardizes expense classification (e.g., Software Subscriptions, Contractor Fees, Travel) for tax and profit reporting. |
| **`expenses`** | Tracks gross and project-attributable operational expenditures to enable true net profit and margin analytics. |
| **`audit_logs`** | Provides immutable compliance, security, and financial transaction tracking for audit readiness. |

---

## 3 & 4. Complete Schema Column Definition & Datatypes

### 1. `roles`
- **`role_id`**: `INT` / `BIGINT` (AUTO_INCREMENT / IDENTITY) — Primary Key.
- **`role_name`**: `VARCHAR(50)` — Unique name (`ADMIN`, `ACCOUNTANT`, `CLIENT`).
- **`description`**: `VARCHAR(255)` — Human-readable description of permissions.
- **`created_at`**: `TIMESTAMP` — Record creation timestamp.

### 2. `users`
- **`user_id`**: `BIGINT` — Primary Key.
- **`email`**: `VARCHAR(255)` — User login email address (Unique).
- **`password_hash`**: `VARCHAR(255)` — Securely hashed password string (bcrypt/Argon2).
- **`first_name`**: `VARCHAR(100)` — First name of user.
- **`last_name`**: `VARCHAR(100)` — Last name of user.
- **`status`**: `VARCHAR(20)` — Account state (`ACTIVE`, `INACTIVE`, `SUSPENDED`).
- **`created_at`**: `TIMESTAMP` — Account registration date.
- **`updated_at`**: `TIMESTAMP` — Last profile update timestamp.

### 3. `user_roles`
- **`user_id`**: `BIGINT` — Foreign Key referencing `users(user_id)`.
- **`role_id`**: `INT` — Foreign Key referencing `roles(role_id)`.
- **`assigned_at`**: `TIMESTAMP` — Assignment timestamp.
- *(Composite PK: `user_id`, `role_id`)*

### 4. `clients`
- **`client_id`**: `BIGINT` — Primary Key.
- **`company_name`**: `VARCHAR(200)` — Legal company name or individual client name.
- **`tax_identifier`**: `VARCHAR(50)` — Tax ID / VAT Number / GSTIN.
- **`currency_code`**: `CHAR(3)` — ISO 4217 Currency Code (e.g., `USD`, `EUR`, `INR`).
- **`payment_terms_days`**: `INT` — Standard payment window (e.g., 15, 30 days).
- **`status`**: `VARCHAR(30)` — Client lifecycle status (`LEAD`, `ACTIVE`, `INACTIVE`, `FLAGGED_LATE`).
- **`billing_address`**: `TEXT` — Formal physical/postal billing address.
- **`created_at`**: `TIMESTAMP` — Client onboarding date.
- **`updated_at`**: `TIMESTAMP` — Last metadata modification date.

### 5. `client_contacts`
- **`contact_id`**: `BIGINT` — Primary Key.
- **`client_id`**: `BIGINT` — Foreign Key referencing `clients(client_id)`.
- **`first_name`**: `VARCHAR(100)` — Contact person first name.
- **`last_name`**: `VARCHAR(100)` — Contact person last name.
- **`email`**: `VARCHAR(255)` — Official contact email address.
- **`phone_number`**: `VARCHAR(30)` — Direct contact phone number.
- **`is_primary`**: `BOOLEAN` — Indicator if this contact is the primary billing recipient.
- **`created_at`**: `TIMESTAMP` — Contact creation date.

### 6. `projects`
- **`project_id`**: `BIGINT` — Primary Key.
- **`client_id`**: `BIGINT` — Foreign Key referencing `clients(client_id)`.
- **`project_name`**: `VARCHAR(200)` — Project title.
- **`description`**: `TEXT` — Project scope summary.
- **`billing_model`**: `VARCHAR(30)` — Model type (`FIXED_PRICE`, `HOURLY`, `RETAINER`).
- **`hourly_rate`**: `DECIMAL(10, 2)` — Rate per hour (null if fixed price).
- **`total_budget`**: `DECIMAL(12, 2)` — Total contract value or budget cap.
- **`status`**: `VARCHAR(30)` — Project state (`PROPOSED`, `ACTIVE`, `ON_HOLD`, `COMPLETED`, `CANCELLED`).
- **`start_date`**: `DATE` — Project start date.
- **`target_end_date`**: `DATE` — Target completion date.
- **`actual_end_date`**: `DATE` — Actual completion date.
- **`created_at`**: `TIMESTAMP` — System creation date.

### 7. `milestones`
- **`milestone_id`**: `BIGINT` — Primary Key.
- **`project_id`**: `BIGINT` — Foreign Key referencing `projects(project_id)`.
- **`title`**: `VARCHAR(200)` — Milestone name.
- **`description`**: `TEXT` — Deliverable scope details.
- **`amount`**: `DECIMAL(12, 2)` — Milestone billing amount.
- **`due_date`**: `DATE` — Milestone deadline.
- **`status`**: `VARCHAR(30)` — Milestone state (`PENDING`, `IN_PROGRESS`, `SUBMITTED`, `APPROVED`, `INVOICED`).
- **`approved_at`**: `TIMESTAMP` — Date client approved deliverable.

### 8. `tasks`
- **`task_id`**: `BIGINT` — Primary Key.
- **`project_id`**: `BIGINT` — Foreign Key referencing `projects(project_id)`.
- **`task_name`**: `VARCHAR(200)` — Short task title.
- **`estimated_hours`**: `DECIMAL(6, 2)` — Estimated effort hours.
- **`status`**: `VARCHAR(30)` — Task state (`TODO`, `IN_PROGRESS`, `COMPLETED`).
- **`created_at`**: `TIMESTAMP` — Task creation date.

### 9. `time_entries`
- **`time_entry_id`**: `BIGINT` — Primary Key.
- **`task_id`**: `BIGINT` — Foreign Key referencing `tasks(task_id)`.
- **`user_id`**: `BIGINT` — Foreign Key referencing `users(user_id)`.
- **`entry_date`**: `DATE` — Date work was executed.
- **`hours_logged`**: `DECIMAL(5, 2)` — Duration logged in hours (e.g., 2.75).
- **`is_billable`**: `BOOLEAN` — Billable status flag (`TRUE` = billable, `FALSE` = internal overhead).
- **`is_invoiced`**: `BOOLEAN` — Status indicator if logged time has been billed.
- **`work_description`**: `TEXT` — Specific summary of work performed.
- **`created_at`**: `TIMESTAMP` — Logging timestamp.

### 10. `invoices`
- **`invoice_id`**: `BIGINT` — Primary Key.
- **`invoice_number`**: `VARCHAR(50)` — Human-readable invoice number (Unique, e.g., `INV-2026-001`).
- **`client_id`**: `BIGINT` — Foreign Key referencing `clients(client_id)`.
- **`project_id`**: `BIGINT` — Foreign Key referencing `projects(project_id)` (Optional if multi-project).
- **`issue_date`**: `DATE` — Date invoice is issued.
- **`due_date`**: `DATE` — Payment deadline.
- **`currency_code`**: `CHAR(3)` — ISO currency code.
- **`subtotal`**: `DECIMAL(12, 2)` — Base sum of line items before tax/discounts.
- **`tax_rate_percent`**: `DECIMAL(5, 2)` — Tax rate applied (e.g., 18.00%).
- **`tax_amount`**: `DECIMAL(12, 2)` — Computed tax currency amount.
- **`discount_amount`**: `DECIMAL(12, 2)` — Flat discount subtracted.
- **`late_fee_amount`**: `DECIMAL(12, 2)` — Late penalty accrued.
- **`total_amount`**: `DECIMAL(12, 2)` — Final invoice gross payable amount.
- **`status`**: `VARCHAR(30)` — State (`DRAFT`, `ISSUED`, `PARTIALLY_PAID`, `PAID`, `OVERDUE`, `VOID`).
- **`created_at`**: `TIMESTAMP` — Invoice creation date.

### 11. `invoice_items`
- **`item_id`**: `BIGINT` — Primary Key.
- **`invoice_id`**: `BIGINT` — Foreign Key referencing `invoices(invoice_id)`.
- **`milestone_id`**: `BIGINT` — Foreign Key referencing `milestones(milestone_id)` (Nullable).
- **`time_entry_id`**: `BIGINT` — Foreign Key referencing `time_entries(time_entry_id)` (Nullable).
- **`description`**: `VARCHAR(255)` — Line item description text.
- **`quantity`**: `DECIMAL(8, 2)` — Quantity / Hours billed.
- **`unit_price`**: `DECIMAL(10, 2)` — Unit rate / Hourly rate.
- **`line_total`**: `DECIMAL(12, 2)` — Calculated total (`quantity * unit_price`).

### 12. `payments`
- **`payment_id`**: `BIGINT` — Primary Key.
- **`invoice_id`**: `BIGINT` — Foreign Key referencing `invoices(invoice_id)`.
- **`payment_date`**: `DATE` — Date money was received.
- **`amount_paid`**: `DECIMAL(12, 2)` — Payment amount.
- **`payment_method`**: `VARCHAR(50)` — Method (`BANK_TRANSFER`, `CREDIT_CARD`, `MOCK_GATEWAY`, `CASH`).
- **`transaction_reference`**: `VARCHAR(100)` — Bank/Gateway reference string.
- **`notes`**: `TEXT` — Payment notes or reconciliation remarks.
- **`created_at`**: `TIMESTAMP` — Logging timestamp.

### 13. `expense_categories`
- **`category_id`**: `INT` — Primary Key.
- **`category_name`**: `VARCHAR(100)` — Category title (`SOFTWARE_SUBSCRIPTION`, `SUBCONTRACTOR`, `TRAVEL`, `OFFICE_SUPPLIES`, `TAX_RESERVE`).
- **`is_tax_deductible`**: `BOOLEAN` — Tax deductibility flag.

### 14. `expenses`
- **`expense_id`**: `BIGINT` — Primary Key.
- **`category_id`**: `INT` — Foreign Key referencing `expense_categories(category_id)`.
- **`project_id`**: `BIGINT` — Foreign Key referencing `projects(project_id)` (Nullable if general company expense).
- **`client_id`**: `BIGINT` — Foreign Key referencing `clients(client_id)` (Nullable).
- **`expense_date`**: `DATE` — Incurred date.
- **`amount`**: `DECIMAL(12, 2)` — Expense monetary value.
- **`currency_code`**: `CHAR(3)` — ISO Currency Code.
- **`description`**: `TEXT` — Purpose of expense.
- **`receipt_ref`**: `VARCHAR(255)` — Path or reference to receipt voucher/document.
- **`created_at`**: `TIMESTAMP` — Creation timestamp.

### 15. `audit_logs`
- **`log_id`**: `BIGINT` — Primary Key.
- **`user_id`**: `BIGINT` — Foreign Key referencing `users(user_id)` (Nullable for system events).
- **`action_type`**: `VARCHAR(50)` — Action (`INSERT`, `UPDATE`, `DELETE`, `LOGIN`, `STATUS_CHANGE`).
- **`entity_affected`**: `VARCHAR(50)` — Target table (`invoices`, `projects`, `payments`).
- **`entity_id`**: `BIGINT` — Target primary key ID.
- **`change_summary`**: `TEXT` — JSON or text payload of changes made.
- **`ip_address`**: `VARCHAR(45)` — Client IP address.
- **`created_at`**: `TIMESTAMP` — Exact timestamp of event.

---

## 5 & 6. Primary Keys (PK) & Foreign Keys (FK) Summary

| Table | Primary Key (PK) | Foreign Keys (FK) & Parent Reference |
| :--- | :--- | :--- |
| `roles` | `role_id` | None |
| `users` | `user_id` | None |
| `user_roles` | Composite (`user_id`, `role_id`) | `user_id` -> `users(user_id)`, `role_id` -> `roles(role_id)` |
| `clients` | `client_id` | None |
| `client_contacts` | `contact_id` | `client_id` -> `clients(client_id)` |
| `projects` | `project_id` | `client_id` -> `clients(client_id)` |
| `milestones` | `milestone_id` | `project_id` -> `projects(project_id)` |
| `tasks` | `task_id` | `project_id` -> `projects(project_id)` |
| `time_entries` | `time_entry_id` | `task_id` -> `tasks(task_id)`, `user_id` -> `users(user_id)` |
| `invoices` | `invoice_id` | `client_id` -> `clients(client_id)`, `project_id` -> `projects(project_id)` |
| `invoice_items` | `item_id` | `invoice_id` -> `invoices(invoice_id)`, `milestone_id` -> `milestones(milestone_id)`, `time_entry_id` -> `time_entries(time_entry_id)` |
| `payments` | `payment_id` | `invoice_id` -> `invoices(invoice_id)` |
| `expense_categories` | `category_id` | None |
| `expenses` | `expense_id` | `category_id` -> `expense_categories(category_id)`, `project_id` -> `projects(project_id)`, `client_id` -> `clients(client_id)` |
| `audit_logs` | `log_id` | `user_id` -> `users(user_id)` |

---

## 7 & 10. Entity Relationship Categorization & Business Rationales

### 1. One-to-Many (1:N) Relationships

- **`clients` (1) ---> `client_contacts` (N)**
  - *Rationale*: A client company can employ multiple point-of-contact individuals over time (e.g., Billing Manager, Project Lead), but each contact belongs to exactly one client company.
- **`clients` (1) ---> `projects` (N)**
  - *Rationale*: One client can contract multiple projects over its relationship lifecycle, but a specific project contract belongs to exactly one client.
- **`projects` (1) ---> `milestones` (N)**
  - *Rationale*: A fixed-price project is subdivided into multiple deliverable milestones, each belonging to that single project.
- **`projects` (1) ---> `tasks` (N)**
  - *Rationale*: A project comprises multiple distinct tasks for task breakdown and management.
- **`tasks` (1) ---> `time_entries` (N)**
  - *Rationale*: A single task will accumulate multiple time logging sessions over days or weeks.
- **`users` (1) ---> `time_entries` (N)**
  - *Rationale*: A freelancer/user logs multiple time entries across various tasks.
- **`clients` (1) ---> `invoices` (N)**
  - *Rationale*: A client receives multiple invoices over time.
- **`invoices` (1) ---> `invoice_items` (N)**
  - *Rationale*: An invoice consists of one or more itemized lines for billing transparency.
- **`invoices` (1) ---> `payments` (N)**
  - *Rationale*: Supports partial payments where an invoice is settled across multiple incremental payment transactions.
- **`expense_categories` (1) ---> `expenses` (N)**
  - *Rationale*: Standardizes expense classification so multiple expense entries map to one standard category.
- **`projects` (1) ---> `expenses` (N)**
  - *Rationale*: A project incurs zero or multiple directly attributable operational costs.

### 2. Many-to-Many (M:N) Relationships

- **`users` (M) <---> `roles` (N)** (Resolved via `user_roles` junction entity)
  - *Rationale*: A user can possess multiple roles (e.g., both Admin and Accountant), and a role applies to multiple users. 
- **`milestones` / `time_entries` (M) <---> `invoices` (N)** (Resolved via `invoice_items` junction entity)
  - *Rationale*: An invoice aggregates multiple milestones/time entries, and across revisions/re-issuances, billing items link cleanly to invoice line items without multi-valued columns.

---

## 8. Database Constraints Specification

1. **Primary Key Constraints**: Applied on every entity to guarantee entity integrity and fast tuple retrieval.
2. **Foreign Key Integrity & Referential Actions**:
   - `client_contacts` -> `clients`: `ON DELETE CASCADE` (Deleting a client purges contact references).
   - `projects` -> `clients`: `ON DELETE RESTRICT` (Prevents deleting a client if active projects exist).
   - `milestones` -> `projects`: `ON DELETE CASCADE` (Deleting a project removes its milestones).
   - `invoice_items` -> `invoices`: `ON DELETE CASCADE` (Deleting an invoice removes its line items).
   - `invoices` -> `clients`: `ON DELETE RESTRICT` (Protects financial records; clients with invoices cannot be deleted).
   - `payments` -> `invoices`: `ON DELETE RESTRICT` (Protects payment audit trails).
3. **Unique Constraints**:
   - `users.email`: `UNIQUE` (Prevents duplicate user credentials).
   - `roles.role_name`: `UNIQUE` (Prevents duplicate role definitions).
   - `invoices.invoice_number`: `UNIQUE` (Guarantees unique financial document numbers).
   - `expense_categories.category_name`: `UNIQUE` (Prevents redundant expense categories).
4. **Check Constraints**:
   - `users.status`: `CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED'))`.
   - `projects.billing_model`: `CHECK (billing_model IN ('FIXED_PRICE', 'HOURLY', 'RETAINER'))`.
   - `projects.hourly_rate`: `CHECK (hourly_rate >= 0.00)`.
   - `time_entries.hours_logged`: `CHECK (hours_logged > 0.00 AND hours_logged <= 24.00)`.
   - `invoices.tax_rate_percent`: `CHECK (tax_rate_percent >= 0.00 AND tax_rate_percent <= 100.00)`.
   - `invoices.status`: `CHECK (status IN ('DRAFT', 'ISSUED', 'PARTIALLY_PAID', 'PAID', 'OVERDUE', 'VOID'))`.
   - `payments.amount_paid`: `CHECK (amount_paid > 0.00)`.
   - `expenses.amount`: `CHECK (amount > 0.00)`.
5. **Not Null Constraints**:
   - Critical operational fields (`email`, `company_name`, `project_name`, `hours_logged`, `subtotal`, `total_amount`, `entry_date`, `due_date`) enforce `NOT NULL` to guarantee data completeness.

---

## 9. Performance Indexing Strategy

1. **B-Tree Primary Indexes**: Default clustered indexes created automatically on all Primary Keys (`client_id`, `project_id`, `invoice_id`, etc.).
2. **Foreign Key Indexes (B-Tree)**:
   - `idx_projects_client_id` ON `projects(client_id)`
   - `idx_milestones_project_id` ON `milestones(project_id)`
   - `idx_tasks_project_id` ON `tasks(project_id)`
   - `idx_time_entries_task_id` ON `time_entries(task_id)`
   - `idx_time_entries_user_id` ON `time_entries(user_id)`
   - `idx_invoices_client_id` ON `invoices(client_id)`
   - `idx_payments_invoice_id` ON `payments(invoice_id)`
   - `idx_expenses_project_id` ON `expenses(project_id)`
3. **Composite & Filtering Indexes for Analytical Query Performance**:
   - `idx_time_entries_date_billable` ON `time_entries(entry_date, is_billable, is_invoiced)`
     - *Purpose*: Optimizes execution speed for hourly billing compilation and analytics query aggregations.
   - `idx_invoices_status_due_date` ON `invoices(status, due_date)`
     - *Purpose*: Speeds up Accounts Receivable Aging Reports and automated late fee penalty batch updates.
   - `idx_expenses_date_category` ON `expenses(expense_date, category_id)`
     - *Purpose*: Accelerates monthly tax reserve and expense breakdown reports.

---

## 10. Third Normal Form (3NF) Compliance Verification

- **1NF (Atomic Values)**: All columns hold scalar values. No repeating groups or comma-separated lists (e.g., client contacts and invoice line items are fully normalized into child entities `client_contacts` and `invoice_items`).
- **2NF (No Partial Dependencies)**: Every non-key attribute in every entity depends on the *entire* primary key. In composite key table `user_roles`, `assigned_at` depends on the combination of (`user_id`, `role_id`).
- **3NF (No Transitive Dependencies)**: Non-key attributes depend *only* on the primary key, with no intermediate functional dependencies.
  - Calculated financial totals (such as invoice outstanding balances or client total LTV) are **not** stored as mutable non-key columns alongside source rates to avoid transitive dependency violations. They are dynamically aggregated via optimized **Database Views** (`v_invoice_summaries`, `v_client_analytics`).
