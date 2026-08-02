"""
Business Analytics & Intelligence Engine: analytics.py
Project: Freelance & Client Management System with Freelancer Income & Client Analytics
Description: Modular Data Analytics suite utilizing Pandas to extract SQL tables, execute
financial & operational data processing, and generate structured DataFrames covering Revenue,
Expenses, Net Profit, Client LTV, Project Efficiency, Freelancer Utilization, and Rating Matrix.
"""

import logging
import decimal
import pandas as pd
import numpy as np
from db import fetch_data, get_connection

# Configure logger
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)


class FCMSAnalyticsEngine:
    """
    Enterprise Data Analytics Engine for FCMS Analytics platform.
    Extracts raw relational tables into Pandas DataFrames and executes
    multi-dimensional financial, client, project, and freelancer performance analytics.
    """

    def __init__(self):
        self.tables = {}

    def load_table(self, table_name):
        """
        Loads a relational database table into a Pandas DataFrame.
        
        :param table_name: SQL table name string.
        :return: pandas.DataFrame
        """
        query = f"SELECT * FROM {table_name}"
        records = fetch_data(query)
        if records:
            df = pd.DataFrame(records)
            for col in df.columns:
                df[col] = df[col].apply(lambda x: float(x) if isinstance(x, decimal.Decimal) else x)
            logger.info("Successfully loaded table '%s' (%d records).", table_name, len(df))
            return df
        else:
            logger.warning("Table '%s' is empty or unavailable.", table_name)
            return pd.DataFrame()

    def load_all_tables(self):
        """
        Extracts all core database tables into memory.
        """
        target_tables = [
            "clients", "projects", "milestones", "tasks", 
            "time_entries", "invoices", "invoice_items", 
            "payments", "expenses", "expense_categories", 
            "users", "project_reviews", "skills", "freelancer_skills"
        ]
        for t in target_tables:
            self.tables[t] = self.load_table(t)

    # --------------------------------------------------------------------------
    # 1. REVENUE ANALYTICS REPORT
    # --------------------------------------------------------------------------
    def get_revenue_analytics(self) -> pd.DataFrame:
        """
        Generates Revenue Summary Report.
        Computes Total Revenue, Revenue by Billing Model, and Monthly Trends.
        
        :return: pandas.DataFrame
        """
        invoices_df = self.tables.get("invoices", self.load_table("invoices"))
        projects_df = self.tables.get("projects", self.load_table("projects"))

        if invoices_df.empty:
            return pd.DataFrame()

        # Filter paid & issued invoices
        paid_invoices = invoices_df[invoices_df["status"].isin(["PAID", "PARTIALLY_PAID", "ISSUED"])].copy()
        
        # Merge with Projects to analyze revenue by billing model
        if not projects_df.empty:
            merged = paid_invoices.merge(projects_df[["project_id", "billing_model"]], on="project_id", how="left")
        else:
            merged = paid_invoices
            merged["billing_model"] = "UNKNOWN"

        merged["issue_month"] = pd.to_datetime(merged["issue_date"]).dt.to_period("M").astype(str)

        revenue_report = merged.groupby("billing_model").agg(
            total_invoices=("invoice_id", "count"),
            gross_subtotal=("subtotal", "sum"),
            total_tax_collected=("tax_amount", "sum"),
            total_discounts=("discount_amount", "sum"),
            total_late_fees=("late_fee_amount", "sum"),
            net_revenue=("total_amount", "sum"),
            avg_invoice_value=("total_amount", "mean")
        ).reset_index()

        revenue_report["net_revenue"] = revenue_report["net_revenue"].round(2)
        revenue_report["avg_invoice_value"] = revenue_report["avg_invoice_value"].round(2)

        return revenue_report

    # --------------------------------------------------------------------------
    # 2. EXPENSE ANALYTICS REPORT
    # --------------------------------------------------------------------------
    def get_expense_analytics(self) -> pd.DataFrame:
        """
        Generates Expense Breakdown & Tax Deductibility Report.
        
        :return: pandas.DataFrame
        """
        expenses_df = self.tables.get("expenses", self.load_table("expenses"))
        categories_df = self.tables.get("expense_categories", self.load_table("expense_categories"))

        if expenses_df.empty:
            return pd.DataFrame()

        if not categories_df.empty:
            merged = expenses_df.merge(categories_df, on="category_id", how="left")
        else:
            merged = expenses_df
            merged["category_name"] = "General"
            merged["is_tax_deductible"] = True

        expense_report = merged.groupby(["category_name", "is_tax_deductible"]).agg(
            transaction_count=("expense_id", "count"),
            total_amount=("amount", "sum"),
            avg_transaction_amount=("amount", "mean")
        ).reset_index()

        expense_report["total_amount"] = expense_report["total_amount"].round(2)
        expense_report["avg_transaction_amount"] = expense_report["avg_transaction_amount"].round(2)

        return expense_report.sort_values(by="total_amount", ascending=False)

    # --------------------------------------------------------------------------
    # 3. PROFITABILITY ANALYTICS REPORT (Net Profit & EHR)
    # --------------------------------------------------------------------------
    def get_profitability_analytics(self) -> pd.DataFrame:
        """
        Generates Project Net Profit Margin & Effective Hourly Rate (EHR) Report.
        
        :return: pandas.DataFrame
        """
        projects_df = self.tables.get("projects", self.load_table("projects"))
        invoices_df = self.tables.get("invoices", self.load_table("invoices"))
        expenses_df = self.tables.get("expenses", self.load_table("expenses"))
        time_df = self.tables.get("time_entries", self.load_table("time_entries"))
        tasks_df = self.tables.get("tasks", self.load_table("tasks"))

        if projects_df.empty:
            return pd.DataFrame()

        # Revenue per project
        paid_inv = invoices_df[invoices_df["status"] == "PAID"] if not invoices_df.empty else pd.DataFrame()
        proj_rev = paid_inv.groupby("project_id")["total_amount"].sum().reset_index() if not paid_inv.empty else pd.DataFrame(columns=["project_id", "total_amount"])
        proj_rev.rename(columns={"total_amount": "gross_revenue"}, inplace=True)

        # Direct expenses per project
        proj_exp = expenses_df.groupby("project_id")["amount"].sum().reset_index() if not expenses_df.empty else pd.DataFrame(columns=["project_id", "amount"])
        proj_exp.rename(columns={"amount": "direct_expenses"}, inplace=True)

        # Hours logged per project
        if not time_df.empty and not tasks_df.empty:
            time_task = time_df.merge(tasks_df[["task_id", "project_id"]], on="task_id", how="left")
            proj_hours = time_task.groupby("project_id")["hours_logged"].sum().reset_index()
            proj_hours.rename(columns={"hours_logged": "total_hours_worked"}, inplace=True)
        else:
            proj_hours = pd.DataFrame(columns=["project_id", "total_hours_worked"])

        # Merge metrics into project dataframe
        df = projects_df[["project_id", "project_name", "billing_model", "total_budget"]].copy()
        df = df.merge(proj_rev, on="project_id", how="left").fillna({"gross_revenue": 0.0})
        df = df.merge(proj_exp, on="project_id", how="left").fillna({"direct_expenses": 0.0})
        df = df.merge(proj_hours, on="project_id", how="left").fillna({"total_hours_worked": 0.0})

        # Net Profit & Profit Margin %
        df["net_profit"] = df["gross_revenue"] - df["direct_expenses"]
        df["profit_margin_pct"] = np.where(
            df["gross_revenue"] > 0,
            (df["net_profit"] / df["gross_revenue"]) * 100,
            0.0
        )
        
        # Effective Hourly Rate (EHR) = Net Profit / Total Hours
        df["effective_hourly_rate"] = np.where(
            df["total_hours_worked"] > 0,
            df["net_profit"] / df["total_hours_worked"],
            0.0
        )

        df["net_profit"] = df["net_profit"].round(2)
        df["profit_margin_pct"] = df["profit_margin_pct"].round(2)
        df["effective_hourly_rate"] = df["effective_hourly_rate"].round(2)

        return df.sort_values(by="net_profit", ascending=False)

    # --------------------------------------------------------------------------
    # 4. CLIENT CRM & LIFETIME VALUE (CLTV) REPORT
    # --------------------------------------------------------------------------
    def get_client_analytics(self) -> pd.DataFrame:
        """
        Generates Client Lifetime Value (CLTV) & Repeat Client Analysis Report.
        
        :return: pandas.DataFrame
        """
        clients_df = self.tables.get("clients", self.load_table("clients"))
        projects_df = self.tables.get("projects", self.load_table("projects"))
        invoices_df = self.tables.get("invoices", self.load_table("invoices"))

        if clients_df.empty:
            return pd.DataFrame()

        # Project count per client
        proj_count = projects_df.groupby("client_id")["project_id"].count().reset_index() if not projects_df.empty else pd.DataFrame(columns=["client_id", "project_id"])
        proj_count.rename(columns={"project_id": "total_projects_commissioned"}, inplace=True)

        # Total revenue per client
        paid_inv = invoices_df[invoices_df["status"] == "PAID"] if not invoices_df.empty else pd.DataFrame()
        client_rev = paid_inv.groupby("client_id")["total_amount"].sum().reset_index() if not paid_inv.empty else pd.DataFrame(columns=["client_id", "total_amount"])
        client_rev.rename(columns={"total_amount": "client_lifetime_value"}, inplace=True)

        merged = clients_df[["client_id", "company_name", "currency_code", "status", "payment_terms_days"]].copy()
        merged["currency_code"] = "INR"
        merged = merged.merge(proj_count, on="client_id", how="left").fillna({"total_projects_commissioned": 0})
        merged = merged.merge(client_rev, on="client_id", how="left").fillna({"client_lifetime_value": 0.0})

        merged["is_repeat_client"] = merged["total_projects_commissioned"] > 1
        merged["client_lifetime_value"] = merged["client_lifetime_value"].round(2)

        return merged.sort_values(by="client_lifetime_value", ascending=False)

    # --------------------------------------------------------------------------
    # 5. PROJECT BUDGET & EFFICIENCY REPORT
    # --------------------------------------------------------------------------
    def get_project_analytics(self) -> pd.DataFrame:
        """
        Generates Project Budget vs Actual Hours Variance Report.
        
        :return: pandas.DataFrame
        """
        projects_df = self.tables.get("projects", self.load_table("projects"))
        tasks_df = self.tables.get("tasks", self.load_table("tasks"))
        time_df = self.tables.get("time_entries", self.load_table("time_entries"))

        if projects_df.empty:
            return pd.DataFrame()

        # Estimated hours per project
        task_est = tasks_df.groupby("project_id")["estimated_hours"].sum().reset_index() if not tasks_df.empty else pd.DataFrame(columns=["project_id", "estimated_hours"])
        task_est.rename(columns={"estimated_hours": "total_estimated_hours"}, inplace=True)

        # Actual hours per project
        if not time_df.empty and not tasks_df.empty:
            time_task = time_df.merge(tasks_df[["task_id", "project_id"]], on="task_id", how="left")
            time_act = time_task.groupby("project_id")["hours_logged"].sum().reset_index()
            time_act.rename(columns={"hours_logged": "total_actual_hours"}, inplace=True)
        else:
            time_act = pd.DataFrame(columns=["project_id", "total_actual_hours"])

        df = projects_df[["project_id", "project_name", "billing_model", "status", "start_date", "target_end_date"]].copy()
        df = df.merge(task_est, on="project_id", how="left").fillna({"total_estimated_hours": 0.0})
        df = df.merge(time_act, on="project_id", how="left").fillna({"total_actual_hours": 0.0})

        df["hour_variance"] = df["total_actual_hours"] - df["total_estimated_hours"]
        df["budget_health"] = np.where(df["hour_variance"] > 0, "OVER_BUDGET", "WITHIN_BUDGET")

        return df

    # --------------------------------------------------------------------------
    # 6. FREELANCER PERFORMANCE & UTILIZATION REPORT
    # --------------------------------------------------------------------------
    def get_freelancer_analytics(self) -> pd.DataFrame:
        """
        Generates Freelancer Work Hours & Billable Utilization Rate Report.
        
        :return: pandas.DataFrame
        """
        users_df = self.tables.get("users", self.load_table("users"))
        time_df = self.tables.get("time_entries", self.load_table("time_entries"))

        if users_df.empty or time_df.empty:
            return pd.DataFrame()

        # Billable vs Non-Billable Hours
        time_summary = time_df.groupby("user_id").agg(
            total_logged_hours=("hours_logged", "sum"),
            billable_hours=("hours_logged", lambda x: x[time_df.loc[x.index, "is_billable"] == True].sum()),
            non_billable_hours=("hours_logged", lambda x: x[time_df.loc[x.index, "is_billable"] == False].sum()),
            total_sessions=("time_entry_id", "count")
        ).reset_index()

        time_summary["billable_utilization_pct"] = np.where(
            time_summary["total_logged_hours"] > 0,
            (time_summary["billable_hours"] / time_summary["total_logged_hours"]) * 100,
            0.0
        )

        users_df["freelancer_name"] = users_df["first_name"] + " " + users_df["last_name"]
        merged = time_summary.merge(users_df[["user_id", "freelancer_name", "email", "status"]], on="user_id", how="inner")

        merged["billable_utilization_pct"] = merged["billable_utilization_pct"].round(2)

        return merged.sort_values(by="billable_utilization_pct", ascending=False)

    # --------------------------------------------------------------------------
    # 7. RATING & CLIENT FEEDBACK REPORT
    # --------------------------------------------------------------------------
    def get_rating_analytics(self) -> pd.DataFrame:
        """
        Generates Freelancer Client Rating & Feedback Report.
        
        :return: pandas.DataFrame
        """
        reviews_df = self.tables.get("project_reviews", self.load_table("project_reviews"))
        users_df = self.tables.get("users", self.load_table("users"))

        if reviews_df.empty:
            return pd.DataFrame()

        reviews_df = reviews_df.copy()
        reviews_df["rating"] = reviews_df["rating"].astype(float)

        reviews_summary = reviews_df.groupby("freelancer_id").agg(
            total_reviews=("review_id", "count"),
            avg_rating=("rating", "mean"),
            min_rating=("rating", "min"),
            max_rating=("rating", "max")
        ).reset_index()

        if not users_df.empty:
            users_df["freelancer_name"] = users_df["first_name"] + " " + users_df["last_name"]
            merged = reviews_summary.merge(users_df[["user_id", "freelancer_name"]], left_on="freelancer_id", right_on="user_id", how="left")
        else:
            merged = reviews_summary
            merged["freelancer_name"] = merged["freelancer_id"].astype(str)

        merged["avg_rating"] = merged["avg_rating"].round(2)

        return merged.sort_values(by="avg_rating", ascending=False)


if __name__ == "__main__":
    print("Testing analytics.py Engine...")
    engine = FCMSAnalyticsEngine()
    engine.load_all_tables()

    print("\n--- REVENUE ANALYTICS SUMMARY ---")
    print(engine.get_revenue_analytics().head())

    print("\n--- EXPENSE ANALYTICS SUMMARY ---")
    print(engine.get_expense_analytics().head())

    print("\n--- PROFITABILITY & EHR ANALYTICS ---")
    print(engine.get_profitability_analytics().head())

    print("\n--- CLIENT LIFETIME VALUE (CLTV) ---")
    print(engine.get_client_analytics().head())
