-- =============================================================================
-- PROJECT : Customer Segmentation & Purchase Behavior Analytics
-- SCRIPT  : 04_customer_retention.sql
-- PURPOSE : Customer retention rates, monthly cohort retention analysis, churn risk
--           detection, repeat purchase loyalty, and customer lifetime value (LTV).
-- CONCEPTS: Cohort Analysis, Window Functions (MIN OVER, DATEDIFF, ROW_NUMBER),
--           Complex CTEs, Conditional Pivoting with CASE, Churn Scoring.
-- ENGINE  : MySQL 8.0+
-- =============================================================================

USE customer_analytics;

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 1: Cohort Analysis - Monthly Customer Retention
-- -----------------------------------------------------------------------------
-- When grouping customers into cohorts based on their registration quarter/month,
-- what percentage of each cohort returned to place orders in subsequent months?
-- -----------------------------------------------------------------------------

WITH customer_first_purchase AS (
    SELECT 
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month
    FROM orders
    WHERE status != 'Cancelled'
    GROUP BY customer_id
),
customer_activities AS (
    SELECT 
        o.customer_id,
        cfp.cohort_month,
        DATE_FORMAT(o.order_date, '%Y-%m') AS activity_month,
        TIMESTAMPDIFF(MONTH, STR_TO_DATE(CONCAT(cfp.cohort_month, '-01'), '%Y-%m-%d'), STR_TO_DATE(CONCAT(DATE_FORMAT(o.order_date, '%Y-%m'), '-01'), '%Y-%m-%d')) AS month_number
    FROM orders o
    JOIN customer_first_purchase cfp ON o.customer_id = cfp.customer_id
    WHERE o.status != 'Cancelled'
),
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_first_purchase
    GROUP BY cohort_month
),
retention_matrix AS (
    SELECT 
        ca.cohort_month,
        cs.cohort_size,
        COUNT(DISTINCT CASE WHEN ca.month_number = 0 THEN ca.customer_id END) AS month_0,
        COUNT(DISTINCT CASE WHEN ca.month_number BETWEEN 1 AND 3 THEN ca.customer_id END) AS months_1_to_3,
        COUNT(DISTINCT CASE WHEN ca.month_number BETWEEN 4 AND 6 THEN ca.customer_id END) AS months_4_to_6,
        COUNT(DISTINCT CASE WHEN ca.month_number BETWEEN 7 AND 12 THEN ca.customer_id END) AS months_7_to_12,
        COUNT(DISTINCT CASE WHEN ca.month_number > 12 THEN ca.customer_id END) AS months_13_plus
    FROM customer_activities ca
    JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
    GROUP BY ca.cohort_month, cs.cohort_size
)
SELECT 
    cohort_month,
    cohort_size,
    month_0 AS active_m0,
    months_1_to_3 AS reordered_m1_m3,
    CONCAT(ROUND((months_1_to_3 * 100.0) / cohort_size, 1), '%') AS retention_rate_m1_m3,
    months_4_to_6 AS reordered_m4_m6,
    CONCAT(ROUND((months_4_to_6 * 100.0) / cohort_size, 1), '%') AS retention_rate_m4_m6,
    months_7_to_12 AS reordered_m7_m12,
    months_13_plus AS long_term_repeat_buyers
FROM retention_matrix
ORDER BY cohort_month ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Classical cohort retention grid tracking customer cohorts over time, measuring
-- retention decay and sustained repurchase rates.


-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 2: Churn Risk Identification & Lapsed Customer Detection
-- -----------------------------------------------------------------------------
-- Which customers have not placed an order in over 180 or 365 days?
-- Classify every customer into an operational churn status:
--   - Active & Frequent (< 60 days)
--   - Warming / In Need of Engagement (61-120 days)
--   - At Risk (121-240 days)
--   - Churned / Lapsed (> 240 days or Never Purchased)
-- -----------------------------------------------------------------------------

WITH customer_order_recency AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.segment,
        c.registration_date,
        COUNT(o.order_id) AS total_lifetime_orders,
        COALESCE(SUM(o.total_amount), 0) AS lifetime_spend,
        MAX(o.order_date) AS last_order_date,
        DATEDIFF('2026-11-10', MAX(o.order_date)) AS days_inactive
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.segment, c.registration_date
)
SELECT 
    customer_id,
    customer_name,
    email,
    segment,
    registration_date,
    total_lifetime_orders,
    CONCAT('₹', FORMAT(lifetime_spend, 2)) AS lifetime_spend,
    COALESCE(DATE_FORMAT(last_order_date, '%Y-%m-%d'), 'Never Ordered') AS last_order_date,
    COALESCE(days_inactive, 9999) AS days_since_last_order,
    CASE 
        WHEN days_inactive IS NULL THEN 'Never Purchased (Lead)'
        WHEN days_inactive <= 60 THEN 'Active & Retained'
        WHEN days_inactive <= 120 THEN 'Cooling Down (Send Offer)'
        WHEN days_inactive <= 240 THEN 'At-Risk of Churn'
        ELSE 'Lapsed / High Churn Risk'
    END AS retention_health_status,
    CASE 
        WHEN days_inactive <= 60 THEN 'Maintain standard communication'
        WHEN days_inactive <= 120 THEN 'Send 10% win-back discount voucher'
        WHEN days_inactive <= 240 THEN 'Target with high-intent personalized catalog'
        ELSE 'Initiate deep reactivation campaign or re-classify'
    END AS recommended_crm_action
FROM customer_order_recency
ORDER BY days_since_last_order ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Comprehensive CRM health report providing retention status and clear marketing
-- action triggers for each customer account.


-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 3: One-Time Buyers vs Repeat Loyalists Comparison
-- -----------------------------------------------------------------------------
-- What percentage of our customer base are one-time buyers versus repeat buyers?
-- How much more valuable are repeat buyers compared to single-order customers?
-- -----------------------------------------------------------------------------

WITH buyer_loyalty AS (
    SELECT 
        c.customer_id,
        COUNT(o.order_id) AS orders_count,
        SUM(o.total_amount) AS total_spend,
        AVG(o.total_amount) AS avg_order_val
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
),
buyer_classification AS (
    SELECT 
        customer_id,
        orders_count,
        total_spend,
        avg_order_val,
        CASE 
            WHEN orders_count = 0 THEN '0 Orders (Non-buyers)'
            WHEN orders_count = 1 THEN '1 Order (One-Time Buyers)'
            WHEN orders_count BETWEEN 2 AND 3 THEN '2-3 Orders (Repeat Buyers)'
            ELSE '4+ Orders (Power Loyalists)'
        END AS buyer_tier
    FROM buyer_loyalty
)
SELECT 
    buyer_tier,
    COUNT(customer_id) AS customer_count,
    ROUND((COUNT(customer_id) * 100.0) / (SELECT COUNT(*) FROM customers), 1) AS pct_of_customer_base,
    CONCAT('₹', FORMAT(COALESCE(SUM(total_spend), 0), 2)) AS aggregate_revenue,
    CONCAT('₹', FORMAT(COALESCE(AVG(total_spend), 0), 2)) AS avg_revenue_per_user_arpu,
    CONCAT('₹', FORMAT(COALESCE(AVG(avg_order_val), 0), 2)) AS average_order_value_aov
FROM buyer_classification
GROUP BY buyer_tier
ORDER BY customer_count DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Quantifies the dramatic revenue impact of repeat buyers, showing that customers
-- with 2+ orders drive the lion's share of overall business profitability.
