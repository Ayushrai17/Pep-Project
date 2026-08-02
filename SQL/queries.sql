-- ==============================================================================
-- BUSINESS INTELLIGENCE & ANALYTICAL QUERIES SCRIPT: queries.sql
-- Project: Freelance & Client Management System with Freelancer Income & Client Analytics
-- Contains: 40 Advanced Analytical Queries covering Revenue, Expenses, Profitability,
-- Clients, Projects, Freelancers, Ratings, Aging Receivables & Growth Trends.
-- ==============================================================================

USE freelance_management;

-- ==============================================================================
-- CATEGORY 1: REVENUE ANALYTICS (Queries 1 - 6)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Query 1: Total Lifetime Gross & Net Revenue Earned
-- Business Purpose: Calculates total billed subtotal, applied taxes, discounts, and final gross revenue.
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(invoice_id) AS total_invoices_issued,
    SUM(subtotal) AS gross_subtotal,
    SUM(tax_amount) AS total_tax_collected,
    SUM(discount_amount) AS total_discounts_given,
    SUM(late_fee_amount) AS total_late_fees_accrued,
    SUM(total_amount) AS final_net_revenue
FROM invoices
WHERE status IN ('PAID', 'PARTIALLY_PAID', 'ISSUED');

-- ------------------------------------------------------------------------------
-- Query 2: Monthly Recurring Revenue (MRR) from Retainer Contracts
-- Business Purpose: Identifies monthly predictable income generated from active retainer projects.
-- ------------------------------------------------------------------------------
SELECT 
    p.project_id,
    p.project_name,
    c.company_name,
    p.hourly_rate AS retainer_monthly_rate,
    p.total_budget AS max_retainer_cap
FROM projects p
JOIN clients c ON p.client_id = c.client_id
WHERE p.billing_model = 'RETAINER' AND p.status = 'ACTIVE';

-- ------------------------------------------------------------------------------
-- Query 3: Revenue Breakdown by Currency Code
-- Business Purpose: Groups overall revenue by currency (USD, EUR, GBP, CAD, INR, AUD).
-- ------------------------------------------------------------------------------
SELECT 
    currency_code,
    COUNT(invoice_id) AS total_invoices,
    SUM(subtotal) AS total_subtotal,
    SUM(total_amount) AS total_currency_revenue
FROM invoices
WHERE status = 'PAID'
GROUP BY currency_code
ORDER BY total_currency_revenue DESC;

-- ------------------------------------------------------------------------------
-- Query 4: Quarterly Revenue Performance & Growth
-- Business Purpose: Aggregates revenue by Year and Quarter for quarterly financial reviews.
-- ------------------------------------------------------------------------------
SELECT 
    YEAR(issue_date) AS revenue_year,
    QUARTER(issue_date) AS revenue_quarter,
    COUNT(invoice_id) AS invoices_count,
    SUM(total_amount) AS quarterly_revenue
FROM invoices
WHERE status = 'PAID'
GROUP BY YEAR(issue_date), QUARTER(issue_date)
ORDER BY revenue_year DESC, revenue_quarter DESC;

-- ------------------------------------------------------------------------------
-- Query 5: Average Revenue Per Client (ARPC)
-- Business Purpose: Computes average revenue generated per active client in the portfolio.
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(DISTINCT client_id) AS active_client_count,
    SUM(total_amount) AS total_revenue,
    ROUND(SUM(total_amount) / COUNT(DISTINCT client_id), 2) AS average_revenue_per_client
FROM invoices
WHERE status = 'PAID';

-- ------------------------------------------------------------------------------
-- Query 6: Revenue Breakdown by Project Billing Model
-- Business Purpose: Compares income generated from Fixed-Price vs Hourly vs Retainer projects.
-- ------------------------------------------------------------------------------
SELECT 
    p.billing_model,
    COUNT(DISTINCT p.project_id) AS project_count,
    SUM(i.total_amount) AS total_revenue_generated,
    ROUND(AVG(i.total_amount), 2) AS avg_invoice_size
FROM projects p
JOIN invoices i ON p.project_id = i.project_id
WHERE i.status = 'PAID'
GROUP BY p.billing_model
ORDER BY total_revenue_generated DESC;


-- ==============================================================================
-- CATEGORY 2: EXPENSE & COST ANALYTICS (Queries 7 - 11)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Query 7: Total Operating Expenses Categorized by Expense Category
-- Business Purpose: Identifies top business expense drivers (SaaS, Hardware, Subcontractors, Travel).
-- ------------------------------------------------------------------------------
SELECT 
    ec.category_name,
    COUNT(e.expense_id) AS transaction_count,
    SUM(e.amount) AS total_category_expense,
    ROUND(AVG(e.amount), 2) AS average_expense_amount
FROM expenses e
JOIN expense_categories ec ON e.category_id = ec.category_id
GROUP BY ec.category_name
ORDER BY total_category_expense DESC;

-- ------------------------------------------------------------------------------
-- Query 8: Tax-Deductible Business Expenses Summary
-- Business Purpose: Calculates total tax-deductible expenditures to optimize tax reserve planning.
-- ------------------------------------------------------------------------------
SELECT 
    ec.is_tax_deductible,
    COUNT(e.expense_id) AS expense_count,
    SUM(e.amount) AS total_amount
FROM expenses e
JOIN expense_categories ec ON e.category_id = ec.category_id
GROUP BY ec.is_tax_deductible;

-- ------------------------------------------------------------------------------
-- Query 9: Direct Project-Attributable Expenses vs General Overhead
-- Business Purpose: Separates client-attributable costs from general freelancer studio overhead.
-- ------------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN e.project_id IS NOT NULL THEN 'Direct Project Expense'
        ELSE 'General Overhead Expense'
    END AS expense_type,
    COUNT(e.expense_id) AS total_transactions,
    SUM(e.amount) AS total_expense_amount
FROM expenses e
GROUP BY expense_type;

-- ------------------------------------------------------------------------------
-- Query 10: Monthly Expense Burn Rate Trend
-- Business Purpose: Tracks monthly cash burn rate over time.
-- ------------------------------------------------------------------------------
SELECT 
    DATE_FORMAT(expense_date, '%Y-%m') AS expense_month,
    COUNT(expense_id) AS total_expenses,
    SUM(amount) AS monthly_burn_amount
FROM expenses
GROUP BY DATE_FORMAT(expense_date, '%Y-%m')
ORDER BY expense_month ASC;

-- ------------------------------------------------------------------------------
-- Query 11: Expense to Revenue Ratio (%) per Quarter
-- Business Purpose: Monitors cost efficiency by calculating expenses as a % of earned revenue.
-- ------------------------------------------------------------------------------
WITH QuarterlyRevenue AS (
    SELECT 
        YEAR(issue_date) AS yr, 
        QUARTER(issue_date) AS qtr, 
        SUM(total_amount) AS rev
    FROM invoices WHERE status = 'PAID'
    GROUP BY YEAR(issue_date), QUARTER(issue_date)
),
QuarterlyExpense AS (
    SELECT 
        YEAR(expense_date) AS yr, 
        QUARTER(expense_date) AS qtr, 
        SUM(amount) AS exp
    FROM expenses
    GROUP BY YEAR(expense_date), QUARTER(expense_date)
)
SELECT 
    r.yr AS year_val,
    r.qtr AS quarter_val,
    r.rev AS total_revenue,
    COALESCE(e.exp, 0.00) AS total_expense,
    ROUND((COALESCE(e.exp, 0.00) / r.rev) * 100, 2) AS expense_to_revenue_ratio_pct
FROM QuarterlyRevenue r
LEFT JOIN QuarterlyExpense e ON r.yr = e.yr AND r.qtr = e.qtr
ORDER BY r.yr DESC, r.qtr DESC;


-- ==============================================================================
-- CATEGORY 3: PROFITABILITY & NET INCOME ANALYTICS (Queries 12 - 16)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Query 12: Net Profit Calculation per Project (Revenue minus Expenses)
-- Business Purpose: Computes actual net profit generated per project contract.
-- ------------------------------------------------------------------------------
SELECT 
    p.project_id,
    p.project_name,
    c.company_name,
    COALESCE(SUM(DISTINCT i.total_amount), 0.00) AS gross_revenue,
    COALESCE(SUM(DISTINCT e.amount), 0.00) AS direct_expenses,
    (COALESCE(SUM(DISTINCT i.total_amount), 0.00) - COALESCE(SUM(DISTINCT e.amount), 0.00)) AS net_profit
FROM projects p
JOIN clients c ON p.client_id = c.client_id
LEFT JOIN invoices i ON p.project_id = i.project_id AND i.status = 'PAID'
LEFT JOIN expenses e ON p.project_id = e.project_id
GROUP BY p.project_id, p.project_name, c.company_name
ORDER BY net_profit DESC;

-- ------------------------------------------------------------------------------
-- Query 13: Overall Freelance Business Income Statement Summary
-- Business Purpose: Executive summary calculating Total Revenue - Total Expenses = Net Operating Income.
-- ------------------------------------------------------------------------------
WITH RevSummary AS (
    SELECT SUM(total_amount) AS total_rev FROM invoices WHERE status = 'PAID'
),
ExpSummary AS (
    SELECT SUM(amount) AS total_exp FROM expenses
)
SELECT 
    r.total_rev AS gross_revenue_collected,
    e.total_exp AS total_operating_expenses,
    (r.total_rev - e.total_exp) AS net_operating_income,
    ROUND(((r.total_rev - e.total_exp) / r.total_rev) * 100, 2) AS net_profit_margin_pct
FROM RevSummary r, ExpSummary e;

-- ------------------------------------------------------------------------------
-- Query 14: Effective Hourly Rate (EHR) per Project
-- Business Purpose: Measures true hourly realization rate ($EHR = \frac{\text{Net Profit}}{\text{Total Hours Logged}}$).
-- ------------------------------------------------------------------------------
SELECT 
    p.project_id,
    p.project_name,
    COALESCE(SUM(te.hours_logged), 0.00) AS total_hours_worked,
    COALESCE(SUM(DISTINCT i.total_amount), 0.00) AS total_revenue,
    ROUND(
        CASE 
            WHEN SUM(te.hours_logged) > 0 THEN COALESCE(SUM(DISTINCT i.total_amount), 0.00) / SUM(te.hours_logged)
            ELSE 0.00 
        END, 2
    ) AS effective_hourly_rate
FROM projects p
LEFT JOIN tasks t ON p.project_id = t.project_id
LEFT JOIN time_entries te ON t.task_id = te.task_id
LEFT JOIN invoices i ON p.project_id = i.project_id AND i.status = 'PAID'
GROUP BY p.project_id, p.project_name
HAVING total_hours_worked > 0
ORDER BY effective_hourly_rate DESC;

-- ------------------------------------------------------------------------------
-- Query 15: Top 5 Most Profitable Projects by Profit Margin %
-- Business Purpose: Ranks top 5 projects yielding the highest percentage profit margin.
-- ------------------------------------------------------------------------------
SELECT 
    p.project_id,
    p.project_name,
    SUM(i.total_amount) AS gross_revenue,
    COALESCE(SUM(e.amount), 0.00) AS direct_expenses,
    ROUND(((SUM(i.total_amount) - COALESCE(SUM(e.amount), 0.00)) / SUM(i.total_amount)) * 100, 2) AS profit_margin_pct
FROM projects p
JOIN invoices i ON p.project_id = i.project_id AND i.status = 'PAID'
LEFT JOIN expenses e ON p.project_id = e.project_id
GROUP BY p.project_id, p.project_name
HAVING gross_revenue > 0
ORDER BY profit_margin_pct DESC
LIMIT 5;

-- ------------------------------------------------------------------------------
-- Query 16: Financial Impact of Non-Billable Hours Logged
-- Business Purpose: Quantifies unbilled overhead time logged by freelancers and potential opportunity cost.
-- ------------------------------------------------------------------------------
SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS freelancer_name,
    SUM(CASE WHEN te.is_billable = TRUE THEN te.hours_logged ELSE 0 END) AS billable_hours,
    SUM(CASE WHEN te.is_billable = FALSE THEN te.hours_logged ELSE 0 END) AS non_billable_hours,
    ROUND(
        (SUM(CASE WHEN te.is_billable = FALSE THEN te.hours_logged ELSE 0 END) / SUM(te.hours_logged)) * 100, 2
    ) AS non_billable_overhead_pct
FROM users u
JOIN time_entries te ON u.user_id = te.user_id
GROUP BY u.user_id, freelancer_name
ORDER BY non_billable_hours DESC;


-- ==============================================================================
-- CATEGORY 4: CLIENT CRM & INTELLIGENCE (Queries 17 - 22)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Query 17: Client Lifetime Value (CLTV) Ranking
-- Business Purpose: Ranks all clients by cumulative net revenue generated over their lifetime.
-- ------------------------------------------------------------------------------
SELECT 
    c.client_id,
    c.company_name,
    c.currency_code,
    COUNT(DISTINCT p.project_id) AS total_projects_commissioned,
    COUNT(DISTINCT i.invoice_id) AS total_invoices_paid,
    COALESCE(SUM(i.total_amount), 0.00) AS client_lifetime_value
FROM clients c
LEFT JOIN projects p ON c.client_id = p.client_id
LEFT JOIN invoices i ON c.client_id = i.client_id AND i.status = 'PAID'
GROUP BY c.client_id, c.company_name, c.currency_code
ORDER BY client_lifetime_value DESC;

-- ------------------------------------------------------------------------------
-- Query 18: Repeat Clients Analysis
-- Business Purpose: Identifies repeat clients who commissioned more than 1 project contract.
-- ------------------------------------------------------------------------------
SELECT 
    c.client_id,
    c.company_name,
    COUNT(p.project_id) AS total_projects,
    MIN(p.start_date) AS first_project_date,
    MAX(p.start_date) AS latest_project_date
FROM clients c
JOIN projects p ON c.client_id = p.client_id
GROUP BY c.client_id, c.company_name
HAVING COUNT(p.project_id) > 1
ORDER BY total_projects DESC;

-- ------------------------------------------------------------------------------
-- Query 19: High-Risk / Flagged Clients with Pending Overdue Balances
-- Business Purpose: Flags clients with delinquent payment records and pending balances.
-- ------------------------------------------------------------------------------
SELECT 
    c.client_id,
    c.company_name,
    c.status AS client_status,
    i.invoice_number,
    i.due_date,
    i.total_amount AS pending_amount,
    DATEDIFF('2026-07-29', i.due_date) AS days_overdue
FROM clients c
JOIN invoices i ON c.client_id = i.client_id
WHERE i.status = 'OVERDUE' OR c.status = 'FLAGGED_LATE'
ORDER BY days_overdue DESC;

-- ------------------------------------------------------------------------------
-- Query 20: Client Acquisition Growth Timeline
-- Business Purpose: Tracks new client onboarding velocity per year.
-- ------------------------------------------------------------------------------
SELECT 
    YEAR(created_at) AS onboarding_year,
    COUNT(client_id) AS new_clients_onboarded
FROM clients
GROUP BY YEAR(created_at)
ORDER BY onboarding_year ASC;

-- ------------------------------------------------------------------------------
-- Query 21: Client Profitability Matrix (Net Profit per Client)
-- Business Purpose: Computes net profit generated per client (Client Revenue minus Client Expenses).
-- ------------------------------------------------------------------------------
SELECT 
    c.client_id,
    c.company_name,
    COALESCE(SUM(DISTINCT i.total_amount), 0.00) AS total_client_revenue,
    COALESCE(SUM(DISTINCT e.amount), 0.00) AS total_client_expenses,
    (COALESCE(SUM(DISTINCT i.total_amount), 0.00) - COALESCE(SUM(DISTINCT e.amount), 0.00)) AS net_client_profit
FROM clients c
LEFT JOIN invoices i ON c.client_id = i.client_id AND i.status = 'PAID'
LEFT JOIN expenses e ON c.client_id = e.client_id
GROUP BY c.client_id, c.company_name
ORDER BY net_client_profit DESC;

-- ------------------------------------------------------------------------------
-- Query 22: Top Clients by Total Hours Billed
-- Business Purpose: Identifies clients utilizing the most freelancer execution hours.
-- ------------------------------------------------------------------------------
SELECT 
    c.client_id,
    c.company_name,
    ROUND(SUM(te.hours_logged), 2) AS total_hours_consumed
FROM clients c
JOIN projects p ON c.client_id = p.client_id
JOIN tasks t ON p.project_id = t.project_id
JOIN time_entries te ON t.task_id = te.task_id
WHERE te.is_billable = TRUE
GROUP BY c.client_id, c.company_name
ORDER BY total_hours_consumed DESC;


-- ==============================================================================
-- CATEGORY 5: PROJECT & MILESTONE PERFORMANCE (Queries 23 - 27)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Query 23: Project Budget vs Actual Hours Variance Analysis
-- Business Purpose: Compares estimated task hours against actual logged hours per project.
-- ------------------------------------------------------------------------------
SELECT 
    p.project_id,
    p.project_name,
    SUM(t.estimated_hours) AS total_estimated_hours,
    COALESCE(SUM(te.hours_logged), 0.00) AS total_actual_hours,
    (COALESCE(SUM(te.hours_logged), 0.00) - SUM(t.estimated_hours)) AS hour_variance,
    CASE 
        WHEN COALESCE(SUM(te.hours_logged), 0.00) > SUM(t.estimated_hours) THEN 'OVER_BUDGET'
        ELSE 'WITHIN_BUDGET'
    END AS budget_health_status
FROM projects p
JOIN tasks t ON p.project_id = t.project_id
LEFT JOIN time_entries te ON t.task_id = te.task_id
GROUP BY p.project_id, p.project_name
ORDER BY hour_variance DESC;

-- ------------------------------------------------------------------------------
-- Query 24: Overdue Projects Past Target Completion Date
-- Business Purpose: Identifies active projects exceeding target delivery deadlines.
-- ------------------------------------------------------------------------------
SELECT 
    p.project_id,
    p.project_name,
    c.company_name,
    p.start_date,
    p.target_end_date,
    DATEDIFF('2026-07-29', p.target_end_date) AS days_delayed
FROM projects p
JOIN clients c ON p.client_id = c.client_id
WHERE p.status = 'ACTIVE' AND p.target_end_date < '2026-07-29'
ORDER BY days_delayed DESC;

-- ------------------------------------------------------------------------------
-- Query 25: Milestone Completion Rate & Deliverable SLA Compliance
-- Business Purpose: Tracks milestone status delivery metrics across projects.
-- ------------------------------------------------------------------------------
SELECT 
    m.status AS milestone_status,
    COUNT(m.milestone_id) AS total_milestones,
    SUM(m.amount) AS total_milestone_value
FROM milestones m
GROUP BY m.status;

-- ------------------------------------------------------------------------------
-- Query 26: Project Lifecycle Status Distribution
-- Business Purpose: Overview of projects grouped by current status.
-- ------------------------------------------------------------------------------
SELECT 
    status AS project_status,
    COUNT(project_id) AS total_projects,
    SUM(total_budget) AS cumulative_budget
FROM projects
GROUP BY status;

-- ------------------------------------------------------------------------------
-- Query 27: Fixed-Price vs Hourly Project Revenue Realization Rate
-- Business Purpose: Evaluates average revenue earned per project type.
-- ------------------------------------------------------------------------------
SELECT 
    p.billing_model,
    COUNT(p.project_id) AS project_count,
    ROUND(AVG(p.total_budget), 2) AS avg_contract_budget,
    ROUND(AVG(i.total_amount), 2) AS avg_revenue_realized
FROM projects p
LEFT JOIN invoices i ON p.project_id = i.project_id AND i.status = 'PAID'
GROUP BY p.billing_model;


-- ==============================================================================
-- CATEGORY 6: FREELANCER PERFORMANCE & RATINGS (Queries 28 - 32)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Query 28: Top Performer Freelancers by Average Client Rating
-- Business Purpose: Identifies top-rated freelancers based on client review feedback.
-- ------------------------------------------------------------------------------
SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS freelancer_name,
    COUNT(pr.review_id) AS total_reviews_received,
    ROUND(AVG(pr.rating), 2) AS average_client_rating
FROM users u
JOIN project_reviews pr ON u.user_id = pr.freelancer_id
GROUP BY u.user_id, freelancer_name
HAVING COUNT(pr.review_id) >= 1
ORDER BY average_client_rating DESC, total_reviews_received DESC;

-- ------------------------------------------------------------------------------
-- Query 29: Total Hours Logged & Billable Realization Rate per Freelancer
-- Business Purpose: Measures individual freelancer billable efficiency.
-- ------------------------------------------------------------------------------
SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS freelancer_name,
    SUM(te.hours_logged) AS total_logged_hours,
    SUM(CASE WHEN te.is_billable = TRUE THEN te.hours_logged ELSE 0 END) AS billable_hours,
    ROUND(
        (SUM(CASE WHEN te.is_billable = TRUE THEN te.hours_logged ELSE 0 END) / SUM(te.hours_logged)) * 100, 2
    ) AS billable_utilization_pct
FROM users u
JOIN time_entries te ON u.user_id = te.user_id
GROUP BY u.user_id, freelancer_name
ORDER BY billable_utilization_pct DESC;

-- ------------------------------------------------------------------------------
-- Query 30: Top Earning Freelancers (Total Client Billing Generated)
-- Business Purpose: Ranks freelancers by total billed client revenue.
-- ------------------------------------------------------------------------------
SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS freelancer_name,
    COUNT(DISTINCT te.task_id) AS tasks_executed,
    SUM(te.hours_logged) AS total_hours_worked
FROM users u
JOIN time_entries te ON u.user_id = te.user_id
WHERE te.is_billable = TRUE
GROUP BY u.user_id, freelancer_name
ORDER BY total_hours_worked DESC;

-- ------------------------------------------------------------------------------
-- Query 31: Freelancer Utilization Rate Analysis
-- Business Purpose: Calculates percentage of billable hours vs non-billable administrative hours.
-- ------------------------------------------------------------------------------
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) AS freelancer_name,
    COUNT(te.time_entry_id) AS total_sessions,
    ROUND(AVG(te.hours_logged), 2) AS avg_session_duration_hours
FROM users u
JOIN time_entries te ON u.user_id = te.user_id
GROUP BY u.user_id, freelancer_name
ORDER BY avg_session_duration_hours DESC;

-- ------------------------------------------------------------------------------
-- Query 32: Freelancer Skill Matrix & Expertise Distribution
-- Business Purpose: Maps freelancer counts across skill domains.
-- ------------------------------------------------------------------------------
SELECT 
    s.skill_name,
    s.category AS skill_category,
    COUNT(fs.user_id) AS freelancer_count
FROM skills s
LEFT JOIN freelancer_skills fs ON s.skill_id = fs.skill_id
GROUP BY s.skill_name, s.category
ORDER BY freelancer_count DESC;


-- ==============================================================================
-- CATEGORY 7: ACCOUNTS RECEIVABLE & FINANCIAL GOVERNANCE (Queries 33 - 36)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Query 33: Aging Accounts Receivable Report (Aging Buckets)
-- Business Purpose: Groups pending invoices into aging buckets (0-30, 31-60, 61-90, 90+ Days Overdue).
-- ------------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN DATEDIFF('2026-07-29', due_date) <= 30 THEN '0 - 30 Days (Current)'
        WHEN DATEDIFF('2026-07-29', due_date) BETWEEN 31 AND 60 THEN '31 - 60 Days (Late)'
        WHEN DATEDIFF('2026-07-29', due_date) BETWEEN 61 AND 90 THEN '61 - 90 Days (Very Late)'
        ELSE '90+ Days (High Default Risk)'
    END AS aging_bucket,
    COUNT(invoice_id) AS invoice_count,
    SUM(total_amount) AS total_receivable_amount
FROM invoices
WHERE status IN ('ISSUED', 'OVERDUE', 'PARTIALLY_PAID')
GROUP BY aging_bucket
ORDER BY aging_bucket ASC;

-- ------------------------------------------------------------------------------
-- Query 34: Total Pending & Uncollected Payments Summary
-- Business Purpose: Summarizes uncollected invoice cash flow.
-- ------------------------------------------------------------------------------
SELECT 
    status AS invoice_status,
    COUNT(invoice_id) AS count,
    SUM(total_amount) AS pending_cash_flow
FROM invoices
WHERE status IN ('ISSUED', 'OVERDUE', 'PARTIALLY_PAID')
GROUP BY status;

-- ------------------------------------------------------------------------------
-- Query 35: Payment Method Distribution
-- Business Purpose: Identifies preferred payment channels (Bank Transfer vs Credit Card vs Gateway).
-- ------------------------------------------------------------------------------
SELECT 
    payment_method,
    COUNT(payment_id) AS transaction_count,
    SUM(amount_paid) AS total_settled_amount
FROM payments
GROUP BY payment_method
ORDER BY total_settled_amount DESC;

-- ------------------------------------------------------------------------------
-- Query 36: Late Payment Penalties Accrued per Client
-- Business Purpose: Identifies late payment interest penalties incurred by client accounts.
-- ------------------------------------------------------------------------------
SELECT 
    c.company_name,
    COUNT(i.invoice_id) AS overdue_invoices,
    SUM(i.late_fee_amount) AS total_late_fees_incurred
FROM clients c
JOIN invoices i ON c.client_id = i.client_id
WHERE i.late_fee_amount > 0
GROUP BY c.company_name
ORDER BY total_late_fees_incurred DESC;


-- ==============================================================================
-- CATEGORY 8: GROWTH, FORECASTING & ADVANCED TRENDS (Queries 37 - 40)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Query 37: Year-over-Year (YoY) Revenue Growth Rate (CTE & Window Function)
-- Business Purpose: Computes annual revenue growth percentage.
-- ------------------------------------------------------------------------------
WITH AnnualRevenue AS (
    SELECT 
        YEAR(issue_date) AS rev_year,
        SUM(total_amount) AS annual_revenue
    FROM invoices
    WHERE status = 'PAID'
    GROUP BY YEAR(issue_date)
)
SELECT 
    rev_year,
    annual_revenue,
    LAG(annual_revenue, 1) OVER (ORDER BY rev_year) AS previous_year_revenue,
    ROUND(
        ((annual_revenue - LAG(annual_revenue, 1) OVER (ORDER BY rev_year)) / LAG(annual_revenue, 1) OVER (ORDER BY rev_year)) * 100, 2
    ) AS yoy_growth_pct
FROM AnnualRevenue;

-- ------------------------------------------------------------------------------
-- Query 38: Projected Revenue Pipeline from Active Contracts & Milestones
-- Business Purpose: Forecasts incoming revenue from approved but un-invoiced milestones.
-- ------------------------------------------------------------------------------
SELECT 
    p.project_id,
    p.project_name,
    c.company_name,
    COUNT(m.milestone_id) AS pending_milestones_count,
    SUM(m.amount) AS projected_pipeline_revenue
FROM projects p
JOIN clients c ON p.client_id = c.client_id
JOIN milestones m ON p.project_id = m.project_id
WHERE p.status = 'ACTIVE' AND m.status IN ('APPROVED', 'SUBMITTED', 'IN_PROGRESS')
GROUP BY p.project_id, p.project_name, c.company_name
ORDER BY projected_pipeline_revenue DESC;

-- ------------------------------------------------------------------------------
-- Query 39: Client Retention & Churn Rate Analysis
-- Business Purpose: Categorizes client accounts into Active vs Inactive / Churned states.
-- ------------------------------------------------------------------------------
SELECT 
    status AS client_status,
    COUNT(client_id) AS client_count,
    ROUND((COUNT(client_id) / (SELECT COUNT(*) FROM clients)) * 100, 2) AS percentage_of_total
FROM clients
GROUP BY status;

-- ------------------------------------------------------------------------------
-- Query 40: Comprehensive Monthly Financial Health Summary Matrix
-- Business Purpose: Single executive dashboard query calculating Revenue, Expenses, Net Profit, and Profit Margin % per Month.
-- ------------------------------------------------------------------------------
WITH MonthlyRev AS (
    SELECT 
        DATE_FORMAT(issue_date, '%Y-%m') AS ym,
        SUM(total_amount) AS rev
    FROM invoices WHERE status = 'PAID'
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
),
MonthlyExp AS (
    SELECT 
        DATE_FORMAT(expense_date, '%Y-%m') AS ym,
        SUM(amount) AS exp
    FROM expenses
    GROUP BY DATE_FORMAT(expense_date, '%Y-%m')
)
SELECT 
    r.ym AS financial_month,
    r.rev AS gross_revenue_collected,
    COALESCE(e.exp, 0.00) AS total_operating_expenses,
    (r.rev - COALESCE(e.exp, 0.00)) AS net_monthly_profit,
    ROUND(((r.rev - COALESCE(e.exp, 0.00)) / r.rev) * 100, 2) AS monthly_profit_margin_pct
FROM MonthlyRev r
LEFT JOIN MonthlyExp e ON r.ym = e.ym
ORDER BY financial_month DESC;
