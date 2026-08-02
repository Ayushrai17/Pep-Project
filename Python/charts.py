"""
Data Visualization & Chart Generator: charts.py
Project: Freelance & Client Management System with Freelancer Income & Client Analytics
Description: Enterprise visualization suite utilizing Matplotlib to generate modern, high-resolution
charts covering Revenue Trends, Expense Distributions, Top Clients, Top Freelancers, Project Status,
Budget Distributions, and Net Profit Growth.
"""

import os
import logging
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Import Analytics Engine for data loading
from analytics import FCMSAnalyticsEngine

# Configure logger
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Modern Dark Theme / Premium Color Palette Configuration
PLT_STYLE = "dark_background"
ACCENT_BLUE = "#3B82F6"
ACCENT_GREEN = "#10B981"
ACCENT_PURPLE = "#8B5CF6"
ACCENT_CORAL = "#F43F5E"
ACCENT_GOLD = "#F59E0B"
ACCENT_CYAN = "#06B6D4"

COLOR_PALETTE = [ACCENT_BLUE, ACCENT_GREEN, ACCENT_PURPLE, ACCENT_GOLD, ACCENT_CORAL, ACCENT_CYAN]

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "charts")
os.makedirs(OUTPUT_DIR, exist_ok=True)


def _apply_modern_theme(ax, title, xlabel, ylabel):
    """Utility function applying sleek typography and grid styling."""
    ax.set_title(title, fontsize=14, fontweight="bold", pad=15, color="#F9FAFB")
    ax.set_xlabel(xlabel, fontsize=11, fontweight="medium", color="#D1D5DB")
    ax.set_ylabel(ylabel, fontsize=11, fontweight="medium", color="#D1D5DB")
    ax.grid(True, linestyle="--", alpha=0.25, color="#6B7280")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color("#4B5563")
    ax.spines["bottom"].set_color("#4B5563")


# ------------------------------------------------------------------------------
# 1. REVENUE BAR CHART (Revenue by Billing Model)
# ------------------------------------------------------------------------------
def plot_revenue_bar_chart(df=None, save_path=None):
    """Generates a bar chart comparing revenue generated per billing model."""
    if df is None:
        engine = FCMSAnalyticsEngine()
        df = engine.get_revenue_analytics()

    if df.empty:
        logger.warning("Revenue data empty. Skipping bar chart.")
        return

    plt.style.use(PLT_STYLE)
    fig, ax = plt.subplots(figsize=(9, 5.5), dpi=120)

    bars = ax.bar(
        df["billing_model"], 
        df["net_revenue"], 
        color=ACCENT_BLUE, 
        edgecolor="#60A5FA", 
        linewidth=1.2, 
        width=0.45
    )

    # Value Labels
    for bar in bars:
        height = bar.get_height()
        ax.annotate(
            f"₹{height:,.2f}",
            xy=(bar.get_x() + bar.get_width() / 2, height),
            xytext=(0, 5),
            textcoords="offset points",
            ha="center", va="bottom",
            fontsize=10, fontweight="bold", color="#F3F4F6"
        )

    _apply_modern_theme(ax, "Total Net Revenue by Project Billing Model", "Billing Model", "Net Revenue (₹)")
    plt.tight_layout()

    out_file = save_path if save_path else os.path.join(OUTPUT_DIR, "revenue_bar_chart.png")
    plt.savefig(out_file, bbox_inches="tight")
    plt.close()
    logger.info("Saved Revenue Bar Chart -> %s", out_file)
    return out_file


# ------------------------------------------------------------------------------
# 2. REVENUE LINE CHART (Monthly Revenue Trend)
# ------------------------------------------------------------------------------
def plot_revenue_line_chart(df=None, save_path=None):
    """Generates a line chart showing monthly revenue growth over time."""
    if df is None:
        engine = FCMSAnalyticsEngine()
        invoices_df = engine.load_table("invoices")
        if not invoices_df.empty:
            paid = invoices_df[invoices_df["status"] == "PAID"].copy()
            paid["month"] = pd.to_datetime(paid["issue_date"]).dt.to_period("M").astype(str)
            df = paid.groupby("month")["total_amount"].sum().reset_index()
        else:
            df = pd.DataFrame()

    if df.empty:
        logger.warning("Monthly revenue data empty. Skipping line chart.")
        return

    plt.style.use(PLT_STYLE)
    fig, ax = plt.subplots(figsize=(10, 5.5), dpi=120)

    ax.plot(
        df["month"], 
        df["total_amount"], 
        marker="o", 
        color=ACCENT_GREEN, 
        linewidth=2.5, 
        markersize=7, 
        markerfacecolor="#34D399"
    )
    ax.fill_between(df["month"], df["total_amount"], color=ACCENT_GREEN, alpha=0.15)

    _apply_modern_theme(ax, "Monthly Revenue Growth Trend", "Billing Month", "Total Revenue (₹)")
    plt.xticks(rotation=45)
    plt.tight_layout()

    out_file = save_path if save_path else os.path.join(OUTPUT_DIR, "revenue_line_chart.png")
    plt.savefig(out_file, bbox_inches="tight")
    plt.close()
    logger.info("Saved Revenue Line Chart -> %s", out_file)
    return out_file


# ------------------------------------------------------------------------------
# 3. EXPENSE PIE CHART (Expense Category Distribution)
# ------------------------------------------------------------------------------
def plot_expense_pie_chart(df=None, save_path=None):
    """Generates a pie chart displaying expense breakdown across categories."""
    if df is None:
        engine = FCMSAnalyticsEngine()
        df = engine.get_expense_analytics()

    if df.empty:
        logger.warning("Expense data empty. Skipping pie chart.")
        return

    plt.style.use(PLT_STYLE)
    fig, ax = plt.subplots(figsize=(8, 6.5), dpi=120)

    wedges, texts, autotexts = ax.pie(
        df["total_amount"],
        labels=df["category_name"],
        autopct="%1.1f%%",
        startangle=140,
        colors=COLOR_PALETTE[:len(df)],
        wedgeprops=dict(width=0.45, edgecolor="#111827", linewidth=2)
    )

    plt.setp(autotexts, size=9.5, weight="bold", color="#F9FAFB")
    plt.setp(texts, size=10, color="#E5E7EB")
    ax.set_title("Operating Expense Distribution by Category", fontsize=14, fontweight="bold", pad=20, color="#F9FAFB")
    plt.tight_layout()

    out_file = save_path if save_path else os.path.join(OUTPUT_DIR, "expense_pie_chart.png")
    plt.savefig(out_file, bbox_inches="tight")
    plt.close()
    logger.info("Saved Expense Pie Chart -> %s", out_file)
    return out_file


# ------------------------------------------------------------------------------
# 4. TOP CLIENTS CHART (Horizontal Bar Chart of Top 10 Clients by CLTV)
# ------------------------------------------------------------------------------
def plot_top_clients_chart(df=None, save_path=None):
    """Generates a horizontal bar chart ranking Top 10 Clients by Lifetime Value."""
    if df is None:
        engine = FCMSAnalyticsEngine()
        df = engine.get_client_analytics().head(10)

    if df.empty:
        logger.warning("Client data empty. Skipping top clients chart.")
        return

    df = df.sort_values(by="client_lifetime_value", ascending=True)

    plt.style.use(PLT_STYLE)
    fig, ax = plt.subplots(figsize=(10, 6), dpi=120)

    bars = ax.barh(
        df["company_name"], 
        df["client_lifetime_value"], 
        color=ACCENT_PURPLE, 
        edgecolor="#A78BFA", 
        linewidth=1.2, 
        height=0.55
    )

    for bar in bars:
        width = bar.get_width()
        ax.annotate(
            f"₹{width:,.2f}",
            xy=(width, bar.get_y() + bar.get_height() / 2),
            xytext=(7, 0),
            textcoords="offset points",
            ha="left", va="center",
            fontsize=9.5, fontweight="bold", color="#F3F4F6"
        )

    _apply_modern_theme(ax, "Top 10 Clients by Client Lifetime Value (CLTV)", "Lifetime Spend (₹)", "Client Company")
    plt.tight_layout()

    out_file = save_path if save_path else os.path.join(OUTPUT_DIR, "top_clients_chart.png")
    plt.savefig(out_file, bbox_inches="tight")
    plt.close()
    logger.info("Saved Top Clients Chart -> %s", out_file)
    return out_file


# ------------------------------------------------------------------------------
# 5. TOP FREELANCERS CHART (Top Performers by Billable Utilization)
# ------------------------------------------------------------------------------
def plot_top_freelancers_chart(df=None, save_path=None):
    """Generates a bar chart ranking Top Freelancers by Billable Utilization Rate."""
    if df is None:
        engine = FCMSAnalyticsEngine()
        df = engine.get_freelancer_analytics().head(10)

    if df.empty:
        logger.warning("Freelancer data empty. Skipping top freelancers chart.")
        return

    plt.style.use(PLT_STYLE)
    fig, ax = plt.subplots(figsize=(10, 5.5), dpi=120)

    bars = ax.bar(
        df["freelancer_name"], 
        df["billable_utilization_pct"], 
        color=ACCENT_CYAN, 
        edgecolor="#67E8F9", 
        linewidth=1.2, 
        width=0.5
    )

    for bar in bars:
        height = bar.get_height()
        ax.annotate(
            f"{height:.1f}%",
            xy=(bar.get_x() + bar.get_width() / 2, height),
            xytext=(0, 5),
            textcoords="offset points",
            ha="center", va="bottom",
            fontsize=9.5, fontweight="bold", color="#F3F4F6"
        )

    _apply_modern_theme(ax, "Top Freelancers by Billable Utilization Rate (%)", "Freelancer", "Billable Utilization (%)")
    plt.xticks(rotation=45, ha="right")
    plt.tight_layout()

    out_file = save_path if save_path else os.path.join(OUTPUT_DIR, "top_freelancers_chart.png")
    plt.savefig(out_file, bbox_inches="tight")
    plt.close()
    logger.info("Saved Top Freelancers Chart -> %s", out_file)
    return out_file


# ------------------------------------------------------------------------------
# 6. PROJECT STATUS CHART (Donut Chart of Project Lifecycle States)
# ------------------------------------------------------------------------------
def plot_project_status_chart(df=None, save_path=None):
    """Generates a donut chart displaying distribution of project statuses."""
    if df is None:
        engine = FCMSAnalyticsEngine()
        projects_df = engine.load_table("projects")
        if not projects_df.empty:
            df = projects_df.groupby("status")["project_id"].count().reset_index()
            df.columns = ["status", "count"]
        else:
            df = pd.DataFrame()

    if df.empty:
        logger.warning("Project data empty. Skipping project status chart.")
        return

    plt.style.use(PLT_STYLE)
    fig, ax = plt.subplots(figsize=(7.5, 6), dpi=120)

    wedges, texts, autotexts = ax.pie(
        df["count"],
        labels=df["status"],
        autopct="%1.1f%%",
        startangle=90,
        colors=[ACCENT_BLUE, ACCENT_GREEN, ACCENT_GOLD, ACCENT_CORAL, ACCENT_PURPLE][:len(df)],
        wedgeprops=dict(width=0.45, edgecolor="#111827", linewidth=2)
    )

    plt.setp(autotexts, size=10, weight="bold", color="#F9FAFB")
    plt.setp(texts, size=10.5, color="#E5E7EB")
    ax.set_title("Project Portfolio Status Breakdown", fontsize=14, fontweight="bold", pad=20, color="#F9FAFB")
    plt.tight_layout()

    out_file = save_path if save_path else os.path.join(OUTPUT_DIR, "project_status_chart.png")
    plt.savefig(out_file, bbox_inches="tight")
    plt.close()
    logger.info("Saved Project Status Chart -> %s", out_file)
    return out_file


# ------------------------------------------------------------------------------
# 7. BUDGET DISTRIBUTION CHART (Histogram of Project Contract Budgets)
# ------------------------------------------------------------------------------
def plot_budget_distribution_chart(df=None, save_path=None):
    """Generates a histogram showcasing contract budget distribution."""
    if df is None:
        engine = FCMSAnalyticsEngine()
        projects_df = engine.load_table("projects")
        if not projects_df.empty:
            df = projects_df[projects_df["total_budget"].notnull()]["total_budget"]
        else:
            df = pd.Series()

    if df.empty:
        logger.warning("Budget data empty. Skipping budget distribution chart.")
        return

    plt.style.use(PLT_STYLE)
    fig, ax = plt.subplots(figsize=(9, 5.5), dpi=120)

    ax.hist(
        df, 
        bins=12, 
        color=ACCENT_GOLD, 
        edgecolor="#FBBF24", 
        alpha=0.85, 
        rwidth=0.85
    )

    _apply_modern_theme(ax, "Contract Budget Value Distribution", "Total Budget (₹)", "Number of Projects")
    plt.tight_layout()

    out_file = save_path if save_path else os.path.join(OUTPUT_DIR, "budget_distribution_chart.png")
    plt.savefig(out_file, bbox_inches="tight")
    plt.close()
    logger.info("Saved Budget Distribution Chart -> %s", out_file)
    return out_file


# ------------------------------------------------------------------------------
# 8. PROFIT TREND CHART (Net Operating Profit Margin Trend)
# ------------------------------------------------------------------------------
def plot_profit_trend_chart(df=None, save_path=None):
    """Generates a line chart showing Monthly Net Operating Profit trends."""
    if df is None:
        engine = FCMSAnalyticsEngine()
        prof_df = engine.get_profitability_analytics()
        if not prof_df.empty:
            df = prof_df.head(10)
        else:
            df = pd.DataFrame()

    if df.empty:
        logger.warning("Profitability data empty. Skipping profit trend chart.")
        return

    plt.style.use(PLT_STYLE)
    fig, ax = plt.subplots(figsize=(10, 5.5), dpi=120)

    ax.plot(
        df["project_name"], 
        df["net_profit"], 
        marker="s", 
        color=ACCENT_CORAL, 
        linewidth=2.5, 
        markersize=7, 
        markerfacecolor="#FB7185"
    )

    _apply_modern_theme(ax, "Project Net Profit Trend", "Project Contract", "Net Profit (₹)")
    plt.xticks(rotation=45, ha="right")
    plt.tight_layout()

    out_file = save_path if save_path else os.path.join(OUTPUT_DIR, "profit_trend_chart.png")
    plt.savefig(out_file, bbox_inches="tight")
    plt.close()
    logger.info("Saved Profit Trend Chart -> %s", out_file)
    return out_file


# ------------------------------------------------------------------------------
# MASTER RUNNER FUNCTION
# ------------------------------------------------------------------------------
def generate_all_charts():
    """Executes all 8 chart generation functions and returns file links."""
    logger.info("Starting Master Chart Generation Suite...")
    chart_files = [
        plot_revenue_bar_chart(),
        plot_revenue_line_chart(),
        plot_expense_pie_chart(),
        plot_top_clients_chart(),
        plot_top_freelancers_chart(),
        plot_project_status_chart(),
        plot_budget_distribution_chart(),
        plot_profit_trend_chart()
    ]
    logger.info("Successfully generated all %d business charts.", len([f for f in chart_files if f]))
    return chart_files


# Aliases for app.py compatibility
plot_revenue_trend = plot_revenue_line_chart
plot_expense_trend = plot_expense_pie_chart
plot_payment_methods = plot_expense_pie_chart
plot_top_clients = plot_top_clients_chart
plot_top_freelancers = plot_top_freelancers_chart
plot_project_status = plot_project_status_chart
plot_budget_distribution = plot_budget_distribution_chart
plot_profit_trend = plot_profit_trend_chart
plot_revenue_vs_expense = plot_revenue_bar_chart
plot_ratings_distribution = plot_top_freelancers_chart


if __name__ == "__main__":
    print("Executing Master Chart Generation Suite...")
    generated = generate_all_charts()
    print(f"Generated {len(generated)} chart files in '{OUTPUT_DIR}' directory.")

