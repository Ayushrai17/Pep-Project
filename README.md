# Freelance & Client Management System with Freelancer Income & Client Analytics (FCMS Analytics)

[![Database](https://img.shields.io/badge/Database-MySQL%208.0%20%7C%203NF%20Normalized-blue?style=for-the-badge&logo=mysql)](https://www.mysql.com/)
[![Python](https://img.shields.io/badge/Python-3.10%2B-green?style=for-the-badge&logo=python)](https://www.python.org/)
[![Analytics](https://img.shields.io/badge/Analytics-Pandas%20%26%20NumPy-orange?style=for-the-badge&logo=pandas)](https://pandas.pydata.org/)
[![Visualization](https://img.shields.io/badge/Visualization-Matplotlib-red?style=for-the-badge)](https://matplotlib.org/)
[![Dashboard](https://img.shields.io/badge/Dashboard-Streamlit-FF4B4B?style=for-the-badge&logo=streamlit)](https://streamlit.io/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

**Developer:** **Ayush Rai**  
**Version:** 2.5 (Enterprise Edition)  

---

## 📌 Executive Summary
**FCMS Analytics** is an industry-grade, end-to-end platform engineered for independent contractors, freelancers, and boutique service agencies. The system unifies operational CRM, project contract tracking, time logging, invoicing, and expense management with a 3NF normalized relational SQL backend and a Python data analytics engine. 

The platform converts raw operational data into executive-level business intelligence, including **Client Lifetime Value (CLTV)**, **Effective Hourly Rate (EHR)**, **Project Profit Margins**, **Accounts Receivable Aging**, and **Monthly Recurring Revenue (MRR)** forecasting.

---

## 🔐 Demo Credentials & Login Access
The web application features an authentication login system:

- **Login URL:** Launched via `streamlit run app.py`
- **Username:** `admin`
- **Password:** `admin123`

---

## 🏗️ System Architecture & Technology Stack

```
+-----------------------------------------------------------------------------------+
|                            FCMS ANALYTICS ARCHITECTURE                            |
+-----------------------------------------------------------------------------------+
|  PRESENTATION LAYER       : Streamlit Interactive Light Theme Web Dashboard (10 Pages)|
|  VISUALIZATION LAYER     : Matplotlib Custom Dark Theme Chart Engine (10 Charts)  |
|  DATA ANALYTICS LAYER     : Pandas & NumPy Data Engines (7 Core Business DataFrames)|
|  DATA ACCESS LAYER (DAO)  : db.py (mysql-connector-python with Auto-Reconnect)    |
|  DATABASE BACKEND LAYER   : MySQL 8.0 (18 Tables in 3NF, 5 Views, Triggers,       |
|                             Procedures, Indexes, & 40 Analytical BI Queries)       |
+-----------------------------------------------------------------------------------+
```

---

## 📁 Repository Folder Structure

```
Freelance-Management-System/
│
├── SQL/                                 # SQL Database Initialization & Logic Scripts
│   ├── database.sql                     # Database Context Creation
│   ├── tables.sql                       # 3NF DDL Table Creation Script (18 Tables)
│   ├── insert_data.sql                  # Production Seed Data Script
│   ├── update_delete.sql                # Business Operations Transactions
│   ├── views.sql                        # 5 Pre-computed Analytical Database Views
│   ├── queries.sql                      # 40 Business Intelligence & Analytical Queries
│   ├── procedures.sql                   # 3 Parameter-Validated Stored Procedures
│   ├── triggers.sql                     # 3 Automated Validation & Status Triggers
│   └── window_functions.sql             # 10 Advanced Analytical Window Function Queries
│
├── Python/                              # Python Backend & Analytics Engine Modules
│   ├── db.py                            # MySQL Connection & DAO Module
│   ├── analytics.py                     # Pandas Data Analytics Engine
│   ├── charts.py                        # Matplotlib Visualization Generator (10 Charts)
│   ├── dashboard.py                     # CLI & Streamlit Interactive Executive Dashboard
│   ├── reports.py                       # Text & Markdown Financial Statement Generator
│   ├── app.py                           # Streamlit Web Application
│   └── main.py                          # Master Application Orchestrator Script
│
├── images/                              # Generated High-Res Visualizations (.png)
│   ├── revenue_trend.png
│   ├── expense_trend.png
│   ├── profit_trend.png
│   ├── revenue_vs_expense.png
│   ├── top_clients.png
│   ├── top_freelancers.png
│   ├── project_status.png
│   ├── budget_distribution.png
│   ├── ratings_distribution.png
│   └── payment_methods.png
│
├── report/                              # Technical Project Report
│   └── project_report.md
│
├── presentation/                        # Presentation Pitch Deck Outline
│   └── presentation_outline.md
│
├── docs/                                # Architectural & Design Specifications
│   ├── project_specification.md         # System Requirements Specification (SRS)
│   ├── database_design.md               # 3NF Relational Schema Specification
│   ├── er_diagram_spec.md               # ER Diagram, Mermaid Code & FK Matrix
│   └── portfolio_and_resume.md          # Case Study, Resume Bullets & Pitch Deck
│
├── app.py                               # Root Web App Entrypoint Shortcut
├── main.py                              # Root Entrypoint Shortcut
├── dashboard.py                         # Root Dashboard Entrypoint Shortcut
├── requirements.txt                     # Python Dependencies
├── .gitignore                           # Git Exclusion Rules
├── LICENSE                              # MIT License
└── README.md                            # Complete Project Documentation
```

---

## ⚡ Quick Start & Execution Guide

### 1. Database Setup (MySQL)
Execute the SQL scripts in order using MySQL CLI or Workbench:

```sql
SOURCE SQL/database.sql;
SOURCE SQL/tables.sql;
SOURCE SQL/insert_data.sql;
SOURCE SQL/update_delete.sql;
SOURCE SQL/views.sql;
SOURCE SQL/queries.sql;
SOURCE SQL/procedures.sql;
SOURCE SQL/triggers.sql;
SOURCE SQL/window_functions.sql;
```

### 2. Python Dependencies Installation
Install required packages via pip:

```bash
pip install -r requirements.txt
```

### 3. Database Credentials Configuration
Verify or edit connection parameters in `Python/db.py`:

```python
DB_CONFIG = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "your_mysql_password",
    "database": "freelance_management"
}
```

### 4. Running the Master System Pipeline
Run the master orchestrator to verify database connection, run analytics, generate all 10 chart images in `images/`, and display executive terminal reports:

```bash
python main.py
```

### 5. Launching the Interactive Web Frontend
Launch the Streamlit interactive web application:

```bash
streamlit run app.py
```

Login credentials: Username `admin` | Password `admin123`

---

## 📄 License & Author
Developed by **Ayush Rai**. Released under the [MIT License](LICENSE).
