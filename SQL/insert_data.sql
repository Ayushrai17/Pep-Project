-- SEED DATA FOR FCMS ANALYTICS
USE freelance_management;

INSERT IGNORE INTO roles (role_id, role_name, description) VALUES
(1, 'ADMIN', 'System Administrator'),
(2, 'FREELANCER', 'Independent Contractor'),
(3, 'CLIENT', 'Client User'),
(4, 'ACCOUNTANT', 'Financial Auditor');

INSERT IGNORE INTO skills (skill_id, skill_name, category) VALUES
(1, 'Python Development', 'Backend Engineering'),
(2, 'React.js Frontend', 'Frontend Engineering'),
(3, 'Data Analytics', 'Data Science'),
(4, 'MySQL Architecture', 'Database'),
(5, 'UI/UX Design', 'Design');

INSERT IGNORE INTO users (user_id, email, password_hash, first_name, last_name, status) VALUES
(1, 'admin@fcms.com', 'pbkdf2:sha256:admin', 'Ayush', 'Rai', 'ACTIVE'),
(2, 'accountant@fcms.com', 'pbkdf2:sha256:acc', 'Sarah', 'Jenkins', 'ACTIVE'),
(3, 'client1@acme.com', 'pbkdf2:sha256:cli', 'Robert', 'Smith', 'ACTIVE'),
(4, 'client2@nexus.com', 'pbkdf2:sha256:cli', 'Elena', 'Rostova', 'ACTIVE'),
(5, 'client3@vertex.com', 'pbkdf2:sha256:cli', 'Michael', 'Brown', 'ACTIVE'),
(6, 'freelancer1@dev.com', 'pbkdf2:sha256:free', 'Vikram', 'Sharma', 'ACTIVE'),
(7, 'freelancer2@dev.com', 'pbkdf2:sha256:free', 'Ananya', 'Patel', 'ACTIVE'),
(8, 'freelancer3@dev.com', 'pbkdf2:sha256:free', 'Rahul', 'Verma', 'ACTIVE'),
(9, 'freelancer4@dev.com', 'pbkdf2:sha256:free', 'Priya', 'Nair', 'ACTIVE'),
(10, 'freelancer5@dev.com', 'pbkdf2:sha256:free', 'Amit', 'Kumar', 'ACTIVE');

INSERT IGNORE INTO user_roles (user_id, role_id) VALUES
(1, 1), (2, 4), (3, 3), (4, 3), (5, 3),
(6, 2), (7, 2), (8, 2), (9, 2), (10, 2);

INSERT IGNORE INTO clients (client_id, company_name, tax_identifier, currency_code, payment_terms_days, status, billing_address) VALUES
(1, 'Acme Global Corporation', 'TAX-99881', 'INR', 30, 'ACTIVE', 'Mumbai, India'),
(2, 'Nexus Tech Solutions Inc', 'TAX-99882', 'INR', 15, 'ACTIVE', 'Bengaluru, India'),
(3, 'Vertex Systems GmbH', 'TAX-99883', 'INR', 30, 'ACTIVE', 'Delhi, India'),
(4, 'CloudScale Innovations', 'TAX-99884', 'INR', 15, 'ACTIVE', 'Hyderabad, India'),
(5, 'Apex Media Group', 'TAX-99885', 'INR', 30, 'ACTIVE', 'Pune, India'),
(6, 'Quantum Dynamics Ltd', 'TAX-99886', 'INR', 30, 'ACTIVE', 'Chennai, India'),
(7, 'Horizon AI Labs', 'TAX-99887', 'INR', 15, 'ACTIVE', 'Kolkata, India'),
(8, 'Pulse Health Systems', 'TAX-99888', 'INR', 30, 'ACTIVE', 'Ahmedabad, India'),
(9, 'Synergy Global Logistics', 'TAX-99889', 'INR', 45, 'ACTIVE', 'Gurugram, India'),
(10, 'EcoSmart Energy Solutions', 'TAX-99890', 'INR', 30, 'ACTIVE', 'Noida, India');

INSERT IGNORE INTO expense_categories (category_id, category_name, is_tax_deductible) VALUES
(1, 'Software Subscriptions', 1),
(2, 'Cloud Infrastructure', 1),
(3, 'Marketing & Advertising', 1),
(4, 'Subcontracting Fees', 1),
(5, 'Office Equipment & Supplies', 1);

INSERT IGNORE INTO projects (project_id, client_id, project_name, description, billing_model, hourly_rate, total_budget, status, start_date) VALUES
(1, 1, 'Enterprise CRM Portal', 'Fullstack Web Portal with Analytics', 'FIXED_PRICE', NULL, 150000.00, 'ACTIVE', '2026-01-15'),
(2, 1, 'Cloud Data Migration', 'ETL Data Pipeline Migration', 'HOURLY', 1200.00, 80000.00, 'COMPLETED', '2026-02-01'),
(3, 2, 'Mobile Health Dashboard', 'React Native Healthcare App', 'FIXED_PRICE', NULL, 200000.00, 'ACTIVE', '2026-03-01'),
(4, 3, 'AI Analytics Dashboard', 'Pandas & Streamlit BI Suite', 'RETAINER', NULL, 120000.00, 'COMPLETED', '2026-01-10'),
(5, 4, 'Cybersecurity Audit', 'Infrastructure Penetration Test', 'FIXED_PRICE', NULL, 90000.00, 'ON_HOLD', '2026-04-05'),
(6, 5, 'E-Commerce Platform Redesign', 'UI/UX Redesign & Shopify API', 'HOURLY', 1500.00, 110000.00, 'ACTIVE', '2026-02-20'),
(7, 6, 'DevOps CI/CD Automation', 'Docker & Kubernetes Setup', 'FIXED_PRICE', NULL, 95000.00, 'COMPLETED', '2026-01-20'),
(8, 7, 'ML Model Optimization', 'PyTorch LLM Fine-Tuning', 'HOURLY', 2000.00, 175000.00, 'ACTIVE', '2026-03-15'),
(9, 8, 'Telehealth API Integration', 'REST & GraphQL API Engine', 'FIXED_PRICE', NULL, 130000.00, 'COMPLETED', '2026-02-10'),
(10, 9, 'Logistics Tracking System', 'Real-time GPS Tracking App', 'FIXED_PRICE', NULL, 250000.00, 'ACTIVE', '2026-01-05');

INSERT IGNORE INTO tasks (task_id, project_id, task_name, estimated_hours, status) VALUES
(1, 1, 'Database Schema & DAO Layer', 40.00, 'COMPLETED'),
(2, 1, 'Frontend UI Design & Components', 60.00, 'IN_PROGRESS'),
(3, 2, 'ETL Script Migration', 50.00, 'COMPLETED'),
(4, 3, 'Mobile Auth & Navigation', 45.00, 'COMPLETED'),
(5, 4, 'Streamlit BI Dashboard Setup', 35.00, 'COMPLETED');

INSERT IGNORE INTO time_entries (time_entry_id, task_id, user_id, entry_date, hours_logged, is_billable, is_invoiced, work_description) VALUES
(1, 1, 6, '2026-01-20', 8.00, 1, 1, 'Designed 3NF database tables & foreign keys'),
(2, 1, 6, '2026-01-21', 7.50, 1, 1, 'Implemented MySQL connector DAO module'),
(3, 2, 7, '2026-02-05', 6.00, 1, 1, 'Created responsive UI layout components'),
(4, 3, 8, '2026-02-12', 8.00, 1, 1, 'Wrote Python Pandas ETL data transformation scripts'),
(5, 5, 9, '2026-01-25', 7.00, 1, 1, 'Built Streamlit KPI cards & Matplotlib charts');

INSERT IGNORE INTO invoices (invoice_id, invoice_number, client_id, project_id, issue_date, due_date, currency_code, subtotal, tax_rate_percent, tax_amount, discount_amount, late_fee_amount, total_amount, status) VALUES
(1, 'INV-2026-001', 1, 1, '2026-02-01', '2026-03-01', 'INR', 100000.00, 18.00, 18000.00, 0.00, 0.00, 118000.00, 'PAID'),
(2, 'INV-2026-002', 1, 2, '2026-02-15', '2026-03-15', 'INR', 80000.00, 18.00, 14400.00, 0.00, 0.00, 94400.00, 'PAID'),
(3, 'INV-2026-003', 2, 3, '2026-03-05', '2026-04-05', 'INR', 150000.00, 18.00, 27000.00, 0.00, 0.00, 177000.00, 'ISSUED'),
(4, 'INV-2026-004', 3, 4, '2026-01-20', '2026-02-20', 'INR', 120000.00, 18.00, 21600.00, 0.00, 0.00, 141600.00, 'PAID'),
(5, 'INV-2026-005', 4, 5, '2026-04-10', '2026-04-25', 'INR', 90000.00, 18.00, 16200.00, 0.00, 0.00, 106200.00, 'OVERDUE');

INSERT IGNORE INTO payments (payment_id, invoice_id, payment_date, amount_paid, payment_method, transaction_reference, notes) VALUES
(1, 1, '2026-02-10', 118000.00, 'BANK_TRANSFER', 'TXN-INR-99001', 'Settled full milestone invoice'),
(2, 2, '2026-02-28', 94400.00, 'CREDIT_CARD', 'TXN-INR-99002', 'Paid via corporate credit card'),
(3, 4, '2026-02-05', 141600.00, 'BANK_TRANSFER', 'TXN-INR-99003', 'Retainer monthly settlement');

INSERT IGNORE INTO expenses (expense_id, category_id, project_id, client_id, expense_date, amount, currency_code, description, receipt_ref) VALUES
(1, 1, 1, 1, '2026-01-18', 12000.00, 'INR', 'AWS Cloud Server Hosting', 'REC-AWS-881'),
(2, 1, 3, 2, '2026-03-02', 8500.00, 'INR', 'Figma Team Subscription', 'REC-FIG-402'),
(3, 2, 4, 3, '2026-01-12', 15000.00, 'INR', 'PostgreSQL Managed Cloud DB', 'REC-PG-109'),
(4, 3, 6, 5, '2026-02-25', 25000.00, 'INR', 'Google Ads Campaign', 'REC-GGL-504'),
(5, 5, 8, 7, '2026-03-18', 5000.00, 'INR', 'Hardware Test Devices', 'REC-HW-991');

INSERT IGNORE INTO project_reviews (review_id, project_id, client_id, freelancer_id, rating, feedback_text, review_date) VALUES
(1, 2, 1, 6, 5.0, 'Outstanding database optimization and migration work!', '2026-03-01'),
(2, 4, 3, 9, 4.8, 'Great BI dashboard with clear Pandas data analytics.', '2026-02-22'),
(3, 7, 6, 8, 4.9, 'Excellent DevOps setup and seamless CI/CD automation.', '2026-02-01');
