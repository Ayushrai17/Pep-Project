# Software Requirements & Architectural Specification

## Project Title
**Freelance & Client Management System with Freelancer Income & Client Analytics (FCMS Analytics)**

---

## 1. Project Overview
The **Freelance & Client Management System with Freelancer Income & Client Analytics (FCMS Analytics)** is an enterprise-grade platform designed for independent contractors, freelancers, and boutique agencies. 

The system centralizes operational workflows—ranging from client onboarding and project contract management to time tracking, invoicing, and expense management. Beyond basic CRUD functions, it incorporates an advanced analytical backend powered by normalized relational SQL schemas and Python data processing algorithms. This engine delivers real-time business intelligence, including Client Lifetime Value (CLTV), Effective Hourly Rate (EHR), project profitability margins, and financial forecasting.

---

## 2. Problem Statement
Freelancers and solo service providers frequently face severe operational inefficiencies due to fragmented tooling and manual record-keeping:
1. **Financial Invisibility & Unclear Profitability**: Scattered spreadsheets make it difficult to determine true profit margins per client after accounting for billable vs non-billable time, taxes, and software/project expenses.
2. **Scope Creep & Milestone Slippage**: Lack of integrated milestone-to-invoice mapping leads to unpaid work, unbilled extra hours, and delayed client payments.
3. **Inconsistent Revenue & Cash Flow Bottlenecks**: Without aging invoice tracking and automated late fee calculations, freelancers suffer from high accounts receivable defaults and unpredictable cash flow.
4. **Lack of Data-Driven Decision Making**: Independent professionals rarely have access to executive-level analytics like Client Risk Scoring, Revenue Realization Rates, or Client Acquisition Cost vs. Lifetime Value ratios.

---

## 3. Objectives
- **Centralize Operational Workflows**: Unify client management, project milestones, time logs, invoicing, and expenses into a single robust relational system.
- **Enforce Business Data Integrity**: Build a 3NF/BCNF normalized database schema with ACID-compliant transaction boundaries, strict constraints, and cascade policies.
- **Deliver Business Intelligence & Analytics**: Develop Python-driven analytical models and SQL view aggregations to calculate client profitability, hourly realization rates, tax liabilities, and revenue growth.
- **Automate Financial Governance**: Automate balance calculations, late payment penalty accruals, and invoice status transitions.
- **Apply Software Engineering Best Practices**: Structure code following the Repository Pattern / MVC architecture, separation of concerns, and security controls (parameterized queries, RBAC).

---

## 4. System Scope

### 4.1 In-Scope Features
- **Client & Lead CRM**: Full lifecycle tracking of clients, communication logs, billing addresses, and payment terms.
- **Contract & Project Management**: Fixed-price and hourly project tracking, milestone completion workflows, and deliverables management.
- **Time & Task Tracking**: Detailed billable and non-billable hour logging categorized by task and project.
- **Invoicing & Expense Engine**: Automated invoice creation from billable hours/milestones, payment tracking, partial payment handling, and business expense logging.
- **Analytics & BI Dashboard**: SQL analytical views and Python metrics computing EHR, CLTV, Profit Margins, and Monthly Recurring Revenue (MRR).
- **Reporting System**: Generation of financial statements, aging invoice reports, and tax summary documents.
- **Role-Based Access Control (RBAC)**: Distinct permissions for Freelancer/Admin, Client Portal View, and Accountant/Auditor.

### 4.2 Out-of-Scope (Current Version)
- Live payment gateway API integrations (e.g., Stripe/PayPal webhooks - payment processing will be simulated via mock handlers).
- Native mobile applications (iOS/Android - scope is focused on web/desktop dashboard architectures).
- Multi-tenant enterprise SaaS infrastructure (focused on single-freelancer/agency multi-user model).

---

## 5. Business Rules (BR)

| Rule ID | Name | Rule Description |
| :--- | :--- | :--- |
| **BR-01** | Milestone-Invoice Linking | Invoices for milestone-based projects cannot be generated unless the corresponding milestone status is officially marked as 'Completed' or 'Approved'. |
| **BR-02** | Payment & Balance Settlement | Every payment transaction reduces the outstanding balance of an invoice. An invoice status automatically transitions to 'Paid' when balance reaches $0.00, and to 'Partially Paid' if 0 < Balance < Total. |
| **BR-03** | Hour Cap Protection | Billable hours logged against a project cannot exceed the max cap defined in the project contract unless a contract scope change is approved. |
| **BR-04** | Late Payment Penalty Accrual | Invoices remaining unpaid 15 days past their due date automatically incur a configurable late fee penalty (e.g., 2% recurring monthly interest) applied to the pending balance. |
| **BR-05** | Effective Hourly Rate (EHR) | $EHR = \frac{\text{Gross Revenue Earned from Project} - \text{Attributable Expenses}}{\text{Total Hours (Billable + Non-Billable) Logged}}$. Non-billable hours directly reduce overall project EHR. |
| **BR-06** | Currency & Tax Standardization | Multi-currency transactions must store the foreign currency amount alongside the normalized base currency equivalent computed using the transaction-date exchange rate. |

---

## 6. User Roles & Access Control Matrix

| Role | Operational Permissions | Analytical / Financial Access | System Governance |
| :--- | :--- | :--- | :--- |
| **Freelancer / Admin** | Full CRUD on Clients, Projects, Tasks, Invoices, Expenses | Access to all financial metrics, profit analytics, income forecasting, and raw export reports | Full administrative configuration |
| **Client (Portal View)** | Read-only access to assigned projects, milestones, logged billable hours; permission to approve/reject completed milestones | View issued invoices, outstanding balance, and payment receipts for own account | Profile management |
| **Accountant / Auditor** | Read-only access to financial records, expense vouchers, tax entries, and invoice status logs | Access to audit trails, tax summaries, accounts receivable aging, and revenue statements | Export financial reports |

---

## 7. Functional Requirements (FR)

### Module 1: Authentication & User Governance
- **FR-1.1**: Secure user login with password hashing (bcrypt/Argon2).
- **FR-1.2**: Session/JWT-based authorization with Role-Based Access Control (RBAC).

### Module 2: Client Relationship Management (CRM)
- **FR-2.1**: Onboard and manage client profiles (Company Name, Contact Person, Tax ID, Currency, Default Payment Terms).
- **FR-2.2**: Track client status history (`Lead`, `Active`, `Inactive`, `Flagged for Late Payment`).
- **FR-2.3**: Record client notes and interaction history.

### Module 3: Project & Milestone Management
- **FR-3.1**: Create projects linked to clients with attributes: Billing Model (`Fixed Price`, `Hourly Rate`, `Monthly Retainer`), Total Budget, Start Date, Target Completion Date.
- **FR-3.2**: Define project milestones with deliverable descriptions, completion percentages, due dates, and milestone amounts.
- **FR-3.3**: Milestone approval workflow (Freelancer submits -> Client approves/rejects).

### Module 4: Time & Task Tracker
- **FR-4.1**: Create tasks categorized under projects with estimated vs actual hours.
- **FR-4.2**: Log time entries containing: Date, Task ID, Duration (hours/minutes), Billable Flag (`True`/`False`), Work Description.
- **FR-4.3**: Prevent overlapping time logs for the same user.

### Module 5: Invoicing, Expense & Payment Engine
- **FR-5.1**: Auto-generate itemized invoices from approved milestones or billable time logs.
- **FR-5.2**: Support custom discounts, tax rates (VAT/GST/Sales Tax), and late fee additions.
- **FR-5.3**: Record payments (Payment Date, Amount, Payment Method, Reference/Txn ID, Notes).
- **FR-5.4**: Track business expenses (Expense Date, Category, Amount, Attributable Client/Project, Tax Deductible Flag, Receipt Voucher reference).

### Module 6: Analytics & Business Intelligence Engine
- **FR-6.1**: Calculate key performance metrics:
  - **Client Lifetime Value (CLTV)**: Total net revenue generated per client over lifetime.
  - **Effective Hourly Rate (EHR)**: Net profit per project divided by total hours worked.
  - **Project Profit Margin %**: $\frac{\text{Revenue} - \text{Expenses}}{\text{Revenue}} \times 100$.
  - **Monthly Recurring Revenue (MRR)**: Income from active retainer contracts.
- **FR-6.2**: Calculate Client Health & Risk Score based on payment history and average payment delay.

---

## 8. Non-Functional Requirements (NFR)

- **Performance**: 
  - Complex analytical SQL queries (e.g., multi-year quarterly aggregation views) must execute under **100ms** using optimized indexes and materialized views.
- **Data Integrity & Relational Rules**:
  - Strict Foreign Key constraints, domain check constraints, non-null guarantees, and explicit cascading rules (`ON DELETE RESTRICT` / `CASCADE` depending on business domain).
  - ACID compliance for multi-table transactions (e.g., invoice generation + milestone status updates).
- **Security**:
  - 100% parameterized SQL queries to prevent SQL Injection vulnerability.
  - Sensitive data protection and secure password hashing.
- **Maintainability & Architecture**:
  - Clean separation of concerns (Presentation Layer, Business Logic Layer, Data Access Layer via Repository Pattern).
  - Code modularity allowing seamless database driver replacement (e.g., SQLite to PostgreSQL/MySQL).
- **Extensibility**:
  - Abstract analytics pipeline allowing easy addition of new metrics or reporting formats without altering core schemas.

---

## 9. Project Modules Architecture

```
+-----------------------------------------------------------------------------------+
|                            FCMS ANALYTICS SYSTEM                                  |
+-----------------------------------------------------------------------------------+
|  1. Auth & RBAC Module        |  2. Client CRM Module                             |
|  - Login / Token Handler      |  - Client Profiles & Billing Terms                |
|  - Role Enforcement           |  - Client Status & Communication History          |
+-------------------------------+---------------------------------------------------+
|  3. Project & Milestone Mod   |  4. Time & Task Tracker Module                    |
|  - Contracts & Budgets        |  - Billable / Non-Billable Time Logs              |
|  - Milestone Approval Flow    |  - Task Hour Estimation & Burn Rate               |
+-------------------------------+---------------------------------------------------+
|  5. Invoicing & Expense Mod   |  6. Analytics & Intelligence Engine               |
|  - Invoice Generation Engine  |  - EHR & Profit Margin Calculators                |
|  - Payment Rec balance sync   |  - CLTV & Client Risk Score Matrix                |
|  - Business Expense Tracker   |  - Revenue Realization & MRR Models               |
+-------------------------------+---------------------------------------------------+
|                          7. Reporting & Export Engine                             |
|  - Financial Statements  | Aging Accounts Receivable | Client ROI Reports          |
+-----------------------------------------------------------------------------------+
```

---

## 10. Expected Reports & Analytical Output

1. **Freelancer Income & Tax Liability Summary Report**:
   - Monthly/Quarterly breakdown of gross revenue, deductible expenses, net taxable income, and estimated tax reserves.
2. **Client Profitability & Effective Hourly Rate (EHR) Matrix**:
   - Comparative ranking of clients by profitability percentage, net revenue, total hours spent, and realization rate per hour.
3. **Accounts Receivable Aging Report**:
   - Breakdown of pending invoices grouped by aging buckets: `0-30 Days`, `31-60 Days`, `61-90 Days`, and `90+ Days (High Default Risk)`.
4. **Project Budget vs. Actual Efficiency Report**:
   - Variance analysis comparing estimated milestone budgets vs actual hours logged and expenses incurred.
5. **Revenue Pipeline & Forecast Report**:
   - Income projections combining active monthly retainers, pending milestone approvals, and historical realization trends.

---

## 11. Future Scope & Enhancements

- **Automated Expense OCR & Invoice Parsing**: Integrate machine learning models to parse PDF receipts into structured expense entries.
- **Automated Banking Reconciliation**: Open Banking API integration to match incoming bank deposits with pending invoices automatically.
- **Interactive Web/Mobile Client Portal**: React / Next.js web application for client self-service invoicing and digital milestone sign-off.
- **Multi-Tenant SaaS Expansion**: Upgrade single-tenant data structures to isolated multi-tenant schemas for agency team management.
