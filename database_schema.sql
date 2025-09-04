-- ================================================
-- FINANCIAL SERVICES CUSTOMER ANALYTICS PROJECT
-- Database Schema and Sample Data Creation
-- ================================================

-- Create database
CREATE DATABASE financial_analytics;
USE financial_analytics;

-- ================================================
-- 1. CUSTOMERS TABLE
-- ================================================
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(10),
    occupation VARCHAR(50),
    annual_income DECIMAL(12,2),
    credit_score INT,
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    registration_date DATE,
    customer_status VARCHAR(20) DEFAULT 'Active',
    risk_category VARCHAR(20)
);

-- ================================================
-- 2. ACCOUNTS TABLE
-- ================================================
CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    customer_id INT,
    account_type VARCHAR(30) NOT NULL,
    account_number VARCHAR(20) UNIQUE,
    opening_date DATE,
    closing_date DATE,
    account_status VARCHAR(20) DEFAULT 'Active',
    current_balance DECIMAL(15,2),
    credit_limit DECIMAL(15,2),
    interest_rate DECIMAL(5,4),
    branch_id INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ================================================
-- 3. TRANSACTIONS TABLE
-- ================================================
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    account_id INT,
    transaction_date DATETIME,
    transaction_type VARCHAR(30),
    transaction_category VARCHAR(50),
    amount DECIMAL(15,2),
    merchant_name VARCHAR(100),
    merchant_category VARCHAR(50),
    transaction_status VARCHAR(20) DEFAULT 'Completed',
    description TEXT,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- ================================================
-- 4. CREDIT_CARDS TABLE
-- ================================================
CREATE TABLE credit_cards (
    card_id INT PRIMARY KEY,
    customer_id INT,
    card_number VARCHAR(20),
    card_type VARCHAR(30),
    credit_limit DECIMAL(15,2),
    current_balance DECIMAL(15,2),
    minimum_payment DECIMAL(15,2),
    due_date DATE,
    interest_rate DECIMAL(5,4),
    issue_date DATE,
    expiry_date DATE,
    card_status VARCHAR(20) DEFAULT 'Active',
    rewards_points INT DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ================================================
-- 5. LOANS TABLE
-- ================================================
CREATE TABLE loans (
    loan_id INT PRIMARY KEY,
    customer_id INT,
    loan_type VARCHAR(30),
    loan_amount DECIMAL(15,2),
    outstanding_balance DECIMAL(15,2),
    interest_rate DECIMAL(5,4),
    loan_term_months INT,
    monthly_payment DECIMAL(15,2),
    start_date DATE,
    end_date DATE,
    loan_status VARCHAR(20),
    collateral_type VARCHAR(50),
    purpose VARCHAR(100),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ================================================
-- 6. CUSTOMER_INTERACTIONS TABLE
-- ================================================
CREATE TABLE customer_interactions (
    interaction_id INT PRIMARY KEY,
    customer_id INT,
    interaction_date DATETIME,
    interaction_type VARCHAR(30),
    channel VARCHAR(20),
    duration_minutes INT,
    resolution_status VARCHAR(20),
    satisfaction_score INT,
    agent_id INT,
    issue_category VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ================================================
-- 7. BRANCHES TABLE
-- ================================================
CREATE TABLE branches (
    branch_id INT PRIMARY KEY,
    branch_name VARCHAR(100),
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    manager_name VARCHAR(100),
    phone VARCHAR(20),
    opening_date DATE
);

-- ================================================
-- SAMPLE DATA INSERTION
-- ================================================

-- Insert sample customers
INSERT INTO customers VALUES
(1, 'John', 'Smith', 'john.smith@email.com', '555-0101', '1985-03-15', 'Male', 'Software Engineer', 95000.00, 750, 'New York', 'NY', 'USA', '2020-01-15', 'Active', 'Low'),
(2, 'Sarah', 'Johnson', 'sarah.j@email.com', '555-0102', '1990-07-22', 'Female', 'Marketing Manager', 78000.00, 720, 'Los Angeles', 'CA', 'USA', '2019-03-20', 'Active', 'Low'),
(3, 'Michael', 'Brown', 'michael.b@email.com', '555-0103', '1978-11-08', 'Male', 'Doctor', 150000.00, 800, 'Chicago', 'IL', 'USA', '2018-05-10', 'Active', 'Low'),
(4, 'Emily', 'Davis', 'emily.d@email.com', '555-0104', '1992-12-03', 'Female', 'Teacher', 45000.00, 680, 'Houston', 'TX', 'USA', '2021-07-18', 'Active', 'Medium'),
(5, 'Robert', 'Wilson', 'robert.w@email.com', '555-0105', '1983-09-14', 'Male', 'Business Owner', 120000.00, 690, 'Phoenix', 'AZ', 'USA', '2019-11-25', 'Active', 'Medium'),
(6, 'Jessica', 'Martinez', 'jessica.m@email.com', '555-0106', '1995-04-28', 'Female', 'Nurse', 55000.00, 640, 'Philadelphia', 'PA', 'USA', '2022-02-14', 'Active', 'Medium'),
(7, 'David', 'Anderson', 'david.a@email.com', '555-0107', '1987-08-17', 'Male', 'Sales Manager', 65000.00, 600, 'San Antonio', 'TX', 'USA', '2020-09-30', 'Active', 'High'),
(8, 'Lisa', 'Taylor', 'lisa.t@email.com', '555-0108', '1991-01-25', 'Female', 'Accountant', 52000.00, 710, 'San Diego', 'CA', 'USA', '2021-04-12', 'Active', 'Low'),
(9, 'Christopher', 'Thomas', 'chris.t@email.com', '555-0109', '1979-06-11', 'Male', 'Construction Worker', 48000.00, 580, 'Dallas', 'TX', 'USA', '2020-12-05', 'Inactive', 'High'),
(10, 'Amanda', 'Jackson', 'amanda.j@email.com', '555-0110', '1988-10-30', 'Female', 'Graphic Designer', 58000.00, 670, 'San Jose', 'CA', 'USA', '2019-08-22', 'Active', 'Medium');

-- Insert sample accounts
INSERT INTO accounts VALUES
(101, 1, 'Checking', 'CHK001', '2020-01-15', NULL, 'Active', 15000.00, NULL, 0.0050, 1),
(102, 1, 'Savings', 'SAV001', '2020-01-15', NULL, 'Active', 45000.00, NULL, 0.0200, 1),
(103, 2, 'Checking', 'CHK002', '2019-03-20', NULL, 'Active', 8500.00, NULL, 0.0050, 2),
(104, 2, 'Savings', 'SAV002', '2019-03-20', NULL, 'Active', 32000.00, NULL, 0.0200, 2),
(105, 3, 'Checking', 'CHK003', '2018-05-10', NULL, 'Active', 25000.00, NULL, 0.0050, 3),
(106, 3, 'Investment', 'INV001', '2018-05-10', NULL, 'Active', 150000.00, NULL, 0.0000, 3),
(107, 4, 'Checking', 'CHK004', '2021-07-18', NULL, 'Active', 3200.00, NULL, 0.0050, 4),
(108, 5, 'Business Checking', 'BCK001', '2019-11-25', NULL, 'Active', 85000.00, NULL, 0.0075, 5),
(109, 6, 'Checking', 'CHK005', '2022-02-14', NULL, 'Active', 4500.00, NULL, 0.0050, 6),
(110, 7, 'Checking', 'CHK006', '2020-09-30', NULL, 'Active', 1200.00, NULL, 0.0050, 7);

-- Insert sample transactions
INSERT INTO transactions VALUES
(1001, 101, '2024-01-15 10:30:00', 'Purchase', 'Grocery', -150.00, 'SuperMart', 'Grocery', 'Completed', 'Weekly groceries'),
(1002, 101, '2024-01-16 14:22:00', 'Purchase', 'Gas', -65.00, 'Shell Station', 'Gas', 'Completed', 'Fuel'),
(1003, 102, '2024-01-17 09:15:00', 'Deposit', 'Salary', 7916.67, 'Direct Deposit', 'Salary', 'Completed', 'Monthly salary'),
(1004, 103, '2024-01-18 11:45:00', 'Purchase', 'Dining', -85.00, 'Restaurant ABC', 'Dining', 'Completed', 'Dinner'),
(1005, 104, '2024-01-19 16:30:00', 'Transfer', 'Internal', 1000.00, 'Internal Transfer', 'Transfer', 'Completed', 'Savings transfer'),
(1006, 105, '2024-01-20 08:00:00', 'Purchase', 'Medical', -250.00, 'City Hospital', 'Healthcare', 'Completed', 'Medical consultation'),
(1007, 106, '2024-01-21 13:20:00', 'Investment', 'Stock Purchase', -5000.00, 'Investment Platform', 'Investment', 'Completed', 'Stock investment'),
(1008, 107, '2024-01-22 15:45:00', 'Purchase', 'Clothing', -120.00, 'Fashion Store', 'Retail', 'Completed', 'Clothing'),
(1009, 108, '2024-01-23 10:10:00', 'Deposit', 'Business Revenue', 15000.00, 'Business Income', 'Business', 'Completed', 'Monthly revenue'),
(1010, 109, '2024-01-24 12:30:00', 'Purchase', 'Pharmacy', -45.00, 'CVS Pharmacy', 'Healthcare', 'Completed', 'Medication');

-- Insert sample credit cards
INSERT INTO credit_cards VALUES
(201, 1, '****1234', 'Platinum', 15000.00, 2500.00, 125.00, '2024-02-15', 0.1899, '2022-01-15', '2027-01-15', 'Active', 2500),
(202, 2, '****5678', 'Gold', 10000.00, 1800.00, 90.00, '2024-02-20', 0.1999, '2021-03-20', '2026-03-20', 'Active', 1800),
(203, 3, '****9012', 'Black', 25000.00, 5000.00, 250.00, '2024-02-10', 0.1699, '2020-05-10', '2025-05-10', 'Active', 5000),
(204, 4, '****3456', 'Silver', 5000.00, 1200.00, 60.00, '2024-02-25', 0.2199, '2023-07-18', '2028-07-18', 'Active', 600),
(205, 5, '****7890', 'Business', 20000.00, 8000.00, 400.00, '2024-02-12', 0.1799, '2021-11-25', '2026-11-25', 'Active', 4000);

-- Insert sample loans
INSERT INTO loans VALUES
(301, 1, 'Mortgage', 450000.00, 420000.00, 0.0325, 360, 2200.00, '2020-06-01', '2050-06-01', 'Active', 'Property', 'Home Purchase'),
(302, 2, 'Auto Loan', 35000.00, 28000.00, 0.0450, 60, 650.00, '2021-01-15', '2026-01-15', 'Active', 'Vehicle', 'Car Purchase'),
(303, 3, 'Personal Loan', 15000.00, 12000.00, 0.0680, 36, 460.00, '2022-03-10', '2025-03-10', 'Active', 'None', 'Home Improvement'),
(304, 5, 'Business Loan', 200000.00, 180000.00, 0.0550, 84, 2800.00, '2021-05-20', '2028-05-20', 'Active', 'Business Assets', 'Business Expansion'),
(305, 7, 'Auto Loan', 25000.00, 15000.00, 0.0520, 48, 580.00, '2022-08-15', '2026-08-15', 'Active', 'Vehicle', 'Car Purchase');

-- Insert sample customer interactions
INSERT INTO customer_interactions VALUES
(401, 1, '2024-01-10 14:30:00', 'Phone Call', 'Phone', 15, 'Resolved', 5, 101, 'Account Balance'),
(402, 2, '2024-01-12 10:15:00', 'Branch Visit', 'Branch', 30, 'Resolved', 4, 102, 'Loan Application'),
(403, 3, '2024-01-14 16:45:00', 'Online Chat', 'Online', 20, 'Resolved', 5, 103, 'Credit Card'),
(404, 4, '2024-01-16 11:20:00', 'Phone Call', 'Phone', 25, 'Pending', 3, 104, 'Dispute'),
(405, 5, '2024-01-18 09:30:00', 'Email', 'Email', 0, 'Resolved', 4, 105, 'Account Information'),
(406, 6, '2024-01-20 13:15:00', 'Branch Visit', 'Branch', 45, 'Resolved', 5, 106, 'New Account'),
(407, 7, '2024-01-22 15:00:00', 'Phone Call', 'Phone', 35, 'Escalated', 2, 107, 'Complaint'),
(408, 8, '2024-01-24 12:30:00', 'Online Chat', 'Online', 10, 'Resolved', 5, 108, 'Balance Inquiry'),
(409, 9, '2024-01-26 14:20:00', 'Phone Call', 'Phone', 40, 'Unresolved', 1, 109, 'Account Closure'),
(410, 10, '2024-01-28 10:45:00', 'Branch Visit', 'Branch', 25, 'Resolved', 4, 110, 'Investment Options');

-- Insert sample branches
INSERT INTO branches VALUES
(1, 'Downtown Manhattan', '123 Wall Street, New York, NY 10005', 'New York', 'NY', '10005', 'James Wilson', '555-1001', '2015-01-01'),
(2, 'Beverly Hills', '456 Rodeo Drive, Beverly Hills, CA 90210', 'Los Angeles', 'CA', '90210', 'Maria Garcia', '555-1002', '2016-03-15'),
(3, 'Chicago Loop', '789 LaSalle Street, Chicago, IL 60604', 'Chicago', 'IL', '60604', 'Robert Chen', '555-1003', '2014-07-20'),
(4, 'Houston Center', '321 Main Street, Houston, TX 77002', 'Houston', 'TX', '77002', 'Lisa Anderson', '555-1004', '2017-05-10'),
(5, 'Phoenix Central', '654 Central Avenue, Phoenix, AZ 85004', 'Phoenix', 'AZ', '85004', 'Michael Rodriguez', '555-1005', '2018-09-12'),
(6, 'Philadelphia Square', '987 Market Street, Philadelphia, PA 19107', 'Philadelphia', 'PA', '19107', 'Jennifer Lee', '555-1006', '2019-02-28'),
(7, 'San Antonio Plaza', '147 Commerce Street, San Antonio, TX 78205', 'San Antonio', 'TX', '78205', 'David Martinez', '555-1007', '2020-11-15');