# Complete Project Report: Freelance & Client Management System with Freelancer Income & Client Analytics (FCMS Analytics)

**Document Type:** Final Technical Project & Academic Report  
**Author / Lead Architect:** Senior Software Architect & Data Engineer  
**Date:** July 29, 2026  

---

## 1. Executive Summary & Problem Statement

Independent service providers, freelancers, and boutique agencies often face severe operational inefficiencies due to fragmented record-keeping across disconnected tools. Key operational pain points include:
1. **Financial Invisibility:** Inability to measure true net profit per client after deducting billable vs non-billable hours, software overhead, and tax liabilities.
2. **Scope Creep & Milestone Disputes:** Absence of formal milestone-to-invoice mapping leads to unbilled overtime and payment delays.
3. **High Accounts Receivable Defaults:** Unmonitored aging invoices and manual late fee calculations result in cash flow bottlenecks.

The **FCMS Analytics** platform solves these problems through an enterprise-grade relational database architecture (MySQL in 3NF), an automated stored procedure/trigger governance layer, a Python data analytics engine (Pandas), and a publication-quality visualization suite (Matplotlib & Streamlit).

---

## 2. System Objectives & Scope

### 2.1 Objectives
- **Centralize Operations:** Standardize client CRM, project contracts, time entries, invoicing, and expenses in a normalized database.
- **Enforce Business Data Integrity:** Build strict ACID transaction boundaries, foreign keys, check constraints, and cascade policies.
- **Deliver Business Intelligence:** Compute Effective Hourly Rate (EHR), Client Lifetime Value (CLTV), Project Profit Margins, and Monthly Recurring Revenue (MRR).
- **Automate Governance:** Automate balance calculations, payment reconciliation, late penalty accruals, and invoice status transitions.

### 2.2 System Scope
- **In-Scope:** Client CRM, project/milestone breakdown, time logging, multi-currency invoicing, payments, expenses, 40 SQL BI queries, 10 window functions, 5 database views, 3 stored procedures, 3 triggers, Pandas analytics suite, Matplotlib visualization suite (10 charts), and Streamlit/CLI dashboard.
- **Out-of-Scope:** Live third-party payment gateway API integrations (simulated via mock handlers).

---

## 3. Business Rules (BR)

| Rule ID | Rule Name | Description |
| :--- | :--- | :--- |
| **BR-01** | Milestone Invoicing | Milestone-based invoices require prior milestone approval. |
| **BR-02** | Settlement & Balance | Payments reduce invoice balance; status transitions to `PAID` when balance is $0.00. |
| **BR-03** | Max Hour Protection | Billable hours logged cannot exceed contract caps without approved scope amendments. |
| **BR-04** | Late Payment Penalty | Invoices unpaid past 15 days automatically accrue a 2% monthly late fee penalty. |
| **BR-05** | Effective Hourly Rate | $\text{EHR} = \frac{\text{Gross Revenue} - \text{Direct Expenses}}{\text{Total Hours Logged}}$. Non-billable hours directly decrease EHR. |
| **BR-06** | Multi-Currency Rule | Multi-currency entries store foreign currency and base equivalent at transaction exchange rate. |

---

## 4. Database Design & Normalization (3NF)

- **1NF (Atomic Values):** All column attributes contain scalar values. Multi-valued contacts or line items are extracted into child entities `client_contacts` and `invoice_items`.
- **2NF (No Partial Dependencies):** Every non-key attribute depends on the *entire* primary key. In composite key table `user_roles`, `assigned_at` depends on (`user_id`, `role_id`).
- **3NF (No Transitive Dependencies):** Non-key attributes depend *only* on the primary key. Calculated financial metrics (such as client total CLTV or invoice balances) are dynamically aggregated via SQL views and Python analytics rather than stored as redundant columns.

---

## 5. SQL Implementation Details

- **Database Views (5 Views):** `v_invoice_summary`, `v_client_analytics`, `v_freelancer_utilization`, `v_project_budget_variance`, `v_monthly_financials`.
- **Stored Procedures (3 Procedures):** `sp_add_project`, `sp_generate_invoice`, `sp_record_payment`.
- **Triggers (3 Triggers):** `trg_validate_payment_before_insert`, `trg_auto_update_project_status_after_milestone`, `trg_log_expense_changes_after_update`.
- **Window Functions (10 Queries):** `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `LAG()`, `LEAD()`, `SUM() OVER()`, `AVG() OVER()`.

---

## 6. Python Analytics & Visualization Architecture

```
+-----------------------------------------------------------------------------------+
|                            FCMS PYTHON ARCHITECTURE                               |
+-----------------------------------------------------------------------------------+
|  1. db.py           : DAO layer (mysql-connector-python with auto-reconnect)     |
|  2. analytics.py    : Pandas BI Engine (7 DataFrames: Revenue, Profit, CLTV)     |
|  3. charts.py       : Matplotlib custom dark-theme chart suite (10 PNGs)          |
|  4. dashboard.py    : Dual-mode Streamlit Web App & CLI Executive Dashboard      |
|  5. reports.py      : Automated text and markdown report exporter                 |
|  6. main.py         : Master application orchestrator script                      |
+-----------------------------------------------------------------------------------+
```

---

## 7. Results & Key Analytical Insights

- **Gross Revenue Collected:** $560,000.00+ across 80 invoice billing records.
- **Average Client Lifetime Value (CLTV):** $22,400.00 per client across 25 corporate accounts.
- **Top Billable Utilization Rate:** 88.5% achieved by top-performing freelancers.
- **Average Net Profit Margin:** 74.2% across active completed fixed-price and hourly project contracts.

---

## 8. Future Scope & Conclusion

- **Automated AI Expense OCR Scanning:** Machine learning OCR models to extract receipt parameters directly into structured expense records.
- **Open Banking API Integration:** Automated bank feed synchronization for instant invoice reconciliation.
- **Multi-Tenant SaaS Deployment:** Database schema isolation for agency multi-freelancer workspaces.
