"""
Financial Report Generator Module: Python/reports.py
Project: Freelance & Client Management System with Freelancer Income & Client Analytics
Description: Automated text, markdown, and summary report generator exporting audit-ready
financial statements, aging accounts receivable statements, and project margin performance reports.
"""

import os
import sys
import logging
import pandas as pd

# Adjust path if loaded from subfolder
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from analytics import FCMSAnalyticsEngine

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

REPORT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "report"))
os.makedirs(REPORT_DIR, exist_ok=True)


class FCMSReportGenerator:
    """Generates structured financial, client, and project performance reports."""

    def __init__(self):
        self.engine = FCMSAnalyticsEngine()
        self.engine.load_all_tables()

    def generate_income_statement(self) -> str:
        """Generates Executive Income Statement Report."""
        invoices_df = self.engine.tables.get("invoices", pd.DataFrame())
        expenses_df = self.engine.tables.get("expenses", pd.DataFrame())

        paid_rev = invoices_df[invoices_df["status"] == "PAID"]["total_amount"].sum() if not invoices_df.empty else 0.0
        total_exp = expenses_df["amount"].sum() if not expenses_df.empty else 0.0
        net_inc = paid_rev - total_exp
        margin = (net_inc / paid_rev * 100) if paid_rev > 0 else 0.0

        report = f"""================================================================================
                    FCMS ANALYTICS EXECUTIVE INCOME STATEMENT
================================================================================
Gross Revenue Collected    : ${paid_rev:,.2f}
Total Operating Expenses   : ${total_exp:,.2f}
--------------------------------------------------------------------------------
Net Operating Income       : ${net_inc:,.2f}
Net Operating Profit Margin: {margin:.2f}%
================================================================================
"""
        return report

    def generate_aging_receivables_report(self) -> str:
        """Generates Accounts Receivable Aging Statement."""
        invoices_df = self.engine.tables.get("invoices", pd.DataFrame())
        if invoices_df.empty:
            return "No invoice data found."

        pending = invoices_df[invoices_df["status"].isin(["ISSUED", "OVERDUE", "PARTIALLY_PAID"])].copy()
        if pending.empty:
            return "No pending accounts receivable outstanding."

        pending["days_overdue"] = (pd.to_datetime("2026-07-29") - pd.to_datetime(pending["due_date"])).dt.days

        def get_bucket(days):
            if days <= 30: return "0 - 30 Days (Current)"
            elif days <= 60: return "31 - 60 Days (Late)"
            elif days <= 90: return "61 - 90 Days (Very Late)"
            else: return "90+ Days (High Risk)"

        pending["aging_bucket"] = pending["days_overdue"].apply(get_bucket)
        summary = pending.groupby("aging_bucket").agg(
            invoice_count=("invoice_id", "count"),
            total_pending_amount=("total_amount", "sum")
        ).reset_index()

        return summary.to_string(index=False)

    def export_summary_reports(self):
        """Exports all report statements to text and markdown files in 'report/' directory."""
        income_text = self.generate_income_statement()
        aging_text = self.generate_aging_receivables_report()

        out_path = os.path.join(REPORT_DIR, "financial_summary_statement.txt")
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(income_text + "\n\nACCOUNTS RECEIVABLE AGING STATEMENT:\n" + aging_text)

        logger.info("Exported summary financial report to -> %s", out_path)
        return out_path


if __name__ == "__main__":
    gen = FCMSReportGenerator()
    gen.export_summary_reports()
