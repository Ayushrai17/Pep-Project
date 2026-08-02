# Complete Project Documentation & Portfolio Assets

## Project Title
**Freelance & Client Management System with Freelancer Income & Client Analytics (FCMS Analytics)**

---

## 1. System Specifications & Overview

### 1.1 Problem Statement
Independent contractors, solo consultants, and boutique agencies suffer from operational fragmentation due to scattered spreadsheets, manual invoice creation, and unbilled overtime. Crucially, freelancers lack visibility into **true profit margins** per client after accounting for billable vs non-billable hours, software overhead, and tax reserves. Uncollected invoices and unmonitored accounts receivable lead to high cash flow volatility.

### 1.2 Objectives
- **Centralize Operations:** Unify client relationship management (CRM), project contracts, time logs, invoicing, and expenses into a 3NF normalized relational schema.
- **Enforce Business Data Integrity:** Build strict ACID-compliant transaction boundaries, foreign keys, domain check constraints, and cascade policies.
- **Deliver Actionable BI Analytics:** Develop Python analytics and SQL view models calculating Effective Hourly Rate (EHR), Client Lifetime Value (CLTV), Project Profit Margins, and Monthly Recurring Revenue (MRR).
- **Automate Financial Governance:** Implement parameter-validated stored procedures and database triggers for automated payment verification, invoice state transitions, and late penalty fee accruals.

### 1.3 Scope
- **In-Scope:** Client CRM, project & milestone breakdown, billable/non-billable time logging, multi-currency invoicing, payment settlement, business expense tracking, 40 SQL analytical queries, 10 window functions, Pandas analytics suite, Matplotlib visualization suite, and Streamlit/CLI executive dashboard.
- **Out-of-Scope (Current Phase):** Live Stripe API webhooks (simulated via mock handlers), native mobile apps (focused on web/desktop dashboard architecture).

### 1.4 Business Rules (BR)
- **BR-01 (Milestone Invoicing):** Invoices for milestone contracts require prior milestone approval.
- **BR-02 (Payment Settlement):** Payments reduce invoice balance; status updates to `PAID` when balance is $0.00.
- **BR-03 (Max Hour Protection):** Billable hours logged cannot exceed contract caps without approved scope amendments.
- **BR-04 (Late Payment Penalty):** Invoices unpaid past 15 days automatically accrue a 2% monthly late fee penalty.
- **BR-05 (Effective Hourly Rate):** $\text{EHR} = \frac{\text{Gross Revenue} - \text{Direct Expenses}}{\text{Total Hours Logged}}$. Non-billable hours directly decrease EHR.
- **BR-06 (Currency & Tax Rules):** Multi-currency entries store foreign currency and base equivalent.

---

## 2. Relational Database Design & Normalization

### 2.1 Normalization Verification (1NF, 2NF, 3NF)
- **1NF (Atomic Values):** All column attributes contain scalar values. Multi-valued contacts or line items are extracted into child entities `client_contacts` and `invoice_items`.
- **2NF (No Partial Dependencies):** Every non-key attribute depends on the *entire* primary key. In composite primary key table `user_roles`, `assigned_at` depends on (`user_id`, `role_id`).
- **3NF (No Transitive Dependencies):** Non-key attributes depend *only* on the primary key. Calculated financial metrics (such as client total CLTV or invoice balances) are dynamically aggregated via SQL views and Python analytics rather than stored as redundant columns.

### 2.2 Table Architecture Summary (18 Tables)
1. `roles`: System permission roles (`ADMIN`, `ACCOUNTANT`, `CLIENT`, `FREELANCER`).
2. `users`: Identity credentials, password hashes, and account states.
3. `user_roles`: Junction mapping table between users and roles ($M:N$).
4. `skills`: Technical competencies and domain skills.
5. `freelancer_skills`: Junction mapping between freelancers and skills with proficiency levels ($M:N$).
6. `clients`: Corporate client profiles, payment terms, and currency codes.
7. `client_contacts`: Individual point-of-contact persons at client companies.
8. `expense_categories`: Tax-deductible and operational expense categories.
9. `projects`: Contracts, budgets, billing models (`FIXED_PRICE`, `HOURLY`, `RETAINER`), and dates.
10. `milestones`: Deliverable phases and payment thresholds for fixed-price contracts.
11. `tasks`: Work breakdown structure items under projects.
12. `time_entries`: Billable and non-billable time logs linked to tasks and freelancers.
13. `invoices`: Financial billing headers issued to clients.
14. `invoice_items`: Itemized line details on invoices.
15. `payments`: Incoming monetary transactions settled against invoices.
16. `expenses`: Outgoing operational expenditures.
17. `project_reviews`: Client ratings (1.0 to 5.0) and feedback reviews.
18. `audit_logs`: Immutable security and financial transaction log.

---

## 3. Python Software Architecture

```
+-----------------------------------------------------------------------------------+
|                           FCMS PYTHON APPLICATION LAYOUT                          |
+-----------------------------------------------------------------------------------+
|  1. main.py               : Master system orchestrator script                     |
|  2. dashboard.py          : Dual-mode Streamlit Web App & CLI Executive Dashboard |
|  3. charts.py             : Matplotlib modern dark-theme chart suite (8 PNGs)     |
|  4. analytics.py          : Pandas BI Engine (7 DataFrames: Revenue, Profit, CLTV)|
|  5. db.py                 : DAO layer (mysql-connector-python with auto-reconnect)|
+-----------------------------------------------------------------------------------+
```

---

## 4. GitHub Repository Assets

### 4.1 GitHub Repository Bio
> Industry-level Freelance & Client Management System with Freelancer Income & Client Analytics (3NF MySQL, Python, Pandas, Matplotlib & Streamlit).

### 4.2 GitHub Topics / Tags
`mysql` `database-design` `3nf-normalization` `python` `pandas` `data-analytics` `financial-analytics` `streamlit` `matplotlib` `sql-queries` `stored-procedures` `database-triggers` `portfolio-project`

### 4.3 GitHub Description & Readme Summary
> **FCMS Analytics** is a comprehensive software engineering and data analytics project designed for freelance management and client financial intelligence. Features an 18-table 3NF relational schema, 40 business intelligence queries, 10 window function reports, 3 stored procedures, 3 triggers, a Pandas analytics engine, a Matplotlib visualization suite, and an interactive Streamlit executive dashboard.

---

## 5. Portfolio Case Study (LinkedIn / Personal Website)

### Project Title: Enterprise Freelance & Client Management System with Financial Analytics

#### Executive Summary
Designed and implemented an enterprise-grade management platform and financial intelligence engine for independent service providers. The platform addresses operational fragmentation and financial invisibility by automating contract tracking, invoicing, expense logging, and business performance analytics.

#### Key Architectural Contributions
- **Normalized Database Design:** Architected an 18-table 3NF MySQL relational database enforcing strict foreign keys, check constraints, domain validation, and zero transitive dependencies.
- **Automated Financial Governance:** Developed MySQL stored procedures and triggers to automate payment settlement, late penalty accruals, and invoice lifecycle transitions.
- **Data Analytics Engine:** Built a modular Python analytics engine using Pandas and NumPy to compute key financial indicators: Client Lifetime Value (CLTV), Effective Hourly Rate (EHR), and Billable Utilization Rate.
- **Executive Dashboard Suite:** Created an interactive Streamlit web dashboard and Matplotlib visualization pipeline rendering 8 publication-grade dark-theme business charts.

---

## 6. Resume Bullet Points (STAR Format)

- **Architected 3NF MySQL Relational Database:** Engineered an 18-table normalized database for a Freelance Management & Analytics platform, implementing 40 BI queries, 10 window functions, triggers, and stored procedures to ensure 100% data integrity.
- **Built End-to-End Python Analytics Pipeline:** Developed a modular Pandas and NumPy analytics engine that processed thousands of transactional records to compute Client Lifetime Value (CLTV), Effective Hourly Rate (EHR), and profit margins.
- **Automated Financial Governance Workflows:** Programmed MySQL stored procedures and automated triggers for parameter validation, payment reconciliation, and 2% late fee penalty calculations.
- **Created Executive Streamlit & Matplotlib Dashboard:** Built an interactive web dashboard and custom visualization engine rendering 8 high-resolution charts covering revenue growth, expense burn rate, and freelancer utilization metrics.

---

## 7. University Final Project Defense / Presentation Outline (12 Slides)

1. **Slide 1: Title Slide** — Project Title, Student Name, Course/Degree, Date.
2. **Slide 2: Problem Statement & Industry Context** — Freelancer financial invisibility, scattered spreadsheets, unbilled overtime, late payments.
3. **Slide 3: Project Objectives & Key Features** — Operational centralization, 3NF schema, BI analytics, automated invoicing.
4. **Slide 4: System Architecture** — Layered diagram (Presentation, Visualization, Analytics, DAO, Database).
5. **Slide 5: Database Architecture & ER Diagram** — 18 Entities, Crow's Foot notation, 3NF compliance, key relationships.
6. **Slide 6: Business Rules & Governance** — Milestone rules, balance settlement, late fee accruals (BR-01 to BR-06).
7. **Slide 7: Advanced SQL Implementation** — 40 BI queries, window functions (`LAG`, `LEAD`, `SUM OVER`), stored procedures, and triggers.
8. **Slide 8: Python Data Analytics Engine (Pandas)** — Data processing pipelines for EHR, CLTV, and profit margins.
9. **Slide 9: Visualization Suite (Matplotlib)** — Overview of 8 custom dark-theme charts (Revenue, Expenses, Profit Trends).
10. **Slide 10: Executive Streamlit Dashboard Demo** — Live demonstration of interactive web UI metrics and data tables.
11. **Slide 11: Future Scope & Enhancements** — AI OCR expense parsing, Open Banking reconciliation, multi-tenant SaaS architecture.
12. **Slide 12: Q&A & Conclusion** — Final summary and opening floor for evaluation committee questions.
