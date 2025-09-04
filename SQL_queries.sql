-- ================================================
-- 1. CUSTOMER SEGMENTATION ANALYSIS
-- ================================================

-- High-Value Customer Analysis
-- Identifies customers with highest lifetime value and engagement
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.annual_income,
        c.credit_score,
        c.risk_category,
        COUNT(DISTINCT a.account_id) as total_accounts,
        SUM(a.current_balance) as total_balance,
        COUNT(DISTINCT cc.card_id) as credit_cards_count,
        SUM(cc.credit_limit) as total_credit_limit,
        COUNT(DISTINCT l.loan_id) as active_loans,
        SUM(l.loan_amount) as total_loan_amount,
        AVG(ci.satisfaction_score) as avg_satisfaction,
        COUNT(ci.interaction_id) as total_interactions
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN credit_cards cc ON c.customer_id = cc.customer_id
    LEFT JOIN loans l ON c.customer_id = l.customer_id
    LEFT JOIN customer_interactions ci ON c.customer_id = ci.customer_id
    WHERE c.customer_status = 'Active'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.annual_income, c.credit_score, c.risk_category
),
customer_value_score AS (
    SELECT 
        *,
        (total_balance * 0.3 + total_credit_limit * 0.2 + total_loan_amount * 0.25 + 
         annual_income * 0.15 + (credit_score/800) * 10000 * 0.1) as customer_value_score,
        CASE 
            WHEN total_balance > 100000 OR total_credit_limit > 20000 THEN 'Premium'
            WHEN total_balance > 50000 OR total_credit_limit > 10000 THEN 'Gold'
            WHEN total_balance > 20000 OR total_credit_limit > 5000 THEN 'Silver'
            ELSE 'Standard'
        END as customer_tier
    FROM customer_metrics
)
SELECT 
    customer_id,
    first_name,
    last_name,
    customer_tier,
    risk_category,
    ROUND(customer_value_score, 2) as value_score,
    total_accounts,
    total_balance,
    credit_cards_count,
    total_credit_limit,
    active_loans,
    ROUND(avg_satisfaction, 2) as avg_satisfaction_score,
    CASE 
        WHEN avg_satisfaction >= 4.5 THEN 'Highly Satisfied'
        WHEN avg_satisfaction >= 3.5 THEN 'Satisfied'
        WHEN avg_satisfaction >= 2.5 THEN 'Neutral'
        ELSE 'Dissatisfied'
    END as satisfaction_level
FROM customer_value_score
ORDER BY customer_value_score DESC;

-- ================================================
-- 2. PRODUCT PERFORMANCE ANALYSIS
-- ================================================

-- Account Type Performance and Profitability
WITH ordered AS (
    SELECT 
        a.account_type,
        a.current_balance,
        a.interest_rate,
        ROW_NUMBER() OVER (PARTITION BY a.account_type ORDER BY a.current_balance) AS rn,
        COUNT(*) OVER (PARTITION BY a.account_type) AS cnt
    FROM accounts a
    WHERE a.account_status = 'Active'
)
SELECT 
    o.account_type,
    COUNT(*) AS total_accounts,
    SUM(o.current_balance) AS total_balance,
    AVG(o.current_balance) AS avg_balance,
    SUM(o.current_balance * o.interest_rate) AS annual_interest_income,
    COUNT(CASE WHEN o.current_balance > 10000 THEN 1 END) AS high_balance_accounts,
    ROUND(COUNT(CASE WHEN o.current_balance > 10000 THEN 1 END) * 100.0 / COUNT(*), 2) AS high_balance_percentage,
    MIN(o.current_balance) AS min_balance,
    MAX(o.current_balance) AS max_balance,
    AVG(
        CASE 
            WHEN o.rn IN (FLOOR((o.cnt + 1) / 2), CEIL((o.cnt + 1) / 2)) 
            THEN o.current_balance 
        END
    ) AS median_balance
FROM ordered o
GROUP BY o.account_type
ORDER BY total_balance DESC;

-- ================================================
-- 3. CREDIT RISK ANALYSIS
-- ================================================

-- Credit Utilization and Risk Assessment
WITH credit_analysis AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.credit_score,
        c.annual_income,
        c.risk_category,
        cc.card_type,
        cc.credit_limit,
        cc.current_balance,
        ROUND((cc.current_balance / NULLIF(cc.credit_limit, 0)) * 100, 2) as utilization_rate,
        cc.interest_rate,
        cc.minimum_payment,
        CASE 
            WHEN cc.current_balance / NULLIF(cc.credit_limit, 0) > 0.8 THEN 'High Risk'
            WHEN cc.current_balance / NULLIF(cc.credit_limit, 0) > 0.5 THEN 'Medium Risk'
            WHEN cc.current_balance / NULLIF(cc.credit_limit, 0) > 0.3 THEN 'Low Risk'
            ELSE 'Very Low Risk'
        END as utilization_risk_level
    FROM customers c
    JOIN credit_cards cc ON c.customer_id = cc.customer_id
    WHERE cc.card_status = 'Active'
)
SELECT 
    risk_category,
    utilization_risk_level,
    COUNT(*) as customer_count,
    AVG(credit_score) as avg_credit_score,
    AVG(utilization_rate) as avg_utilization_rate,
    AVG(annual_income) as avg_annual_income,
    SUM(current_balance) as total_outstanding_balance,
    SUM(credit_limit) as total_credit_limit,
    ROUND(SUM(current_balance) / SUM(credit_limit) * 100, 2) as portfolio_utilization_rate
FROM credit_analysis
GROUP BY risk_category, utilization_risk_level
ORDER BY risk_category, utilization_risk_level;

-- ================================================
-- 4. TRANSACTION PATTERN ANALYSIS
-- ================================================

-- Monthly Transaction Trends and Customer Behavior
WITH monthly_transactions AS (
    SELECT 
        DATE_FORMAT(t.transaction_date, '%Y-%m') as transaction_month,
        c.customer_id,
        c.customer_status,
        COUNT(*) as transaction_count,
        SUM(CASE WHEN t.amount > 0 THEN t.amount ELSE 0 END) as total_deposits,
        SUM(CASE WHEN t.amount < 0 THEN ABS(t.amount) ELSE 0 END) as total_withdrawals,
        SUM(t.amount) as net_transaction_amount,
        COUNT(DISTINCT t.transaction_category) as unique_categories,
        AVG(ABS(t.amount)) as avg_transaction_amount
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    JOIN customers c ON a.customer_id = c.customer_id
    WHERE t.transaction_status = 'Completed'
    GROUP BY DATE_FORMAT(t.transaction_date, '%Y-%m'), c.customer_id, c.customer_status
),
customer_transaction_summary AS (
    SELECT 
        customer_id,
        COUNT(*) as active_months,
        SUM(transaction_count) as total_transactions,
        AVG(transaction_count) as avg_monthly_transactions,
        SUM(total_deposits) as total_deposits,
        SUM(total_withdrawals) as total_withdrawals,
        SUM(net_transaction_amount) as net_amount,
        AVG(avg_transaction_amount) as avg_transaction_size
    FROM monthly_transactions
    GROUP BY customer_id
)
SELECT 
    cts.customer_id,
    c.first_name,
    c.last_name,
    c.risk_category,
    cts.active_months,
    cts.total_transactions,
    ROUND(cts.avg_monthly_transactions, 2) as avg_monthly_transactions,
    cts.total_deposits,
    cts.total_withdrawals,
    cts.net_amount,
    ROUND(cts.avg_transaction_size, 2) as avg_transaction_size,
    CASE 
        WHEN cts.avg_monthly_transactions >= 20 THEN 'High Activity'
        WHEN cts.avg_monthly_transactions >= 10 THEN 'Medium Activity'
        WHEN cts.avg_monthly_transactions >= 5 THEN 'Low Activity'
        ELSE 'Minimal Activity'
    END as activity_level
FROM customer_transaction_summary cts
JOIN customers c ON cts.customer_id = c.customer_id
ORDER BY cts.total_transactions DESC;

-- ================================================
-- 5. LOAN PORTFOLIO ANALYSIS
-- ================================================

-- Loan Performance and Default Risk Assessment
WITH loan_performance AS (
    SELECT 
        l.loan_type,
        l.loan_status,
        COUNT(*) as loan_count,
        SUM(l.loan_amount) as total_loan_amount,
        SUM(l.outstanding_balance) as total_outstanding,
        AVG(l.interest_rate) as avg_interest_rate,
        AVG(l.loan_term_months) as avg_term_months,
        AVG(c.credit_score) as avg_borrower_credit_score,
        AVG(c.annual_income) as avg_borrower_income,
        SUM(l.loan_amount - l.outstanding_balance) as total_repaid,
        ROUND(AVG((l.loan_amount - l.outstanding_balance) / l.loan_amount * 100), 2) as avg_repayment_percentage
    FROM loans l
    JOIN customers c ON l.customer_id = c.customer_id
    GROUP BY l.loan_type, l.loan_status
),
risk_assessment AS (
    SELECT 
        l.customer_id,
        c.first_name,
        c.last_name,
        c.credit_score,
        c.annual_income,
        c.risk_category,
        l.loan_type,
        l.loan_amount,
        l.outstanding_balance,
        l.monthly_payment,
        ROUND((l.monthly_payment * 12) / c.annual_income * 100, 2) as debt_to_income_ratio,
        ROUND(l.outstanding_balance / l.loan_amount * 100, 2) as remaining_balance_percentage,
        CASE 
            WHEN (l.monthly_payment * 12) / c.annual_income > 0.4 THEN 'High Risk'
            WHEN (l.monthly_payment * 12) / c.annual_income > 0.25 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END as payment_risk_level
    FROM loans l
    JOIN customers c ON l.customer_id = c.customer_id
    WHERE l.loan_status = 'Active'
)
SELECT 
    loan_type,
    payment_risk_level,
    COUNT(*) as borrower_count,
    AVG(credit_score) as avg_credit_score,
    AVG(debt_to_income_ratio) as avg_debt_to_income,
    SUM(loan_amount) as total_loans,
    SUM(outstanding_balance) as total_outstanding,
    ROUND(AVG(remaining_balance_percentage), 2) as avg_remaining_balance_pct
FROM risk_assessment
GROUP BY loan_type, payment_risk_level
ORDER BY loan_type, payment_risk_level;

-- ================================================
-- 6. CUSTOMER CHURN PREDICTION ANALYSIS
-- ================================================

-- Identify customers at risk of churning
WITH customer_activity AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.registration_date,
        c.customer_status,
        DATEDIFF(CURRENT_DATE, c.registration_date) as days_since_registration,
        COUNT(DISTINCT a.account_id) as account_count,
        SUM(a.current_balance) as total_balance,
        COUNT(DISTINCT cc.card_id) as credit_card_count,
        COUNT(DISTINCT l.loan_id) as loan_count,
        COUNT(ci.interaction_id) as total_interactions,
        AVG(ci.satisfaction_score) as avg_satisfaction,
        MAX(t.transaction_date) as last_transaction_date,
        COUNT(CASE WHEN t.transaction_date >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY) THEN 1 END) as transactions_last_30_days,
        COUNT(CASE WHEN t.transaction_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY) THEN 1 END) as transactions_last_90_days
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN credit_cards cc ON c.customer_id = cc.customer_id
    LEFT JOIN loans l ON c.customer_id = l.customer_id
    LEFT JOIN customer_interactions ci ON c.customer_id = ci.customer_id
    LEFT JOIN transactions t ON a.account_id = t.account_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.registration_date, c.customer_status
),
churn_risk_assessment AS (
    SELECT 
        *,
        CASE 
            WHEN last_transaction_date < DATE_SUB(CURRENT_DATE, INTERVAL 60 DAY) THEN 3
            WHEN last_transaction_date < DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY) THEN 2
            ELSE 1
        END as inactivity_score,
        CASE 
            WHEN avg_satisfaction < 3.0 THEN 3
            WHEN avg_satisfaction < 4.0 THEN 2
            ELSE 1
        END as satisfaction_score,
        CASE 
            WHEN total_balance < 1000 THEN 3
            WHEN total_balance < 10000 THEN 2
            ELSE 1
        END as balance_score,
        CASE 
            WHEN transactions_last_30_days = 0 THEN 3
            WHEN transactions_last_30_days < 5 THEN 2
            ELSE 1
        END as activity_score
    FROM customer_activity
)
SELECT 
    customer_id,
    first_name,
    last_name,
    customer_status,
    days_since_registration,
    total_balance,
    account_count,
    credit_card_count,
    loan_count,
    transactions_last_30_days,
    transactions_last_90_days,
    ROUND(avg_satisfaction, 2) as avg_satisfaction,
    (inactivity_score + satisfaction_score + balance_score + activity_score) as churn_risk_score,
    CASE 
        WHEN (inactivity_score + satisfaction_score + balance_score + activity_score) >= 10 THEN 'High Risk'
        WHEN (inactivity_score + satisfaction_score + balance_score + activity_score) >= 7 THEN 'Medium Risk'
        WHEN (inactivity_score + satisfaction_score + balance_score + activity_score) >= 5 THEN 'Low Risk'
        ELSE 'Very Low Risk'
    END as churn_risk_level
FROM churn_risk_assessment
WHERE customer_status = 'Active'
ORDER BY churn_risk_score DESC;

-- ================================================
-- 7. REVENUE ANALYSIS BY PRODUCT AND REGION
-- ================================================

-- Revenue Generation Analysis by Product Type and Geographic Region
WITH revenue_analysis AS (
    SELECT 
        b.state,
        b.city,
        a.account_type,
        COUNT(DISTINCT a.customer_id) as unique_customers,
        COUNT(a.account_id) as total_accounts,
        SUM(a.current_balance) as total_deposits,
        SUM(a.current_balance * a.interest_rate) as annual_interest_expense,
        -- Credit card revenue
        COUNT(DISTINCT cc.card_id) as credit_cards_issued,
        SUM(cc.current_balance * cc.interest_rate) as cc_interest_revenue,
        -- Loan revenue
        COUNT(DISTINCT l.loan_id) as loans_issued,
        SUM(l.outstanding_balance * l.interest_rate) as loan_interest_revenue,
        -- Total estimated revenue
        SUM(cc.current_balance * cc.interest_rate) + SUM(l.outstanding_balance * l.interest_rate) - SUM(a.current_balance * a.interest_rate) as net_interest_revenue
    FROM accounts a
    JOIN customers c ON a.customer_id = c.customer_id
    JOIN branches b ON a.branch_id = b.branch_id
    LEFT JOIN credit_cards cc ON c.customer_id = cc.customer_id
    LEFT JOIN loans l ON c.customer_id = l.customer_id
    GROUP BY b.state, b.city, a.account_type
)
SELECT 
    state,
    city,
    account_type,
    unique_customers,
    total_accounts,
    total_deposits,
    credit_cards_issued,
    loans_issued,
    ROUND(cc_interest_revenue, 2) as credit_card_revenue,
    ROUND(loan_interest_revenue, 2) as loan_revenue,
    ROUND(annual_interest_expense, 2) as deposit_interest_expense,
    ROUND(net_interest_revenue, 2) as net_interest_income,
    ROUND(net_interest_revenue / unique_customers, 2) as revenue_per_customer
FROM revenue_analysis
WHERE net_interest_revenue > 0
ORDER BY net_interest_income DESC;

-- ================================================
-- 8. CUSTOMER SERVICE PERFORMANCE METRICS
-- ================================================

-- Customer Service Efficiency and Satisfaction Analysis
WITH service_metrics AS (
    SELECT 
        ci.agent_id,
        ci.channel,
        ci.issue_category,
        COUNT(*) as total_interactions,
        AVG(ci.duration_minutes) as avg_duration,
        AVG(ci.satisfaction_score) as avg_satisfaction,
        COUNT(CASE WHEN ci.resolution_status = 'Resolved' THEN 1 END) as resolved_count,
        COUNT(CASE WHEN ci.resolution_status = 'Escalated' THEN 1 END) as escalated_count,
        COUNT(CASE WHEN ci.resolution_status = 'Pending' THEN 1 END) as pending_count,
        ROUND(COUNT(CASE WHEN ci.resolution_status = 'Resolved' THEN 1 END) * 100.0 / COUNT(*), 2) as resolution_rate,
        ROUND(COUNT(CASE WHEN ci.resolution_status = 'Escalated' THEN 1 END) * 100.0 / COUNT(*), 2) as escalation_rate
    FROM customer_interactions ci
    GROUP BY ci.agent_id, ci.channel, ci.issue_category
),
channel_performance AS (
    SELECT 
        channel,
        COUNT(*) as total_interactions,
        AVG(duration_minutes) as avg_duration,
        AVG(satisfaction_score) as avg_satisfaction,
        AVG(resolution_rate) as avg_resolution_rate,
        COUNT(DISTINCT agent_id) as active_agents
    FROM service_metrics
    GROUP BY channel
)
SELECT 
    channel,
    total_interactions,
    ROUND(avg_duration, 2) as avg_duration_minutes,
    ROUND(avg_satisfaction, 2) as avg_satisfaction_score,
    ROUND(avg_resolution_rate, 2) as avg_resolution_rate_pct,
    active_agents,
    ROUND(total_interactions / active_agents, 2) as interactions_per_agent,
    CASE 
        WHEN avg_satisfaction >= 4.5 AND avg_resolution_rate >= 85 THEN 'Excellent'
        WHEN avg_satisfaction >= 4.0 AND avg_resolution_rate >= 75 THEN 'Good'
        WHEN avg_satisfaction >= 3.5 AND avg_resolution_rate >= 65 THEN 'Average'
        ELSE 'Needs Improvement'
    END as performance_rating
FROM channel_performance
ORDER BY avg_satisfaction DESC;

-- ================================================
-- 9. ADVANCED COHORT ANALYSIS
-- ================================================

-- Customer Cohort Analysis based on Registration Date
WITH monthly_cohorts AS (
    SELECT 
        customer_id,
        DATE_FORMAT(registration_date, '%Y-%m') as cohort_month,
        registration_date
    FROM customers
),
customer_activities AS (
    SELECT 
        mc.customer_id,
        mc.cohort_month,
        DATE_FORMAT(t.transaction_date, '%Y-%m') as activity_month,
        COUNT(*) as transaction_count,
        SUM(ABS(t.amount)) as total_transaction_value
    FROM monthly_cohorts mc
    JOIN accounts a ON mc.customer_id = a.customer_id
    JOIN transactions t ON a.account_id = t.account_id
    GROUP BY mc.customer_id, mc.cohort_month, DATE_FORMAT(t.transaction_date, '%Y-%m')
),
cohort_data AS (
    SELECT 
        cohort_month,
        activity_month,
        COUNT(DISTINCT customer_id) as active_customers,
        SUM(transaction_count) as total_transactions,
        SUM(total_transaction_value) as total_value,
        PERIOD_DIFF(REPLACE(activity_month, '-', ''), REPLACE(cohort_month, '-', '')) as period_number
    FROM customer_activities
    GROUP BY cohort_month, activity_month
),
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) as cohort_size
    FROM monthly_cohorts
    GROUP BY cohort_month
)
SELECT 
    cd.cohort_month,
    cs.cohort_size,
    cd.period_number,
    cd.activity_month,
    cd.active_customers,
    ROUND(cd.active_customers * 100.0 / cs.cohort_size, 2) as retention_rate,
    cd.total_transactions,
    ROUND(cd.total_value, 2) as total_transaction_value,
    ROUND(cd.total_value / cd.active_customers, 2) as avg_value_per_customer
FROM cohort_data cd
JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
WHERE cd.period_number >= 0
ORDER BY cd.cohort_month, cd.period_number;

-- ================================================
-- 10. PROFITABILITY ANALYSIS BY CUSTOMER SEGMENT
-- ================================================

-- Customer Profitability Analysis with Lifetime Value Calculation
WITH customer_profitability AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.annual_income,
        c.credit_score,
        c.risk_category,
        DATEDIFF(CURRENT_DATE, c.registration_date) as customer_age_days,
        
        -- Account balances and interest expense
        SUM(a.current_balance) as total_deposits,
        SUM(a.current_balance * a.interest_rate) as annual_interest_expense,
        
        -- Credit card revenue
        SUM(cc.current_balance * cc.interest_rate) as cc_annual_revenue,
        
        -- Loan revenue
        SUM(l.outstanding_balance * l.interest_rate) as loan_annual_revenue,
        
        -- Transaction volume (proxy for fee revenue)
        COUNT(t.transaction_id) as total_transactions,
        SUM(ABS(t.amount)) as total_transaction_volume,
        
        -- Service costs (proxy based on interactions)
        COUNT(ci.interaction_id) as total_service_interactions,
        COUNT(ci.interaction_id) * 25 as estimated_service_cost, -- $25 per interaction
        
        -- Net revenue calculation
        (SUM(cc.current_balance * cc.interest_rate) + SUM(l.outstanding_balance * l.interest_rate) + 
         COUNT(t.transaction_id) * 2 - SUM(a.current_balance * a.interest_rate) - COUNT(ci.interaction_id) * 25) as net_annual_revenue
        
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN credit_cards cc ON c.customer_id = cc.customer_id
    LEFT JOIN loans l ON c.customer_id = l.customer_id
    LEFT JOIN transactions t ON a.account_id = t.account_id
    LEFT JOIN customer_interactions ci ON c.customer_id = ci.customer_id
    WHERE c.customer_status = 'Active'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.annual_income, c.credit_score, c.risk_category, c.registration_date
),
profitability_segments AS (
    SELECT 
        *,
        ROUND(net_annual_revenue, 2) as net_revenue,
        ROUND(net_annual_revenue / (customer_age_days / 365.0), 2) as revenue_per_year,
        ROUND(net_annual_revenue * 5, 2) as estimated_lifetime_value, -- 5-year projection
        CASE 
            WHEN net_annual_revenue > 1000 THEN 'High Profit'
            WHEN net_annual_revenue > 500 THEN 'Medium Profit'
            WHEN net_annual_revenue > 0 THEN 'Low Profit'
            ELSE 'Unprofitable'
        END as profitability_segment
    FROM customer_profitability
)
SELECT 
    profitability_segment,
    risk_category,
    COUNT(*) as customer_count,
    AVG(annual_income) as avg_annual_income,
    AVG(credit_score) as avg_credit_score,
    AVG(total_deposits) as avg_total_deposits,
    AVG(total_transactions) as avg_transactions,
    AVG(net_revenue) as avg_net_revenue,
    AVG(estimated_lifetime_value) as avg_lifetime_value,
    SUM(net_revenue) as total_segment_revenue,
    ROUND(AVG(net_revenue) / AVG(total_deposits) * 100, 2) as revenue_on_deposits_pct
FROM profitability_segments
GROUP BY profitability_segment, risk_category
ORDER BY profitability_segment, risk_category;

-- ================================================
-- 11. COMPETITIVE ANALYSIS & BENCHMARKING
-- ================================================

-- Internal Performance Benchmarking
WITH performance_benchmarks AS (
    SELECT 
        'Credit Card Utilization' as metric,
        AVG(cc.current_balance / cc.credit_limit * 100) as current_value,
        45.0 as industry_benchmark,
        'Lower is Better' as direction
    FROM credit_cards cc
    WHERE cc.card_status = 'Active'
    
    UNION ALL
    
    SELECT 
        'Average Customer Satisfaction' as metric,
        AVG(ci.satisfaction_score) as current_value,
        4.2 as industry_benchmark,
        'Higher is Better' as direction
    FROM customer_interactions ci
    
    UNION ALL
    
    SELECT 
        'Loan Default Rate' as metric,
        COUNT(CASE WHEN l.loan_status = 'Defaulted' THEN 1 END) * 100.0 / COUNT(*) as current_value,
        3.5 as industry_benchmark,
        'Lower is Better' as direction
    FROM loans l
    
    UNION ALL
    
    SELECT 
        'Customer Service Resolution Rate' as metric,
        COUNT(CASE WHEN ci.resolution_status = 'Resolved' THEN 1 END) * 100.0 / COUNT(*) as current_value,
        85.0 as industry_benchmark,
        'Higher is Better' as direction
    FROM customer_interactions ci
    
    UNION ALL
    
    SELECT 
        'Average Account Balance' as metric,
        AVG(a.current_balance) as current_value,
        15000.0 as industry_benchmark,
        'Higher is Better' as direction
    FROM accounts a
    WHERE a.account_status = 'Active'
)
SELECT 
    metric,
    ROUND(current_value, 2) as current_performance,
    industry_benchmark,
    direction,
    ROUND(current_value - industry_benchmark, 2) as variance,
    CASE 
        WHEN direction = 'Higher is Better' AND current_value > industry_benchmark THEN 'Above Benchmark'
        WHEN direction = 'Lower is Better' AND current_value < industry_benchmark THEN 'Above Benchmark'
        WHEN direction = 'Higher is Better' AND current_value < industry_benchmark THEN 'Below Benchmark'
        WHEN direction = 'Lower is Better' AND current_value > industry_benchmark THEN 'Below Benchmark'
        ELSE 'At Benchmark'
    END as performance_status
FROM performance_benchmarks
ORDER BY metric;
        