# University Final Project Defense & Presentation Outline (12 Slides)

**Project Title:** Freelance & Client Management System with Freelancer Income & Client Analytics (**FCMS Analytics**)  
**Presenter:** Senior Software Engineer / Lead Database Architect  

---

### Slide 1: Title & Overview
- **Header:** Freelance & Client Management System (FCMS Analytics)
- **Sub-header:** Database Architecture, Python Data Engineering & Business Intelligence Suite
- **Bullet Points:**
  - Integrated 3NF Relational Database (MySQL 8.0)
  - Python Data Analytics Engine (Pandas & NumPy)
  - Publication-Quality Data Visualizations (Matplotlib)
  - Dual-Mode Executive Dashboard (Streamlit & CLI)

---

### Slide 2: Industry Problem Statement
- **Header:** Operational & Financial Challenges in Freelancing
- **Bullet Points:**
  - Scattered spreadsheets & disconnected tools cause operational chaos.
  - Absence of true net profit visibility (billable vs non-billable hours, software expenses, tax reserves).
  - Scope creep, unbilled overtime, and milestone deliverable disputes.
  - High accounts receivable delinquency and cash flow volatility.

---

### Slide 3: Project Objectives & Core Scope
- **Header:** Project Goals & Technical Scope
- **Bullet Points:**
  - Centralize CRM, contracts, time entries, invoicing, and expenses into a single normalized schema.
  - Enforce 100% referential integrity and ACID-compliant transaction boundaries.
  - Deliver automated financial governance via MySQL stored procedures and triggers.
  - Generate actionable business intelligence: Client Lifetime Value (CLTV), Effective Hourly Rate (EHR), and Net Profit Margins.

---

### Slide 4: Business Rules & Governance
- **Header:** Key Business Domain Rules
- **Bullet Points:**
  - **BR-01:** Milestone-based invoices require prior client milestone approval.
  - **BR-02:** Payments automatically update invoice balances and trigger status transitions (`PAID` / `PARTIALLY_PAID`).
  - **BR-04:** Overdue invoices (> 15 days) automatically accrue a 2% monthly late fee.
  - **BR-05:** Effective Hourly Rate ($\text{EHR}$) factors in direct project expenses and non-billable overhead time.

---

### Slide 5: System Architecture & Data Pipeline
- **Header:** Layered Software Architecture
- **Bullet Points:**
  - **Presentation Layer:** Interactive Streamlit Web UI & CLI Terminal Summaries.
  - **Visualization Layer:** Matplotlib Custom Dark-Theme Chart Suite (10 Charts).
  - **Analytics Layer:** Pandas Data Processing Engine (7 Core DataFrames).
  - **Data Access Layer:** `db.py` (mysql-connector-python DAO with auto-reconnect).
  - **Database Backend:** 3NF MySQL Database (18 Tables, 40 BI Queries, 10 Window Functions, 5 Views).

---

### Slide 6: Database Schema & 3NF Normalization
- **Header:** 18-Entity Relational Database Structure
- **Bullet Points:**
  - **1NF Verification:** Atomic scalar attributes; repeating groups extracted into child entities (`client_contacts`, `invoice_items`).
  - **2NF Verification:** Zero partial dependencies; composite PK tables (`user_roles`, `freelancer_skills`) fully dependent on candidate keys.
  - **3NF Verification:** Zero transitive dependencies; calculated financial metrics generated dynamically via SQL Views and Python Pandas.

---

### Slide 7: Advanced SQL Features & Governance
- **Header:** Views, Stored Procedures & Triggers
- **Bullet Points:**
  - **5 Database Views:** `v_invoice_summary`, `v_client_analytics`, `v_freelancer_utilization`, `v_project_budget_variance`, `v_monthly_financials`.
  - **3 Stored Procedures:** `sp_add_project`, `sp_generate_invoice`, `sp_record_payment` (with SQLSTATE parameter validation).
  - **3 Triggers:** `trg_validate_payment_before_insert`, `trg_auto_update_project_status_after_milestone`, `trg_log_expense_changes_after_update`.

---

### Slide 8: Analytical SQL Queries & Window Functions
- **Header:** Business Intelligence & Advanced Analytics
- **Bullet Points:**
  - **40 BI Queries:** Revenue trends, expense burn rates, profit margins, repeat clients, aging accounts receivable.
  - **10 Window Function Reports:** `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `LAG()`, `LEAD()`, `SUM() OVER()`, `AVG() OVER()`.

---

### Slide 9: Python Data Analytics & Visualization Engine
- **Header:** Pandas Data Engine & Matplotlib Chart Suite
- **Bullet Points:**
  - Modular `FCMSAnalyticsEngine` class loading SQL tables directly into Pandas DataFrames.
  - Custom dark-theme visualization suite generating 10 high-res chart PNGs saved to `images/`.
  - Automated report generator producing formatted financial statements and aging receivables.

---

### Slide 10: Executive Interactive Dashboard (Demo)
- **Header:** Live Streamlit & CLI Executive Dashboard
- **Bullet Points:**
  - Real-time KPI Metric Cards (Total Revenue, Total Expenses, Net Profit, Pending Payments, Completed Projects).
  - Interactive multi-tabbed layout for Financials, Client CRM, Freelancer Performance, and Project Portfolios.
  - CLI fallback mode providing terminal executive summaries.

---

### Slide 11: Future Scope & Enhancements
- **Header:** Future System Expansion
- **Bullet Points:**
  - **AI OCR Expense Parsing:** Machine learning vision models to auto-extract paper receipts.
  - **Open Banking API Integration:** Live bank feed sync for automated invoice reconciliation.
  - **Multi-Tenant SaaS Infrastructure:** Schema multi-tenancy for agency team collaboration.

---

### Slide 12: Conclusion & Q&A
- **Header:** Final Summary & Q&A
- **Bullet Points:**
  - Successfully built a complete, production-ready, error-free management platform and analytics engine.
  - Fully verified database integrity, SQL execution, Python analytics, and visualization output.
  - Floor open for Evaluation Committee Questions.
