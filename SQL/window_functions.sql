-- ==============================================================================
-- WINDOW FUNCTIONS ANALYTICAL SCRIPT: window_functions.sql
-- Project: Freelance & Client Management System with Freelancer Income & Client Analytics
-- Purpose: Demonstrates advanced analytical window functions (ROW_NUMBER, RANK, DENSE_RANK,
-- LAG, LEAD, SUM OVER, AVG OVER) for business reporting.
-- ==============================================================================

USE freelance_management;

-- ------------------------------------------------------------------------------
-- Query 1: ROW_NUMBER() - Sequential Freelancer Billing Leaderboard
-- Business Purpose: Assigns a unique sequential row number (1, 2, 3...) to freelancers 
-- ranked by total billable hours logged.
-- ------------------------------------------------------------------------------
SELECT 
    ROW_NUMBER() OVER (ORDER BY SUM(te.hours_logged) DESC) AS rank_position,
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS freelancer_name,
    SUM(te.hours_logged) AS total_billable_hours
FROM users u
JOIN time_entries te ON u.user_id = te.user_id
WHERE te.is_billable = TRUE
GROUP BY u.user_id, freelancer_name
ORDER BY rank_position ASC;

-- ------------------------------------------------------------------------------
-- Query 2: RANK() - Client Lifetime Revenue Tier Ranking (With Gaps)
-- Business Purpose: Ranks clients by total revenue spent. If two clients have equal 
-- revenue, they receive the same rank, and the next rank skips numbers.
-- ------------------------------------------------------------------------------
SELECT 
    RANK() OVER (ORDER BY SUM(i.total_amount) DESC) AS client_revenue_rank,
    c.client_id,
    c.company_name,
    c.currency_code,
    SUM(i.total_amount) AS total_lifetime_spend
FROM clients c
JOIN invoices i ON c.client_id = i.client_id AND i.status = 'PAID'
GROUP BY c.client_id, c.company_name, c.currency_code
ORDER BY client_revenue_rank ASC;

-- ------------------------------------------------------------------------------
-- Query 3: DENSE_RANK() - Top-Rated Freelancers Ranking (Without Rank Gaps)
-- Business Purpose: Ranks freelancers based on average client rating score without skipping rank numbers on ties.
-- ------------------------------------------------------------------------------
SELECT 
    DENSE_RANK() OVER (ORDER BY AVG(pr.rating) DESC) AS rating_dense_rank,
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS freelancer_name,
    COUNT(pr.review_id) AS total_reviews,
    ROUND(AVG(pr.rating), 2) AS avg_rating
FROM users u
JOIN project_reviews pr ON u.user_id = pr.freelancer_id
GROUP BY u.user_id, freelancer_name
ORDER BY rating_dense_rank ASC;

-- ------------------------------------------------------------------------------
-- Query 4: LAG() - Month-over-Month (MoM) Invoice Revenue Growth Comparison
-- Business Purpose: Fetches the previous month's revenue alongside current month's revenue to compute MoM delta.
-- ------------------------------------------------------------------------------
WITH MonthlyRev AS (
    SELECT 
        DATE_FORMAT(issue_date, '%Y-%m') AS rev_month,
        SUM(total_amount) AS current_month_revenue
    FROM invoices
    WHERE status = 'PAID'
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
)
SELECT 
    rev_month,
    current_month_revenue,
    LAG(current_month_revenue, 1) OVER (ORDER BY rev_month) AS previous_month_revenue,
    (current_month_revenue - LAG(current_month_revenue, 1) OVER (ORDER BY rev_month)) AS mom_revenue_change
FROM MonthlyRev
ORDER BY rev_month ASC;

-- ------------------------------------------------------------------------------
-- Query 5: LEAD() - Project Milestone Timeline Delivery Forecasting
-- Business Purpose: Compares each milestone due date against the *next* milestone due date within the same project.
-- ------------------------------------------------------------------------------
SELECT 
    project_id,
    milestone_id,
    title AS milestone_title,
    due_date AS current_milestone_due_date,
    LEAD(due_date, 1) OVER (PARTITION BY project_id ORDER BY due_date) AS next_milestone_due_date,
    DATEDIFF(LEAD(due_date, 1) OVER (PARTITION BY project_id ORDER BY due_date), due_date) AS days_until_next_milestone
FROM milestones
ORDER BY project_id ASC, due_date ASC;

-- ------------------------------------------------------------------------------
-- Query 6: SUM() OVER() - Cumulative Running Total Revenue per Client
-- Business Purpose: Calculates a running cumulative sum of revenue over time for each client.
-- ------------------------------------------------------------------------------
SELECT 
    c.company_name,
    i.invoice_number,
    i.issue_date,
    i.total_amount AS invoice_amount,
    SUM(i.total_amount) OVER (
        PARTITION BY i.client_id 
        ORDER BY i.issue_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_client_revenue
FROM clients c
JOIN invoices i ON c.client_id = i.client_id
WHERE i.status = 'PAID'
ORDER BY c.company_name ASC, i.issue_date ASC;

-- ------------------------------------------------------------------------------
-- Query 7: AVG() OVER() - Project Budget vs Average Budget for Billing Model
-- Business Purpose: Compares an individual project's budget against the average budget cap of its billing model.
-- ------------------------------------------------------------------------------
SELECT 
    project_id,
    project_name,
    billing_model,
    total_budget,
    ROUND(AVG(total_budget) OVER (PARTITION BY billing_model), 2) AS category_avg_budget,
    ROUND(total_budget - AVG(total_budget) OVER (PARTITION BY billing_model), 2) AS variance_from_category_avg
FROM projects
WHERE total_budget IS NOT NULL
ORDER BY billing_model ASC, total_budget DESC;

-- ------------------------------------------------------------------------------
-- Query 8: ROW_NUMBER() OVER (PARTITION BY ...) - Latest Payment per Invoice
-- Business Purpose: Extracts the single most recent payment transaction recorded for each invoice.
-- ------------------------------------------------------------------------------
WITH RankedPayments AS (
    SELECT 
        payment_id,
        invoice_id,
        payment_date,
        amount_paid,
        payment_method,
        ROW_NUMBER() OVER (PARTITION BY invoice_id ORDER BY payment_date DESC, payment_id DESC) AS rn
    FROM payments
)
SELECT 
    payment_id,
    invoice_id,
    payment_date AS latest_payment_date,
    amount_paid AS latest_amount_settled,
    payment_method
FROM RankedPayments
WHERE rn = 1;

-- ------------------------------------------------------------------------------
-- Query 9: DENSE_RANK() OVER (PARTITION BY ...) - Top Work-Intensive Tasks per Project
-- Business Purpose: Ranks tasks within each project based on total hours logged.
-- ------------------------------------------------------------------------------
SELECT 
    p.project_name,
    t.task_name,
    SUM(te.hours_logged) AS total_task_hours,
    DENSE_RANK() OVER (PARTITION BY t.project_id ORDER BY SUM(te.hours_logged) DESC) AS task_effort_rank
FROM projects p
JOIN tasks t ON p.project_id = t.project_id
JOIN time_entries te ON t.task_id = te.task_id
GROUP BY p.project_name, t.project_id, t.task_name
ORDER BY p.project_name ASC, task_effort_rank ASC;

-- ------------------------------------------------------------------------------
-- Query 10: SUM() OVER & AVG() OVER - Moving Average & Cumulative Expenses
-- Business Purpose: Computes cumulative business expense spend and 3-month moving average burn rate.
-- ------------------------------------------------------------------------------
WITH MonthlyExpenses AS (
    SELECT 
        DATE_FORMAT(expense_date, '%Y-%m') AS exp_month,
        SUM(amount) AS monthly_amount
    FROM expenses
    GROUP BY DATE_FORMAT(expense_date, '%Y-%m')
)
SELECT 
    exp_month,
    monthly_amount,
    SUM(monthly_amount) OVER (
        ORDER BY exp_month 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_total_expenses,
    ROUND(
        AVG(monthly_amount) OVER (
            ORDER BY exp_month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS three_month_moving_avg_burn
FROM MonthlyExpenses
ORDER BY exp_month ASC;
