-- ==============================================================================
-- DATABASE VIEWS SCRIPT: views.sql
-- Project: Freelance & Client Management System with Freelancer Income & Client Analytics
-- Architecture: 3NF Normalized Relational Schema
-- Purpose: Pre-computed analytical database views for fast query access.
-- ==============================================================================

USE freelance_management;

-- ------------------------------------------------------------------------------
-- View 1: v_invoice_summary
-- Purpose: Aggregates invoice financials, calculated tax, late fees, paid amounts, and remaining balance due.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_invoice_summary AS
SELECT 
    i.invoice_id,
    i.invoice_number,
    i.client_id,
    c.company_name,
    i.project_id,
    p.project_name,
    i.issue_date,
    i.due_date,
    i.currency_code,
    i.subtotal,
    i.tax_rate_percent,
    i.tax_amount,
    i.discount_amount,
    i.late_fee_amount,
    i.total_amount,
    COALESCE(SUM(pm.amount_paid), 0.00) AS total_paid_amount,
    ROUND(i.total_amount - COALESCE(SUM(pm.amount_paid), 0.00), 2) AS remaining_balance_due,
    i.status AS invoice_status,
    DATEDIFF(CURRENT_DATE(), i.due_date) AS days_past_due
FROM invoices i
JOIN clients c ON i.client_id = c.client_id
LEFT JOIN projects p ON i.project_id = p.project_id
LEFT JOIN payments pm ON i.invoice_id = pm.invoice_id
GROUP BY 
    i.invoice_id, i.invoice_number, i.client_id, c.company_name, 
    i.project_id, p.project_name, i.issue_date, i.due_date, 
    i.currency_code, i.subtotal, i.tax_rate_percent, i.tax_amount, 
    i.discount_amount, i.late_fee_amount, i.total_amount, i.status;

-- ------------------------------------------------------------------------------
-- View 2: v_client_analytics
-- Purpose: Summarizes client performance metrics: total projects, paid revenue, pending balance, and CLTV.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_client_analytics AS
SELECT 
    c.client_id,
    c.company_name,
    c.tax_identifier,
    c.currency_code,
    c.status AS client_status,
    COUNT(DISTINCT p.project_id) AS total_projects,
    COALESCE(SUM(CASE WHEN i.status = 'PAID' THEN i.total_amount ELSE 0 END), 0.00) AS client_lifetime_value,
    COALESCE(SUM(CASE WHEN i.status IN ('ISSUED', 'OVERDUE', 'PARTIALLY_PAID') THEN (i.total_amount - COALESCE(pm.total_paid, 0)) ELSE 0 END), 0.00) AS pending_balance_due
FROM clients c
LEFT JOIN projects p ON c.client_id = p.client_id
LEFT JOIN invoices i ON c.client_id = i.client_id
LEFT JOIN (
    SELECT invoice_id, SUM(amount_paid) AS total_paid
    FROM payments
    GROUP BY invoice_id
) pm ON i.invoice_id = pm.invoice_id
GROUP BY c.client_id, c.company_name, c.tax_identifier, c.currency_code, c.status;

-- ------------------------------------------------------------------------------
-- View 3: v_freelancer_utilization
-- Purpose: Calculates total logged hours, billable hours, non-billable hours, and billable utilization percentage.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_freelancer_utilization AS
SELECT 
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS freelancer_name,
    u.email,
    u.status AS account_status,
    COALESCE(SUM(te.hours_logged), 0.00) AS total_logged_hours,
    COALESCE(SUM(CASE WHEN te.is_billable = TRUE THEN te.hours_logged ELSE 0 END), 0.00) AS billable_hours,
    COALESCE(SUM(CASE WHEN te.is_billable = FALSE THEN te.hours_logged ELSE 0 END), 0.00) AS non_billable_hours,
    ROUND(
        CASE 
            WHEN SUM(te.hours_logged) > 0 THEN (SUM(CASE WHEN te.is_billable = TRUE THEN te.hours_logged ELSE 0 END) / SUM(te.hours_logged)) * 100
            ELSE 0.00 
        END, 2
    ) AS billable_utilization_pct
FROM users u
JOIN user_roles ur ON u.user_id = ur.user_id
JOIN roles r ON ur.role_id = r.role_id
LEFT JOIN time_entries te ON u.user_id = te.user_id
WHERE r.role_name = 'FREELANCER'
GROUP BY u.user_id, freelancer_name, u.email, u.status;

-- ------------------------------------------------------------------------------
-- View 4: v_project_budget_variance
-- Purpose: Compares estimated task effort hours against actual logged hours to detect project budget overruns.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_project_budget_variance AS
SELECT 
    p.project_id,
    p.project_name,
    c.company_name,
    p.billing_model,
    p.total_budget,
    p.status AS project_status,
    COALESCE(SUM(t.estimated_hours), 0.00) AS total_estimated_hours,
    COALESCE(SUM(te.hours_logged), 0.00) AS total_actual_hours,
    ROUND(COALESCE(SUM(te.hours_logged), 0.00) - COALESCE(SUM(t.estimated_hours), 0.00), 2) AS hour_variance,
    CASE 
        WHEN COALESCE(SUM(te.hours_logged), 0.00) > COALESCE(SUM(t.estimated_hours), 0.00) THEN 'OVER_BUDGET'
        ELSE 'WITHIN_BUDGET'
    END AS budget_health
FROM projects p
JOIN clients c ON p.client_id = c.client_id
LEFT JOIN tasks t ON p.project_id = t.project_id
LEFT JOIN time_entries te ON t.task_id = te.task_id
GROUP BY p.project_id, p.project_name, c.company_name, p.billing_model, p.total_budget, p.status;

-- ------------------------------------------------------------------------------
-- View 5: v_monthly_financials
-- Purpose: Aggregates gross monthly revenue, operating expenses, net profit, and profit margin %.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_monthly_financials AS
WITH MonthlyRev AS (
    SELECT 
        DATE_FORMAT(issue_date, '%Y-%m') AS financial_month,
        SUM(total_amount) AS gross_revenue
    FROM invoices 
    WHERE status = 'PAID'
    GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
),
MonthlyExp AS (
    SELECT 
        DATE_FORMAT(expense_date, '%Y-%m') AS financial_month,
        SUM(amount) AS total_expenses
    FROM expenses
    GROUP BY DATE_FORMAT(expense_date, '%Y-%m')
)
SELECT 
    COALESCE(r.financial_month, e.financial_month) AS financial_month,
    COALESCE(r.gross_revenue, 0.00) AS gross_revenue,
    COALESCE(e.total_expenses, 0.00) AS total_expenses,
    ROUND(COALESCE(r.gross_revenue, 0.00) - COALESCE(e.total_expenses, 0.00), 2) AS net_profit,
    ROUND(
        CASE 
            WHEN COALESCE(r.gross_revenue, 0.00) > 0 THEN ((COALESCE(r.gross_revenue, 0.00) - COALESCE(e.total_expenses, 0.00)) / r.gross_revenue) * 100
            ELSE 0.00 
        END, 2
    ) AS profit_margin_pct
FROM MonthlyRev r
LEFT JOIN MonthlyExp e ON r.financial_month = e.financial_month
UNION
SELECT 
    COALESCE(r.financial_month, e.financial_month) AS financial_month,
    COALESCE(r.gross_revenue, 0.00) AS gross_revenue,
    COALESCE(e.total_expenses, 0.00) AS total_expenses,
    ROUND(COALESCE(r.gross_revenue, 0.00) - COALESCE(e.total_expenses, 0.00), 2) AS net_profit,
    ROUND(
        CASE 
            WHEN COALESCE(r.gross_revenue, 0.00) > 0 THEN ((COALESCE(r.gross_revenue, 0.00) - COALESCE(e.total_expenses, 0.00)) / r.gross_revenue) * 100
            ELSE 0.00 
        END, 2
    ) AS profit_margin_pct
FROM MonthlyRev r
RIGHT JOIN MonthlyExp e ON r.financial_month = e.financial_month;
