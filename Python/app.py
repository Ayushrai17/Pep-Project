"""
Enterprise Streamlit Web Application: app.py
Project: Freelance & Client Management System with Freelancer Income & Client Analytics
Developer: Ayush Rai
Description: Full-stack, responsive, light-themed Streamlit application with authentication login,
sidebar navigation across 10 pages, KPI metric cards, interactive search/filters, data tables,
custom Matplotlib chart visualizations, multi-format report exports (CSV, Markdown, Text), Settings, and About page.
"""

import os
import sys
import logging
import io
import pandas as pd
import numpy as np
import streamlit as st
import matplotlib.pyplot as plt

# Adjust sys.path to include Python subfolder
sys.path.append(os.path.join(os.path.dirname(__file__), "Python"))
from analytics import FCMSAnalyticsEngine
from db import get_connection, fetch_data, execute_query
from charts import (
    plot_revenue_trend,
    plot_expense_trend,
    plot_profit_trend,
    plot_revenue_vs_expense,
    plot_top_clients,
    plot_top_freelancers,
    plot_project_status,
    plot_budget_distribution,
    plot_ratings_distribution,
    plot_payment_methods
)

# Configure Logger
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Streamlit Page Configuration
st.set_page_config(
    page_title="FCMS Analytics | Freelance & Client Management System",
    page_icon="💼",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Modern Light Theme Custom CSS Aesthetics
LIGHT_THEME_CSS = """
<style>
    /* Global Page Styling */
    .main {
        background-color: #F8FAFC;
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    }
    
    /* Headers & Branding */
    h1, h2, h3 {
        color: #0F172A;
        font-weight: 700;
        letter-spacing: -0.02em;
    }
    
    /* Custom Sidebar Styling */
    section[data-testid="stSidebar"] {
        background-color: #FFFFFF;
        border-right: 1px solid #E2E8F0;
    }
    
    /* Metric Cards */
    div[data-testid="stMetricValue"] {
        font-size: 1.75rem !important;
        font-weight: 700 !important;
        color: #0F172A !important;
    }
    div[data-testid="stMetricLabel"] {
        font-size: 0.875rem !important;
        color: #64748B !important;
        font-weight: 600 !important;
    }
    
    /* Login Form Card */
    .login-card {
        background-color: #FFFFFF;
        padding: 40px;
        border-radius: 16px;
        border: 1px solid #E2E8F0;
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05);
        max-width: 450px;
        margin: 40px auto;
    }
    
    /* Footer Styling */
    .footer {
        position: fixed;
        left: 0;
        bottom: 0;
        width: 100%;
        background-color: #FFFFFF;
        color: #64748B;
        text-align: center;
        padding: 8px;
        font-size: 0.8rem;
        border-top: 1px solid #E2E8F0;
        z-index: 100;
    }
</style>
"""
st.markdown(LIGHT_THEME_CSS, unsafe_allow_html=True)

# Initialize Session State for Authentication
if "logged_in" not in st.session_state:
    st.session_state["logged_in"] = False
if "username" not in st.session_state:
    st.session_state["username"] = ""


# ------------------------------------------------------------------------------
# AUTHENTICATION LOGIN PAGE
# ------------------------------------------------------------------------------
def render_login_page():
    st.markdown("<br><br>", unsafe_allow_html=True)
    col1, col2, col3 = st.columns([1, 2, 1])

    with col2:
        st.image("https://img.icons8.com/isometric/96/briefcase.png", width=72)
        st.title("💼 FCMS Analytics")
        st.subheader("Freelance & Client Management System")
        st.caption("Developed by: **Ayush Rai**")
        st.divider()

        with st.form("login_form"):
            st.write("🔒 **Sign In to Access Executive Dashboard**")
            input_user = st.text_input("Username", value="admin", placeholder="Enter username")
            input_pass = st.text_input("Password", value="admin123", type="password", placeholder="Enter password")
            submit_btn = st.form_submit_button("🚀 Login to System", use_container_width=True)

            if submit_btn:
                if input_user == "admin" and input_pass == "admin123":
                    st.session_state["logged_in"] = True
                    st.session_state["username"] = input_user
                    st.success("Authentication successful! Redirecting...")
                    st.rerun()
                else:
                    st.error("Invalid credentials. Demo Access: Username `admin` | Password `admin123`")

        st.info("💡 **Demo Credentials:** Username: `admin` | Password: `admin123`")


if not st.session_state["logged_in"]:
    render_login_page()
    st.stop()


# Cached Analytics Data Engine
@st.cache_data(ttl=60)
def get_cached_analytics_engine():
    engine = FCMSAnalyticsEngine()
    engine.load_all_tables()
    return engine


engine = get_cached_analytics_engine()

# ------------------------------------------------------------------------------
# SIDEBAR NAVIGATION
# ------------------------------------------------------------------------------
st.sidebar.image("https://img.icons8.com/isometric/96/briefcase.png", width=48)
st.sidebar.title("FCMS Analytics")
st.sidebar.caption("System Version 2.5 (Enterprise)")

page = st.sidebar.radio(
    "Navigation",
    [
        "🏠 Dashboard",
        "👨 Freelancers",
        "🏢 Clients",
        "📁 Projects",
        "💳 Payments",
        "💸 Expenses",
        "📊 Analytics",
        "📄 Reports",
        "⚙ Settings",
        "ℹ About"
    ]
)

st.sidebar.divider()
st.sidebar.markdown(f"👤 **Logged User:** {st.session_state['username']}")
st.sidebar.caption("👨‍💻 **Developer:** Ayush Rai")

if st.sidebar.button("🚪 Logout", use_container_width=True):
    st.session_state["logged_in"] = False
    st.session_state["username"] = ""
    st.rerun()


# ==============================================================================
# PAGE 1: DASHBOARD
# ==============================================================================
if page == "🏠 Dashboard":
    st.title("📊 Executive Performance Dashboard")
    st.caption("Real-time operational summaries, cash flow indicators, and KPI highlights")

    invoices_df = engine.tables.get("invoices", pd.DataFrame())
    expenses_df = engine.tables.get("expenses", pd.DataFrame())
    clients_df = engine.tables.get("clients", pd.DataFrame())
    projects_df = engine.tables.get("projects", pd.DataFrame())
    users_df = engine.tables.get("users", pd.DataFrame())
    reviews_df = engine.tables.get("project_reviews", pd.DataFrame())

    # Financial Summaries
    paid_inv = invoices_df[invoices_df["status"] == "PAID"] if not invoices_df.empty else pd.DataFrame()
    pending_inv = invoices_df[invoices_df["status"].isin(["ISSUED", "OVERDUE", "PARTIALLY_PAID"])] if not invoices_df.empty else pd.DataFrame()

    total_revenue = paid_inv["total_amount"].sum() if not paid_inv.empty else 0.0
    pending_payments = pending_inv["total_amount"].sum() if not pending_inv.empty else 0.0
    total_expenses = expenses_df["amount"].sum() if not expenses_df.empty else 0.0
    net_profit = total_revenue - total_expenses
    profit_margin = (net_profit / total_revenue * 100) if total_revenue > 0 else 0.0

    total_projects = len(projects_df) if not projects_df.empty else 0
    completed_projects = len(projects_df[projects_df["status"] == "COMPLETED"]) if not projects_df.empty else 0
    total_clients = len(clients_df) if not clients_df.empty else 0
    freelancers_count = len(users_df[users_df["user_id"] >= 6]) if not users_df.empty else 0
    avg_rating = reviews_df["rating"].mean() if not reviews_df.empty else 0.0

    # Advanced Highlight Metrics
    if not paid_inv.empty:
        paid_inv["month"] = pd.to_datetime(paid_inv["issue_date"]).dt.to_period("M").astype(str)
        rev_by_month = paid_inv.groupby("month")["total_amount"].sum()
        highest_rev_month = rev_by_month.idxmax() if not rev_by_month.empty else "N/A"
    else:
        highest_rev_month = "N/A"

    client_analytics = engine.get_client_analytics()
    highest_paying_client = client_analytics.iloc[0]["company_name"] if not client_analytics.empty else "N/A"

    freelancer_analytics = engine.get_freelancer_analytics()
    top_freelancer_name = freelancer_analytics.iloc[0]["freelancer_name"] if not freelancer_analytics.empty else "N/A"

    # KPI Cards Row 1
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("💰 Total Revenue", f"₹{total_revenue:,.2f}")
    c2.metric("💸 Total Expenses", f"₹{total_expenses:,.2f}")
    c3.metric("📈 Net Profit", f"₹{net_profit:,.2f}", f"{profit_margin:.1f}% Margin")
    c4.metric("⏳ Pending Payments", f"₹{pending_payments:,.2f}")

    st.markdown("<br>", unsafe_allow_html=True)

    # KPI Cards Row 2
    c5, c6, c7, c8 = st.columns(4)
    c5.metric("📁 Total Projects", f"{total_projects}")
    c6.metric("✅ Completed Contracts", f"{completed_projects}")
    c7.metric("🏢 Total Clients", f"{total_clients}")
    c8.metric("⭐ Avg Rating", f"{avg_rating:.2f} / 5.0")

    st.divider()

    # Executive Highlights Panel
    st.subheader("🌟 Executive Highlights & Top Performers")
    h1, h2, h3 = st.columns(3)
    h1.info(f"📅 **Highest Revenue Month:**\n### {highest_rev_month}")
    h2.success(f"🏆 **Highest Paying Client:**\n### {highest_paying_client}")
    h3.warning(f"🌟 **Top Rated Freelancer:**\n### {top_freelancer_name}")

    st.divider()

    # Dashboard Visualizations Grid
    grid1, grid2 = st.columns(2)
    with grid1:
        st.subheader("📉 Monthly Revenue Trend")
        img = plot_revenue_trend()
        if img: st.image(img)
    with grid2:
        st.subheader("🍕 Expense Distribution")
        img = plot_payment_methods()
        if img: st.image(img)

    grid3, grid4 = st.columns(2)
    with grid3:
        st.subheader("🏆 Top 10 Clients by CLTV")
        img = plot_top_clients()
        if img: st.image(img)
    with grid4:
        st.subheader("📊 Project Status Breakdown")
        img = plot_project_status()
        if img: st.image(img)


# ==============================================================================
# PAGE 2: FREELANCERS
# ==============================================================================
elif page == "👨 Freelancers":
    st.title("👨 Freelancer Roster & Performance")
    freelancer_df = engine.get_freelancer_analytics()

    if not freelancer_df.empty:
        m1, m2, m3, m4 = st.columns(4)
        m1.metric("Active Freelancers", len(freelancer_df))
        m2.metric("Total Hours Logged", f"{freelancer_df['total_logged_hours'].sum():,.1f} hrs")
        m3.metric("Billable Hours", f"{freelancer_df['billable_hours'].sum():,.1f} hrs")
        m4.metric("Avg Utilization Rate", f"{freelancer_df['billable_utilization_pct'].mean():.1f}%")

        st.divider()
        c1, c2 = st.columns([2, 1])
        search_query = c1.text_input("🔍 Search Freelancer (Name / Email)", "")
        status_filter = c2.selectbox("Account Status", ["ALL", "ACTIVE", "INACTIVE", "SUSPENDED"])

        filtered = freelancer_df.copy()
        if search_query:
            filtered = filtered[
                filtered["freelancer_name"].str.contains(search_query, case=False, na=False) |
                filtered["email"].str.contains(search_query, case=False, na=False)
            ]
        if status_filter != "ALL":
            filtered = filtered[filtered["status"] == status_filter]

        st.dataframe(filtered, use_container_width=True)

    # Interactive Management Section (CRUD)
    with st.expander("⚙️ Manage Freelancers (Add / Edit / Delete)", expanded=False):
        crud_tab1, crud_tab2, crud_tab3 = st.tabs(["➕ Add Freelancer", "✏️ Edit Status/Email", "🗑️ Delete Freelancer"])
        
        with crud_tab1:
            with st.form("add_freelancer_form"):
                f_first = st.text_input("First Name")
                f_last = st.text_input("Last Name")
                f_email = st.text_input("Email")
                f_pass = st.text_input("Password Hash", value="pbkdf2:sha256:default_hash", type="password")
                f_status = st.selectbox("Status", ["ACTIVE", "INACTIVE", "SUSPENDED"])
                f_submit = st.form_submit_button("➕ Register Freelancer")
                
                if f_submit:
                    if not f_first or not f_last or not f_email:
                        st.error("First Name, Last Name, and Email are required.")
                    else:
                        res = execute_query(
                            "INSERT INTO users (email, password_hash, first_name, last_name, status) VALUES (%s, %s, %s, %s, %s)",
                            (f_email, f_pass, f_first, f_last, f_status)
                        )
                        if res:
                            execute_query("INSERT INTO user_roles (user_id, role_id) VALUES (%s, 2)", (res["lastrowid"],))
                            st.success(f"Freelancer '{f_first} {f_last}' added successfully! (ID: {res['lastrowid']})")
                            st.cache_data.clear()
                            st.rerun()
                        else:
                            st.error("Failed to add freelancer. Check if email already exists.")
                            
        with crud_tab2:
            users_list = fetch_data("SELECT user_id, email, first_name, last_name, status FROM users ORDER BY user_id DESC")
            if users_list:
                u_df = pd.DataFrame(users_list)
                u_df["display"] = u_df.apply(lambda r: f"#{r['user_id']} - {r['first_name']} {r['last_name']} ({r['email']})", axis=1)
                selected_u_disp = st.selectbox("Select Freelancer to Edit", u_df["display"])
                sel_user = u_df[u_df["display"] == selected_u_disp].iloc[0]
                
                with st.form("edit_freelancer_form"):
                    e_email = st.text_input("Email", value=sel_user["email"])
                    e_status = st.selectbox("Status", ["ACTIVE", "INACTIVE", "SUSPENDED"], index=["ACTIVE", "INACTIVE", "SUSPENDED"].index(sel_user["status"]) if sel_user["status"] in ["ACTIVE", "INACTIVE", "SUSPENDED"] else 0)
                    e_submit = st.form_submit_button("💾 Save Changes")
                    
                    if e_submit:
                        res = execute_query(
                            "UPDATE users SET email = %s, status = %s WHERE user_id = %s",
                            (e_email, e_status, sel_user["user_id"])
                        )
                        if res is not None:
                            st.success("Freelancer profile updated successfully!")
                            st.cache_data.clear()
                            st.rerun()
                        else:
                            st.error("Failed to update freelancer.")

        with crud_tab3:
            users_list = fetch_data("SELECT user_id, email, first_name, last_name FROM users ORDER BY user_id DESC")
            if users_list:
                u_df = pd.DataFrame(users_list)
                u_df["display"] = u_df.apply(lambda r: f"#{r['user_id']} - {r['first_name']} {r['last_name']} ({r['email']})", axis=1)
                del_u_disp = st.selectbox("Select Freelancer to Delete", u_df["display"], key="del_u_select")
                del_user_id = u_df[u_df["display"] == del_u_disp].iloc[0]["user_id"]
                
                if st.button("🗑️ Delete Freelancer", type="primary"):
                    res = execute_query("DELETE FROM users WHERE user_id = %s", (del_user_id,))
                    if res is not None:
                        st.success(f"Freelancer #{del_user_id} deleted successfully!")
                        st.cache_data.clear()
                        st.rerun()
                    else:
                        st.error("Failed to delete freelancer (Record may be referenced in active tasks or time entries).")


# ==============================================================================
# PAGE 3: CLIENTS
# ==============================================================================
elif page == "🏢 Clients":
    st.title("🏢 Client Relationship Management (CRM)")
    client_df = engine.get_client_analytics()

    if not client_df.empty:
        m1, m2, m3, m4 = st.columns(4)
        m1.metric("Total Clients", len(client_df))
        m2.metric("Repeat Clients", len(client_df[client_df["is_repeat_client"] == True]))
        m3.metric("Total CLTV", f"₹{client_df['client_lifetime_value'].sum():,.2f}")
        m4.metric("Flagged Late Clients", len(client_df[client_df["status"] == "FLAGGED_LATE"]))

        st.divider()
        c1, c2, c3 = st.columns([2, 1, 1])
        search_query = c1.text_input("🔍 Search Client Company", "")
        status_filter = c2.selectbox("Status Filter", ["ALL", "ACTIVE", "LEAD", "INACTIVE", "FLAGGED_LATE"])
        currency_filter = c3.selectbox("Currency Code", ["ALL", "INR"])

        filtered = client_df.copy()
        if search_query:
            filtered = filtered[filtered["company_name"].str.contains(search_query, case=False, na=False)]
        if status_filter != "ALL":
            filtered = filtered[filtered["status"] == status_filter]
        if currency_filter != "ALL":
            filtered = filtered[filtered["currency_code"] == currency_filter]

        st.dataframe(filtered, use_container_width=True)

    # Interactive Management Section (CRUD)
    with st.expander("⚙️ Manage Clients (Add / Edit / Delete)", expanded=False):
        crud_tab1, crud_tab2, crud_tab3 = st.tabs(["➕ Add Client", "✏️ Edit Client", "🗑️ Delete Client"])
        
        with crud_tab1:
            with st.form("add_client_form"):
                c_name = st.text_input("Company Name")
                c_tax = st.text_input("Tax Identifier / GSTIN", placeholder="e.g. TAX-12345")
                c_curr = st.selectbox("Currency Code", ["INR"])
                c_terms = st.number_input("Payment Terms (Days)", min_value=0, max_value=180, value=30)
                c_status = st.selectbox("Status", ["LEAD", "ACTIVE", "INACTIVE", "FLAGGED_LATE"])
                c_address = st.text_area("Billing Address", placeholder="Street, City, Country")
                c_submit = st.form_submit_button("➕ Register Client")
                
                if c_submit:
                    if not c_name:
                        st.error("Company Name is required.")
                    else:
                        res = execute_query(
                            "INSERT INTO clients (company_name, tax_identifier, currency_code, payment_terms_days, status, billing_address) VALUES (%s, %s, %s, %s, %s, %s)",
                            (c_name, c_tax or None, c_curr, c_terms, c_status, c_address or None)
                        )
                        if res:
                            st.success(f"Client '{c_name}' added successfully! (ID: {res['lastrowid']})")
                            st.cache_data.clear()
                            st.rerun()
                        else:
                            st.error("Failed to add client.")

        with crud_tab2:
            all_clients = fetch_data("SELECT client_id, company_name, tax_identifier, currency_code, payment_terms_days, status, billing_address FROM clients ORDER BY client_id DESC")
            if all_clients:
                c_df = pd.DataFrame(all_clients)
                c_df["display"] = c_df.apply(lambda r: f"#{r['client_id']} - {r['company_name']}", axis=1)
                selected_c_disp = st.selectbox("Select Client to Edit", c_df["display"])
                sel_client = c_df[c_df["display"] == selected_c_disp].iloc[0]
                
                with st.form("edit_client_form"):
                    e_name = st.text_input("Company Name", value=sel_client["company_name"])
                    e_tax = st.text_input("Tax Identifier", value=sel_client["tax_identifier"] or "")
                    e_curr = st.selectbox("Currency Code", ["INR"])
                    e_terms = st.number_input("Payment Terms (Days)", min_value=0, max_value=180, value=int(sel_client["payment_terms_days"]))
                    e_status = st.selectbox("Status", ["LEAD", "ACTIVE", "INACTIVE", "FLAGGED_LATE"], index=["LEAD", "ACTIVE", "INACTIVE", "FLAGGED_LATE"].index(sel_client["status"]) if sel_client["status"] in ["LEAD", "ACTIVE", "INACTIVE", "FLAGGED_LATE"] else 1)
                    e_addr = st.text_area("Billing Address", value=sel_client["billing_address"] or "")
                    e_submit = st.form_submit_button("💾 Save Changes")
                    
                    if e_submit:
                        res = execute_query(
                            "UPDATE clients SET company_name=%s, tax_identifier=%s, currency_code=%s, payment_terms_days=%s, status=%s, billing_address=%s WHERE client_id=%s",
                            (e_name, e_tax or None, e_curr, e_terms, e_status, e_addr or None, sel_client["client_id"])
                        )
                        if res is not None:
                            st.success("Client details updated successfully!")
                            st.cache_data.clear()
                            st.rerun()
                        else:
                            st.error("Failed to update client.")

        with crud_tab3:
            all_clients = fetch_data("SELECT client_id, company_name FROM clients ORDER BY client_id DESC")
            if all_clients:
                c_df = pd.DataFrame(all_clients)
                c_df["display"] = c_df.apply(lambda r: f"#{r['client_id']} - {r['company_name']}", axis=1)
                del_c_disp = st.selectbox("Select Client to Delete", c_df["display"], key="del_c_select")
                del_client_id = c_df[c_df["display"] == del_c_disp].iloc[0]["client_id"]
                
                if st.button("🗑️ Delete Client", type="primary"):
                    res = execute_query("DELETE FROM clients WHERE client_id = %s", (del_client_id,))
                    if res is not None:
                        st.success(f"Client #{del_client_id} deleted successfully!")
                        st.cache_data.clear()
                        st.rerun()
                    else:
                        st.error("Failed to delete client (Client has active projects or invoices linked).")


# ==============================================================================
# PAGE 4: PROJECTS
# ==============================================================================
elif page == "📁 Projects":
    st.title("📁 Project Portfolio & Contract Management")
    project_df = engine.get_project_analytics()

    if not project_df.empty:
        m1, m2, m3, m4 = st.columns(4)
        m1.metric("Total Projects", len(project_df))
        m2.metric("Active Projects", len(project_df[project_df["status"] == "ACTIVE"]))
        m3.metric("Completed Contracts", len(project_df[project_df["status"] == "COMPLETED"]))
        m4.metric("Over Budget Projects", len(project_df[project_df["budget_health"] == "OVER_BUDGET"]))

        st.divider()
        c1, c2, c3 = st.columns([2, 1, 1])
        search_query = c1.text_input("🔍 Search Project Title", "")
        model_filter = c2.selectbox("Billing Model", ["ALL", "FIXED_PRICE", "HOURLY", "RETAINER"])
        status_filter = c3.selectbox("Status", ["ALL", "ACTIVE", "COMPLETED", "PROPOSED", "CANCELLED"])

        filtered = project_df.copy()
        if search_query:
            filtered = filtered[filtered["project_name"].str.contains(search_query, case=False, na=False)]
        if model_filter != "ALL":
            filtered = filtered[filtered["billing_model"] == model_filter]
        if status_filter != "ALL":
            filtered = filtered[filtered["status"] == status_filter]

        st.dataframe(filtered, use_container_width=True)

    # Interactive Management Section (CRUD)
    with st.expander("⚙️ Manage Projects (Add / Edit / Delete)", expanded=False):
        crud_tab1, crud_tab2, crud_tab3 = st.tabs(["➕ Add Project", "✏️ Edit Project", "🗑️ Delete Project"])
        
        all_clients_list = fetch_data("SELECT client_id, company_name FROM clients ORDER BY company_name")
        client_options = {f"#{c['client_id']} - {c['company_name']}": c['client_id'] for c in all_clients_list} if all_clients_list else {}

        with crud_tab1:
            with st.form("add_project_form"):
                p_name = st.text_input("Project Title")
                p_client_disp = st.selectbox("Client", list(client_options.keys()) if client_options else ["No Clients Found"])
                p_model = st.selectbox("Billing Model", ["FIXED_PRICE", "HOURLY", "RETAINER"])
                p_rate = st.number_input("Hourly Rate (if applicable)", min_value=0.0, value=50.0, step=5.0)
                p_budget = st.number_input("Total Budget", min_value=0.0, value=5000.0, step=500.0)
                p_status = st.selectbox("Status", ["PROPOSED", "ACTIVE", "ON_HOLD", "COMPLETED", "CANCELLED"], index=1)
                p_start = st.date_input("Start Date")
                p_desc = st.text_area("Description")
                p_submit = st.form_submit_button("➕ Create Project")
                
                if p_submit:
                    if not p_name or not client_options:
                        st.error("Project Title and Client are required.")
                    else:
                        selected_cid = client_options[p_client_disp]
                        res = execute_query(
                            "INSERT INTO projects (client_id, project_name, description, billing_model, hourly_rate, total_budget, status, start_date) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                            (selected_cid, p_name, p_desc or None, p_model, p_rate if p_model=="HOURLY" else None, p_budget, p_status, str(p_start))
                        )
                        if res:
                            st.success(f"Project '{p_name}' created successfully! (ID: {res['lastrowid']})")
                            st.cache_data.clear()
                            st.rerun()
                        else:
                            st.error("Failed to create project.")

        with crud_tab2:
            all_projects = fetch_data("SELECT project_id, project_name, billing_model, hourly_rate, total_budget, status, description FROM projects ORDER BY project_id DESC")
            if all_projects:
                proj_df = pd.DataFrame(all_projects)
                proj_df["display"] = proj_df.apply(lambda r: f"#{r['project_id']} - {r['project_name']} [{r['status']}]", axis=1)
                selected_p_disp = st.selectbox("Select Project to Edit", proj_df["display"])
                sel_proj = proj_df[proj_df["display"] == selected_p_disp].iloc[0]
                
                with st.form("edit_project_form"):
                    e_pname = st.text_input("Project Name", value=sel_proj["project_name"])
                    e_pmodel = st.selectbox("Billing Model", ["FIXED_PRICE", "HOURLY", "RETAINER"], index=["FIXED_PRICE", "HOURLY", "RETAINER"].index(sel_proj["billing_model"]) if sel_proj["billing_model"] in ["FIXED_PRICE", "HOURLY", "RETAINER"] else 0)
                    e_prate = st.number_input("Hourly Rate", min_value=0.0, value=float(sel_proj["hourly_rate"]) if pd.notnull(sel_proj["hourly_rate"]) else 0.0)
                    e_pbudget = st.number_input("Total Budget", min_value=0.0, value=float(sel_proj["total_budget"]) if pd.notnull(sel_proj["total_budget"]) else 0.0)
                    e_pstatus = st.selectbox("Status", ["PROPOSED", "ACTIVE", "ON_HOLD", "COMPLETED", "CANCELLED"], index=["PROPOSED", "ACTIVE", "ON_HOLD", "COMPLETED", "CANCELLED"].index(sel_proj["status"]) if sel_proj["status"] in ["PROPOSED", "ACTIVE", "ON_HOLD", "COMPLETED", "CANCELLED"] else 1)
                    e_pdesc = st.text_area("Description", value=sel_proj["description"] or "")
                    e_psubmit = st.form_submit_button("💾 Save Project Changes")
                    
                    if e_psubmit:
                        res = execute_query(
                            "UPDATE projects SET project_name=%s, billing_model=%s, hourly_rate=%s, total_budget=%s, status=%s, description=%s WHERE project_id=%s",
                            (e_pname, e_pmodel, e_prate, e_pbudget, e_pstatus, e_pdesc or None, sel_proj["project_id"])
                        )
                        if res is not None:
                            st.success("Project updated successfully!")
                            st.cache_data.clear()
                            st.rerun()
                        else:
                            st.error("Failed to update project.")

        with crud_tab3:
            all_projects = fetch_data("SELECT project_id, project_name FROM projects ORDER BY project_id DESC")
            if all_projects:
                proj_df = pd.DataFrame(all_projects)
                proj_df["display"] = proj_df.apply(lambda r: f"#{r['project_id']} - {r['project_name']}", axis=1)
                del_p_disp = st.selectbox("Select Project to Delete", proj_df["display"], key="del_p_select")
                del_proj_id = proj_df[proj_df["display"] == del_p_disp].iloc[0]["project_id"]
                
                if st.button("🗑️ Delete Project", type="primary"):
                    res = execute_query("DELETE FROM projects WHERE project_id = %s", (del_proj_id,))
                    if res is not None:
                        st.success(f"Project #{del_proj_id} deleted successfully!")
                        st.cache_data.clear()
                        st.rerun()
                    else:
                        st.error("Failed to delete project (Record may have linked milestones/time entries).")


# ==============================================================================
# PAGE 5: PAYMENTS
# ==============================================================================
elif page == "💳 Payments":
    st.title("💳 Payment Transactions & Settlement")
    payments_df = engine.tables.get("payments", pd.DataFrame())
    invoices_df = engine.tables.get("invoices", pd.DataFrame())

    if not payments_df.empty:
        total_paid = payments_df["amount_paid"].sum()
        pending_total = invoices_df[invoices_df["status"].isin(["ISSUED", "OVERDUE", "PARTIALLY_PAID"])]["total_amount"].sum() if not invoices_df.empty else 0.0

        m1, m2, m3 = st.columns(3)
        m1.metric("Settled Cash Flow", f"₹{total_paid:,.2f}")
        m2.metric("Total Transactions", len(payments_df))
        m3.metric("Pending Receivables", f"₹{pending_total:,.2f}")

        st.divider()
        c1, c2 = st.columns([2, 1])
        search_query = c1.text_input("🔍 Search Transaction Ref / Notes", "")
        method_filter = c2.selectbox("Payment Method", ["ALL"] + list(payments_df["payment_method"].unique()))

        filtered = payments_df.copy()
        if search_query:
            filtered = filtered[
                filtered["transaction_reference"].astype(str).str.contains(search_query, case=False, na=False) |
                filtered["notes"].astype(str).str.contains(search_query, case=False, na=False)
            ]
        if method_filter != "ALL":
            filtered = filtered[filtered["payment_method"] == method_filter]

        st.dataframe(filtered, use_container_width=True)

    # Interactive Management Section (CRUD)
    with st.expander("⚙️ Manage Payments & Log Settlements", expanded=False):
        crud_tab1, crud_tab2 = st.tabs(["➕ Record New Payment", "🗑️ Delete Payment"])
        
        invoices_list = fetch_data("SELECT invoice_id, invoice_number, total_amount, status FROM invoices WHERE status IN ('ISSUED', 'PARTIALLY_PAID', 'OVERDUE') ORDER BY invoice_id DESC")
        inv_options = {f"Invoice #{i['invoice_number']} (ID: {i['invoice_id']}) - Total: ₹{i['total_amount']:,.2f} [{i['status']}]": i['invoice_id'] for i in invoices_list} if invoices_list else {}

        with crud_tab1:
            with st.form("add_payment_form"):
                pay_inv_disp = st.selectbox("Select Issued Invoice", list(inv_options.keys()) if inv_options else ["No Issued Invoices Found"])
                pay_date = st.date_input("Payment Date")
                pay_amount = st.number_input("Amount Paid", min_value=0.01, value=1000.0, step=100.0)
                pay_method = st.selectbox("Payment Method", ["BANK_TRANSFER", "CREDIT_CARD", "PAYPAL", "STRIPE", "CASH"])
                pay_ref = st.text_input("Transaction Reference / Cheque No.", placeholder="TXN-998877")
                pay_notes = st.text_area("Payment Notes")
                pay_submit = st.form_submit_button("💳 Record Settlement")
                
                if pay_submit:
                    if not inv_options:
                        st.error("No valid issued invoice selected.")
                    else:
                        sel_inv_id = inv_options[pay_inv_disp]
                        res = execute_query(
                            "INSERT INTO payments (invoice_id, payment_date, amount_paid, payment_method, transaction_reference, notes) VALUES (%s, %s, %s, %s, %s, %s)",
                            (sel_inv_id, str(pay_date), pay_amount, pay_method, pay_ref or None, pay_notes or None)
                        )
                        if res:
                            execute_query("UPDATE invoices SET status = 'PAID' WHERE invoice_id = %s", (sel_inv_id,))
                            st.success(f"Payment of ₹{pay_amount:,.2f} recorded successfully for Invoice #{sel_inv_id}!")
                            st.cache_data.clear()
                            st.rerun()
                        else:
                            st.error("Failed to record payment.")

        with crud_tab2:
            payments_list = fetch_data("SELECT payment_id, invoice_id, amount_paid, payment_method, payment_date FROM payments ORDER BY payment_id DESC")
            if payments_list:
                pay_df = pd.DataFrame(payments_list)
                pay_df["display"] = pay_df.apply(lambda r: f"Payment #{r['payment_id']} (Invoice #{r['invoice_id']}) - ₹{r['amount_paid']:,.2f} on {r['payment_date']}", axis=1)
                del_pay_disp = st.selectbox("Select Payment to Delete", pay_df["display"], key="del_pay_select")
                del_pay_id = pay_df[pay_df["display"] == del_pay_disp].iloc[0]["payment_id"]
                
                if st.button("🗑️ Delete Payment Record", type="primary"):
                    res = execute_query("DELETE FROM payments WHERE payment_id = %s", (del_pay_id,))
                    if res is not None:
                        st.success(f"Payment #{del_pay_id} deleted successfully!")
                        st.cache_data.clear()
                        st.rerun()
                    else:
                        st.error("Failed to delete payment record.")


# ==============================================================================
# PAGE 6: EXPENSES
# ==============================================================================
elif page == "💸 Expenses":
    st.title("💸 Business Expense Management")
    expense_df = engine.get_expense_analytics()
    expenses_raw = engine.tables.get("expenses", pd.DataFrame())

    if not expenses_raw.empty:
        m1, m2, m3 = st.columns(3)
        m1.metric("Total Operating Expenses", f"₹{expenses_raw['amount'].sum():,.2f}")
        m2.metric("Transactions Count", len(expenses_raw))
        m3.metric("Average Transaction Value", f"₹{expenses_raw['amount'].mean():,.2f}")

        st.divider()
        st.subheader("Category Expenditure Table")
        st.dataframe(expense_df, use_container_width=True)

    # Interactive Management Section (CRUD)
    with st.expander("⚙️ Manage Expenses (Add / Edit / Delete)", expanded=False):
        crud_tab1, crud_tab2 = st.tabs(["➕ Add Expense", "🗑️ Delete Expense"])
        
        categories_list = fetch_data("SELECT category_id, category_name FROM expense_categories ORDER BY category_name")
        cat_options = {c['category_name']: c['category_id'] for c in categories_list} if categories_list else {}

        projects_list = fetch_data("SELECT project_id, project_name FROM projects ORDER BY project_name")
        proj_options = {"None (General Overhead)": None}
        if projects_list:
            for p in projects_list:
                proj_options[f"#{p['project_id']} - {p['project_name']}"] = p['project_id']

        with crud_tab1:
            with st.form("add_expense_form"):
                exp_cat = st.selectbox("Category", list(cat_options.keys()) if cat_options else ["Software"])
                exp_proj = st.selectbox("Linked Project (Optional)", list(proj_options.keys()))
                exp_date = st.date_input("Expense Date")
                exp_amount = st.number_input("Amount (₹)", min_value=0.01, value=500.0, step=50.0)
                exp_curr = st.selectbox("Currency Code", ["INR"])
                exp_desc = st.text_area("Description / Item Purchased")
                exp_ref = st.text_input("Receipt / Invoice Ref")
                exp_submit = st.form_submit_button("➕ Record Expense")
                
                if exp_submit:
                    if not cat_options:
                        st.error("Expense Category is required.")
                    else:
                        sel_cat_id = cat_options[exp_cat]
                        sel_proj_id = proj_options[exp_proj]
                        res = execute_query(
                            "INSERT INTO expenses (category_id, project_id, expense_date, amount, currency_code, description, receipt_ref) VALUES (%s, %s, %s, %s, %s, %s, %s)",
                            (sel_cat_id, sel_proj_id, str(exp_date), exp_amount, exp_curr, exp_desc or None, exp_ref or None)
                        )
                        if res:
                            st.success(f"Expense of ₹{exp_amount:,.2f} recorded successfully under '{exp_cat}'!")
                            st.cache_data.clear()
                            st.rerun()
                        else:
                            st.error("Failed to record expense.")

        with crud_tab2:
            all_expenses = fetch_data("SELECT expense_id, expense_date, amount, description FROM expenses ORDER BY expense_id DESC")
            if all_expenses:
                exp_df = pd.DataFrame(all_expenses)
                exp_df["display"] = exp_df.apply(lambda r: f"Expense #{r['expense_id']} - ₹{r['amount']:,.2f} ({r['expense_date']}) - {r['description'] or 'No desc'}", axis=1)
                del_exp_disp = st.selectbox("Select Expense to Delete", exp_df["display"], key="del_exp_select")
                del_exp_id = exp_df[exp_df["display"] == del_exp_disp].iloc[0]["expense_id"]
                
                if st.button("🗑️ Delete Expense", type="primary"):
                    res = execute_query("DELETE FROM expenses WHERE expense_id = %s", (del_exp_id,))
                    if res is not None:
                        st.success(f"Expense #{del_exp_id} deleted successfully!")
                        st.cache_data.clear()
                        st.rerun()
                    else:
                        st.error("Failed to delete expense record.")



# ==============================================================================
# PAGE 7: ANALYTICS & EXAMINER VIVA MODE
# ==============================================================================
elif page == "📊 Analytics":
    st.title("📊 Financial & Operational Analytics")
    tab1, tab2, tab3, tab4 = st.tabs(["💰 Project Net Profit & EHR", "🏆 Client Profitability Matrix", "⭐ Rating Scores", "🎓 Examiner Viva Demonstration"])

    with tab1:
        st.dataframe(engine.get_profitability_analytics(), use_container_width=True)
    with tab2:
        st.dataframe(engine.get_client_analytics(), use_container_width=True)
    with tab3:
        st.dataframe(engine.get_rating_analytics(), use_container_width=True)
    with tab4:
        st.subheader("🎓 Live Examiner Inspection Panel")
        st.markdown("Direct SQL Database Views & Procedure Logic Demonstration:")
        
        v_choice = st.selectbox("Inspect Database View", [
            "v_invoice_summary", "v_client_analytics", "v_freelancer_utilization", 
            "v_project_budget_variance", "v_monthly_financials"
        ])
        view_data = fetch_data(f"SELECT * FROM {v_choice} LIMIT 20")
        if view_data:
            st.dataframe(pd.DataFrame(view_data), use_container_width=True)


# ==============================================================================
# PAGE 8: REPORTS & DOWNLOADS
# ==============================================================================
elif page == "📄 Reports":
    st.title("📄 Executive Reports & Data Exporter")
    st.caption("Export summary statements in CSV, Markdown, or Text format")

    invoices_df = engine.tables.get("invoices", pd.DataFrame())
    expenses_df = engine.tables.get("expenses", pd.DataFrame())

    paid_rev = invoices_df[invoices_df["status"] == "PAID"]["total_amount"].sum() if not invoices_df.empty else 0.0
    total_exp = expenses_df["amount"].sum() if not expenses_df.empty else 0.0
    net_inc = paid_rev - total_exp
    margin = (net_inc / paid_rev * 100) if paid_rev > 0 else 0.0

    report_text = f"""================================================================================
                    FCMS ANALYTICS EXECUTIVE INCOME STATEMENT
================================================================================
Gross Revenue Collected    : ₹{paid_rev:,.2f}
Total Operating Expenses   : ₹{total_exp:,.2f}
--------------------------------------------------------------------------------
Net Operating Income       : ₹{net_inc:,.2f}
Net Operating Profit Margin: {margin:.2f}%
================================================================================
"""

    st.code(report_text, language="text")

    col1, col2 = st.columns(2)
    with col1:
        st.download_button(
            label="📥 Download Text Report (.txt)",
            data=report_text,
            file_name="FCMS_Income_Statement.txt",
            mime="text/plain",
            use_container_width=True
        )
    with col2:
        csv_data = invoices_df.to_csv(index=False) if not invoices_df.empty else ""
        st.download_button(
            label="📥 Export Invoices Data (.csv)",
            data=csv_data,
            file_name="FCMS_Invoices_Export.csv",
            mime="text/csv",
            use_container_width=True
        )


# ==============================================================================
# PAGE 9: SETTINGS
# ==============================================================================
elif page == "⚙ Settings":
    st.title("⚙ System Settings & Database Diagnostics")
    st.caption("Manage connection parameters, database state, and system cache")

    st.subheader("Database Connection Status")
    conn = get_connection()
    if conn and conn.is_connected():
        st.success("✅ **MySQL Database Connection Active & Healthy (Local Production)**")
        st.json({
            "Host": "localhost",
            "Port": 3306,
            "Database": "freelance_management",
            "Server Version": conn.get_server_info()
        })
    else:
        st.info("ℹ️ **Cloud Demonstration Mode: High-Performance In-Memory Engine Active**")
        st.caption("All 10 pages, Pandas analytics, Matplotlib charts, and interactive CRUD forms are fully operational.")

    st.divider()

    st.subheader("Cache Management")
    if st.button("🔄 Clear System Cache & Reload Data", use_container_width=True):
        st.cache_data.clear()
        st.success("System data cache cleared successfully!")
        st.rerun()


# ==============================================================================
# PAGE 10: ABOUT
# ==============================================================================
elif page == "ℹ About":
    st.title("ℹ About FCMS Analytics")
    st.markdown("""
    ### **Freelance & Client Management System with Freelancer Income & Client Analytics (FCMS Analytics)**
    **System Version:** 2.5 (Enterprise Edition)  
    **Developer:** **Ayush Rai**  
    
    ---

    #### 🛠️ **Technology Stack**
    - **Database Backend:** MySQL 8.0 (18 Tables in 3NF, 5 Views, Triggers, Stored Procedures, 40 BI Queries)
    - **Data Analytics Engine:** Python 3.10+, Pandas, NumPy
    - **Visualization Suite:** Matplotlib Custom Dark Theme (10 PNG Visualizations)
    - **Web Frontend Application:** Streamlit Light Theme Layout with Interactive Search & Filters
    
    ---
    
    #### 🎓 **Academic & Portfolio Context**
    Designed for Senior Software Architecture Portfolios, College Final Projects, and Executive Demonstrations.
    """)

# Footer Branding
st.markdown("<div class='footer'>© 2026 Freelance & Client Management System | Developed by <b>Ayush Rai</b></div>", unsafe_allow_html=True)
