# Entity Relationship (ER) Diagram & Relational Mapping Specification

## Project Title
**Freelance & Client Management System with Freelancer Income & Client Analytics (FCMS Analytics)**

---

## 1. Complete ER Diagram Overview

The ER diagram below represents the complete relational structure for the **FCMS Analytics** platform. It comprises 15 normalized entities (3NF compliant), illustrating all primary keys, foreign keys, junction entities, and relationship cardinalities.

---

## 2. Mermaid ER Diagram

```mermaid
erDiagram
    ROLES {
        int role_id PK
        string role_name UK
        string description
        timestamp created_at
    }

    USERS {
        bigint user_id PK
        string email UK
        string password_hash
        string first_name
        string last_name
        string status
        timestamp created_at
        timestamp updated_at
    }

    USER_ROLES {
        bigint user_id PK, FK
        int role_id PK, FK
        timestamp assigned_at
    }

    CLIENTS {
        bigint client_id PK
        string company_name
        string tax_identifier
        string currency_code
        int payment_terms_days
        string status
        string billing_address
        timestamp created_at
        timestamp updated_at
    }

    CLIENT_CONTACTS {
        bigint contact_id PK
        bigint client_id FK
        string first_name
        string last_name
        string email
        string phone_number
        boolean is_primary
        timestamp created_at
    }

    PROJECTS {
        bigint project_id PK
        bigint client_id FK
        string project_name
        string description
        string billing_model
        decimal hourly_rate
        decimal total_budget
        string status
        date start_date
        date target_end_date
        date actual_end_date
        timestamp created_at
    }

    MILESTONES {
        bigint milestone_id PK
        bigint project_id FK
        string title
        string description
        decimal amount
        date due_date
        string status
        timestamp approved_at
    }

    TASKS {
        bigint task_id PK
        bigint project_id FK
        string task_name
        decimal estimated_hours
        string status
        timestamp created_at
    }

    TIME_ENTRIES {
        bigint time_entry_id PK
        bigint task_id FK
        bigint user_id FK
        date entry_date
        decimal hours_logged
        boolean is_billable
        boolean is_invoiced
        string work_description
        timestamp created_at
    }

    INVOICES {
        bigint invoice_id PK
        string invoice_number UK
        bigint client_id FK
        bigint project_id FK
        date issue_date
        date due_date
        string currency_code
        decimal subtotal
        decimal tax_rate_percent
        decimal tax_amount
        decimal discount_amount
        decimal late_fee_amount
        decimal total_amount
        string status
        timestamp created_at
    }

    INVOICE_ITEMS {
        bigint item_id PK
        bigint invoice_id FK
        bigint milestone_id FK
        bigint time_entry_id FK
        string description
        decimal quantity
        decimal unit_price
        decimal line_total
    }

    PAYMENTS {
        bigint payment_id PK
        bigint invoice_id FK
        date payment_date
        decimal amount_paid
        string payment_method
        string transaction_reference
        string notes
        timestamp created_at
    }

    EXPENSE_CATEGORIES {
        int category_id PK
        string category_name UK
        boolean is_tax_deductible
    }

    EXPENSES {
        bigint expense_id PK
        int category_id FK
        bigint project_id FK
        bigint client_id FK
        date expense_date
        decimal amount
        string currency_code
        string description
        string receipt_ref
        timestamp created_at
    }

    AUDIT_LOGS {
        bigint log_id PK
        bigint user_id FK
        string action_type
        string entity_affected
        bigint entity_id
        string change_summary
        string ip_address
        timestamp created_at
    }

    %% User & Role Management Relationships
    USERS ||--o{ USER_ROLES : "assigned"
    ROLES ||--o{ USER_ROLES : "granted to"

    %% Client & Contact Relationships
    CLIENTS ||--o{ CLIENT_CONTACTS : "employs"
    CLIENTS ||--o{ PROJECTS : "commissions"
    CLIENTS ||--o{ INVOICES : "billed via"
    CLIENTS ||--o{ EXPENSES : "incurs project costs for"

    %% Project & Work Breakdown Structure (WBS)
    PROJECTS ||--o{ MILESTONES : "divided into"
    PROJECTS ||--o{ TASKS : "structured into"
    PROJECTS ||--o{ INVOICES : "billed under"
    PROJECTS ||--o{ EXPENSES : "incurs costs"

    %% Task & Time Tracking
    TASKS ||--o{ TIME_ENTRIES : "tracks effort via"
    USERS ||--o{ TIME_ENTRIES : "logs work hours"

    %% Invoicing, Line Items & Payments
    INVOICES ||--|{ INVOICE_ITEMS : "itemized into"
    MILESTONES ||--o| INVOICE_ITEMS : "billed as item"
    TIME_ENTRIES ||--o| INVOICE_ITEMS : "billed as item"
    INVOICES ||--o{ PAYMENTS : "settled via"

    %% Expenses & Categories
    EXPENSE_CATEGORIES ||--o{ EXPENSES : "classifies"

    %% Audit & Logging
    USERS ||--o{ AUDIT_LOGS : "generates"
```

---

## 3. Crow's Foot Notation Explanation

Crow's Foot notation visually represents the cardinality and modality (optionality) of relationships between database entities:

| Notation Symbol | Symbol Meaning | Modality (Minimum) | Cardinality (Maximum) | System Context Example |
| :---: | :--- | :---: | :---: | :--- |
| `||` | **Exactly One** | Mandatory (1) | One (1) | Each `INVOICE_ITEM` belongs to **exactly one** parent `INVOICE`. |
| `|{` | **One or Many** | Mandatory (1) | Many ($N$) | An `INVOICE` must have at least **one or many** `INVOICE_ITEMS`. |
| `|o` | **Zero or One** | Optional (0) | One (1) | An `INVOICE_ITEM` optionally links to **zero or one** `MILESTONE`. |
| `}o` | **Zero or Many** | Optional (0) | Many ($N$) | A `CLIENT` may commission **zero or many** `PROJECTS`. |

---

## 4. Comprehensive Relationship & Foreign Key Verification

Every foreign key constraint in the FCMS database is documented below alongside parent and child table linkages:

### 1. `USER_ROLES` Junction Table
- `user_id` (FK $\rightarrow$ `USERS.user_id`)
- `role_id` (FK $\rightarrow$ `ROLES.role_id`)
- **Relationship:** Many-to-Many ($M:N$) between `USERS` and `ROLES`.

### 2. `CLIENT_CONTACTS` Table
- `client_id` (FK $\rightarrow$ `CLIENTS.client_id`)
- **Relationship:** One-to-Many ($1:N$) from `CLIENTS` to `CLIENT_CONTACTS`.

### 3. `PROJECTS` Table
- `client_id` (FK $\rightarrow$ `CLIENTS.client_id`)
- **Relationship:** One-to-Many ($1:N$) from `CLIENTS` to `PROJECTS`.

### 4. `MILESTONES` Table
- `project_id` (FK $\rightarrow$ `PROJECTS.project_id`)
- **Relationship:** One-to-Many ($1:N$) from `PROJECTS` to `MILESTONES`.

### 5. `TASKS` Table
- `project_id` (FK $\rightarrow$ `PROJECTS.project_id`)
- **Relationship:** One-to-Many ($1:N$) from `PROJECTS` to `TASKS`.

### 6. `TIME_ENTRIES` Table
- `task_id` (FK $\rightarrow$ `TASKS.task_id`)
- `user_id` (FK $\rightarrow$ `USERS.user_id`)
- **Relationships:** One-to-Many ($1:N$) from `TASKS` to `TIME_ENTRIES`; One-to-Many ($1:N$) from `USERS` to `TIME_ENTRIES`.

### 7. `INVOICES` Table
- `client_id` (FK $\rightarrow$ `CLIENTS.client_id`)
- `project_id` (FK $\rightarrow$ `PROJECTS.project_id` - Nullable for multi-project billing)
- **Relationships:** One-to-Many ($1:N$) from `CLIENTS` to `INVOICES`; Zero/One-to-Many ($0/1:N$) from `PROJECTS` to `INVOICES`.

### 8. `INVOICE_ITEMS` Table
- `invoice_id` (FK $\rightarrow$ `INVOICES.invoice_id`)
- `milestone_id` (FK $\rightarrow$ `MILESTONES.milestone_id` - Nullable)
- `time_entry_id` (FK $\rightarrow$ `TIME_ENTRIES.time_entry_id` - Nullable)
- **Relationships:** Mandatory One-to-Many ($1:N$) from `INVOICES` to `INVOICE_ITEMS`; Optional One-to-One ($0:1$) from `MILESTONES` to `INVOICE_ITEMS`; Optional One-to-One ($0:1$) from `TIME_ENTRIES` to `INVOICE_ITEMS`.

### 9. `PAYMENTS` Table
- `invoice_id` (FK $\rightarrow$ `INVOICES.invoice_id`)
- **Relationship:** One-to-Many ($1:N$) from `INVOICES` to `PAYMENTS`.

### 10. `EXPENSES` Table
- `category_id` (FK $\rightarrow$ `EXPENSE_CATEGORIES.category_id`)
- `project_id` (FK $\rightarrow$ `PROJECTS.project_id` - Nullable)
- `client_id` (FK $\rightarrow$ `CLIENTS.client_id` - Nullable)
- **Relationships:** One-to-Many ($1:N$) from `EXPENSE_CATEGORIES` to `EXPENSES`; Optional One-to-Many ($0:N$) from `PROJECTS` and `CLIENTS` to `EXPENSES`.

### 11. `AUDIT_LOGS` Table
- `user_id` (FK $\rightarrow$ `USERS.user_id` - Nullable for background system processes)
- **Relationship:** Optional One-to-Many ($0:N$) from `USERS` to `AUDIT_LOGS`.

---

## 5. Detailed Cardinality & Modality Matrix

| Parent Entity | Child Entity | Parent Modality | Child Modality | Cardinality | Business Explanation |
| :--- | :--- | :---: | :---: | :---: | :--- |
| `USERS` | `USER_ROLES` | Mandatory (1) | Optional (0) | $1 : N$ | A user can be assigned 1 or many roles. |
| `ROLES` | `USER_ROLES` | Mandatory (1) | Optional (0) | $1 : N$ | A role can apply to zero or many users. |
| `CLIENTS` | `CLIENT_CONTACTS` | Mandatory (1) | Optional (0) | $1 : N$ | A newly onboarded client may initially have zero contacts before contacts are added. |
| `CLIENTS` | `PROJECTS` | Mandatory (1) | Optional (0) | $1 : N$ | A client may exist in CRM without active project contracts initially. |
| `PROJECTS` | `MILESTONES` | Mandatory (1) | Optional (0) | $1 : N$ | Fixed-price projects contain 1 or more milestones; hourly projects may have 0 milestones. |
| `PROJECTS` | `TASKS` | Mandatory (1) | Optional (0) | $1 : N$ | Projects contain tasks for tracking progress and hours. |
| `TASKS` | `TIME_ENTRIES` | Mandatory (1) | Optional (0) | $1 : N$ | Tasks accumulate logged work entries over time. |
| `USERS` | `TIME_ENTRIES` | Mandatory (1) | Optional (0) | $1 : N$ | A freelancer user logs multiple work time records. |
| `CLIENTS` | `INVOICES` | Mandatory (1) | Optional (0) | $1 : N$ | Invoices are issued to clients over time. |
| `PROJECTS` | `INVOICES` | Optional (0) | Optional (0) | $0/1 : N$ | Invoices can be associated with a specific project or cover multi-project billing. |
| `INVOICES` | `INVOICE_ITEMS` | Mandatory (1) | Mandatory (1) | $1 : N$ | An invoice cannot exist without at least one line item (mandatory parent & child). |
| `MILESTONES` | `INVOICE_ITEMS` | Optional (0) | Optional (0) | $0 : 1$ | A milestone maps to at most 1 invoice line item once invoiced. |
| `TIME_ENTRIES` | `INVOICE_ITEMS` | Optional (0) | Optional (0) | $0 : 1$ | A billable time entry maps to at most 1 invoice line item once billed. |
| `INVOICES` | `PAYMENTS` | Mandatory (1) | Optional (0) | $1 : N$ | An invoice can be paid in full (1 payment) or incrementally (multiple partial payments). |
| `EXPENSE_CAT` | `EXPENSES` | Mandatory (1) | Optional (0) | $1 : N$ | Expenses are categorized under a specific expense category. |
| `USERS` | `AUDIT_LOGS` | Optional (0) | Optional (0) | $0 : N$ | User actions generate audit records; system background events have null `user_id`. |
