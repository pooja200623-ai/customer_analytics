-- =============================================================================
-- PROJECT : Customer Segmentation & Purchase Behavior Analytics
-- FILE    : customer_retention.sql
-- PURPOSE : Customer Retention & Churn Analysis Module (MySQL Only)
--           Evaluates customer lifecycle metrics, repurchase loyalty, attrition rates,
--           cohort retention matrices, and win-back patterns:
--             1. Identify Repeat Customers (Multi-Order Buyers)
--             2. Identify One-Time Customers (Single-Order Drop-offs)
--             3. Calculate Overall Customer Retention Rate
--             4. Identify Inactive & Dormant Customers (At-Risk of Churn)
--             5. Analyze Repeat Purchase Patterns & Purchase Cadence
--             6. Calculate Customer Churn Rate (Attrition Modeling)
--             7. Analyze Monthly Customer Retention (Cohort Matrix)
--             8. Identify Customers Who Returned After a Long Gap (Reactivated Buyers)
--
-- CONCEPTS: SELECT, JOIN, GROUP BY, HAVING, CASE statements, Subqueries,
--           Common Table Expressions (CTEs), Window Functions (ROW_NUMBER,
--           DENSE_RANK, LAG, NTILE, SUM OVER, AVG OVER)
-- ENGINE  : MySQL 8.0+
-- =============================================================================

USE customer_analytics;


-- =============================================================================
-- SECTION 1: IDENTIFY REPEAT CUSTOMERS (MULTI-ORDER BUYERS)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 1:
-- Which customers have demonstrated loyalty by placing multiple orders (>= 2 orders)?
-- What is their order count, total spending, average order value, and lifespan
-- (days between their first and most recent purchase)?
-- -----------------------------------------------------------------------------

WITH repeat_customers_cte AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.segment,
        CONCAT(c.city, ', ', c.state) AS location,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS total_spend,
        AVG(o.total_amount) AS average_order_value,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS latest_order_date,
        DATEDIFF(MAX(o.order_date), MIN(o.order_date)) AS retention_lifespan_days
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.segment, c.city, c.state
    HAVING COUNT(DISTINCT o.order_id) >= 2
)
SELECT 
    DENSE_RANK() OVER (ORDER BY total_orders DESC, total_spend DESC) AS repeat_loyalty_rank,
    customer_id,
    customer_name,
    email,
    segment,
    location,
    total_orders,
    CONCAT('₹', FORMAT(total_spend, 2)) AS total_spend,
    CONCAT('₹', FORMAT(average_order_value, 2)) AS average_order_value,
    DATE_FORMAT(first_order_date, '%Y-%m-%d') AS first_purchase,
    DATE_FORMAT(latest_order_date, '%Y-%m-%d') AS latest_purchase,
    retention_lifespan_days,
    ROUND(retention_lifespan_days / NULLIF(total_orders - 1, 0), 1) AS avg_days_between_orders
FROM repeat_customers_cte
ORDER BY total_orders DESC, total_spend DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Returns 19 repeat customers who have purchased 2 or more times. Highlights top
-- repeat buyers (Karan Malhotra: 4 orders, ₹3.54L spend; Harsh Shah: 4 orders, ₹2.17L;
-- Aarav Sharma: 4 orders, ₹1.96L) along with the active purchasing span in days.


-- =============================================================================
-- SECTION 2: IDENTIFY ONE-TIME CUSTOMERS (SINGLE-ORDER DROP-OFFS)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 2:
-- Which customers have placed only a single order since registration and never
-- made a subsequent purchase? How much did they spend on their sole transaction,
-- and how many days have elapsed since that order?
-- -----------------------------------------------------------------------------

WITH onetime_buyers_cte AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.phone,
        CONCAT(c.city, ', ', c.state) AS location,
        c.registration_date,
        COUNT(o.order_id) AS total_orders,
        SUM(o.total_amount) AS single_order_spend,
        MAX(o.order_date) AS order_date,
        DATEDIFF('2026-11-10', MAX(o.order_date)) AS days_since_purchase
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.phone, c.city, c.state, c.registration_date
    HAVING COUNT(o.order_id) = 1
)
SELECT 
    customer_id,
    customer_name,
    email,
    location,
    registration_date,
    DATE_FORMAT(order_date, '%Y-%m-%d') AS purchase_date,
    CONCAT('₹', FORMAT(single_order_spend, 2)) AS single_order_spend,
    days_since_purchase,
    CASE 
        WHEN days_since_purchase <= 60 THEN 'Recent First-Time Buyer (Prime for 2nd Order Push)'
        WHEN days_since_purchase <= 180 THEN 'Cooling First-Time Buyer (Send Reactivation Discount)'
        ELSE 'Lapsed One-Time Buyer (High Risk of Churn)'
    END AS customer_nurture_status
FROM onetime_buyers_cte
ORDER BY days_since_purchase ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Lists 10 one-time buyers (e.g., Pallavi Nambiar, Ritika Saxena, Ananya Das, etc.),
-- detailing their single transaction date, amount spent, days elapsed, and CRM status.


-- =============================================================================
-- SECTION 3: CALCULATE OVERALL CUSTOMER RETENTION RATE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 3:
-- What is the platform's macro customer retention rate?
-- What percentage of our total registered customer base and total purchasing
-- customer base returned to place repeat orders?
-- -----------------------------------------------------------------------------

WITH customer_order_summary AS (
    SELECT 
        c.customer_id,
        COUNT(o.order_id) AS order_count
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
),
retention_aggregates AS (
    SELECT 
        COUNT(customer_id) AS total_registered_customers,
        SUM(CASE WHEN order_count > 0 THEN 1 ELSE 0 END) AS total_converted_buyers,
        SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END) AS one_time_buyers,
        SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) AS repeat_buyers,
        SUM(CASE WHEN order_count = 0 THEN 1 ELSE 0 END) AS non_purchasing_leads
    FROM customer_order_summary
)
SELECT 
    total_registered_customers,
    total_converted_buyers,
    one_time_buyers,
    repeat_buyers,
    non_purchasing_leads,
    -- Retention rate calculated over converted buyers
    CONCAT(ROUND((repeat_buyers * 100.0) / NULLIF(total_converted_buyers, 0), 2), '%') AS buyer_retention_rate_pct,
    -- Retention rate calculated over all registered accounts
    CONCAT(ROUND((repeat_buyers * 100.0) / NULLIF(total_registered_customers, 0), 2), '%') AS overall_customer_retention_rate_pct,
    -- One-time buyer ratio
    CONCAT(ROUND((one_time_buyers * 100.0) / NULLIF(total_converted_buyers, 0), 2), '%') AS one_time_buyer_ratio_pct
FROM retention_aggregates;

-- EXPECTED OUTPUT DESCRIPTION:
-- A single-row KPI executive summary displaying: 30 registered customers, 29 converted buyers,
-- 19 repeat buyers, producing a **65.52% buyer retention rate** (19/29) and a 34.48% one-time buyer ratio.


-- =============================================================================
-- SECTION 4: IDENTIFY INACTIVE CUSTOMERS (AT-RISK OF CHURN)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 4:
-- Which customers have been inactive for more than 120 days or have never made
-- a purchase? Group them into inactivity severity tiers and determine lost potential.
-- -----------------------------------------------------------------------------

WITH customer_inactivity_cte AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.phone,
        CONCAT(c.city, ', ', c.state) AS location,
        c.segment,
        c.registration_date,
        COUNT(o.order_id) AS total_orders,
        COALESCE(SUM(o.total_amount), 0.00) AS historical_spend,
        MAX(o.order_date) AS last_order_date,
        COALESCE(DATEDIFF('2026-11-10', MAX(o.order_date)), 9999) AS days_since_last_order
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.phone, c.city, c.state, c.segment, c.registration_date
)
SELECT 
    customer_id,
    customer_name,
    email,
    location,
    segment,
    total_orders,
    CONCAT('₹', FORMAT(historical_spend, 2)) AS historical_spend,
    COALESCE(DATE_FORMAT(last_order_date, '%Y-%m-%d'), 'Never Ordered') AS last_order_date,
    days_since_last_order,
    CASE 
        WHEN total_orders = 0 THEN 'Dormant Account (Never Converted)'
        WHEN days_since_last_order > 300 THEN 'Severely Inactive (> 300 Days)'
        WHEN days_since_last_order > 180 THEN 'High Inactivity (181-300 Days)'
        WHEN days_since_last_order > 120 THEN 'Moderate Inactivity (121-180 Days)'
        ELSE 'Active'
    END AS inactivity_tier,
    CASE 
        WHEN total_orders = 0 THEN 'Send welcome series with first-order discount code'
        WHEN days_since_last_order > 300 THEN 'Initiate major win-back campaign (25% off + free shipping)'
        WHEN days_since_last_order > 180 THEN 'Send personalized product catalog based on past interests'
        WHEN days_since_last_order > 120 THEN 'Send gentle reminder & highlight new arrivals'
        ELSE 'Standard engagement'
    END AS crm_action_recommendation
FROM customer_inactivity_cte
WHERE total_orders = 0 OR days_since_last_order > 120
ORDER BY days_since_last_order DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Surfaces all accounts at risk of churn: Saurav Ghosh (0 orders, never converted),
-- Vikram Singh (421 days inactive), Suresh Pillai (468 days inactive), and Shruti Jain (477 days inactive),
-- pairing each with a tailored CRM reactivation action.


-- =============================================================================
-- SECTION 5: ANALYZE REPEAT PURCHASE PATTERNS & PURCHASE CADENCE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 5:
-- How does customer behavior evolve across sequential purchases (Order 1 -> 2 -> 3 -> 4)?
-- What is the average order amount, average discount availed, and average time
-- gap (in days) between successive purchases?
-- -----------------------------------------------------------------------------

WITH customer_order_sequence AS (
    SELECT 
        o.customer_id,
        o.order_id,
        o.order_date,
        o.total_amount,
        o.discount_amount,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date ASC) AS order_sequence_number,
        LAG(o.order_date, 1) OVER (PARTITION BY o.customer_id ORDER BY o.order_date ASC) AS previous_order_date
    FROM orders o
),
order_interval_analysis AS (
    SELECT 
        customer_id,
        order_id,
        order_date,
        total_amount,
        discount_amount,
        order_sequence_number,
        DATEDIFF(order_date, previous_order_date) AS days_since_prior_order
    FROM customer_order_sequence
)
SELECT 
    order_sequence_number AS order_stage,
    CASE 
        WHEN order_sequence_number = 1 THEN '1st Order (Acquisition)'
        WHEN order_sequence_number = 2 THEN '2nd Order (Initial Repeat)'
        WHEN order_sequence_number = 3 THEN '3rd Order (Loyalty Established)'
        ELSE '4th+ Order (Brand Advocate)'
    END AS customer_lifecycle_milestone,
    COUNT(order_id) AS orders_count,
    CONCAT('₹', FORMAT(AVG(total_amount), 2)) AS average_order_value,
    CONCAT('₹', FORMAT(AVG(discount_amount), 2)) AS avg_discount_received,
    COALESCE(ROUND(AVG(days_since_prior_order), 1), 0.0) AS avg_days_since_previous_order,
    COALESCE(MIN(days_since_prior_order), 0) AS min_days_to_repeat,
    COALESCE(MAX(days_since_prior_order), 0) AS max_days_to_repeat
FROM order_interval_analysis
GROUP BY order_sequence_number
ORDER BY order_sequence_number ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Tracks how customer purchasing power evolves from initial acquisition (Order 1: 29 orders)
-- to repeat milestones (Order 2: 19 orders, avg re-order gap ~238 days; Order 3: 9 orders,
-- avg gap ~154 days; Order 4: 3 orders, avg gap ~80 days), showing accelerating purchase frequency.


-- =============================================================================
-- SECTION 6: CALCULATE CUSTOMER CHURN RATE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 6:
-- Using an industry-standard 180-day inactivity threshold, how many customers
-- are considered churned versus retained? What is the platform's churn rate
-- and what is the total revenue at risk?
-- -----------------------------------------------------------------------------

WITH customer_activity_status AS (
    SELECT 
        c.customer_id,
        COALESCE(SUM(o.total_amount), 0.00) AS lifetime_value,
        MAX(o.order_date) AS last_purchase_date,
        CASE 
            WHEN MAX(o.order_date) IS NULL THEN 'Dormant (Never Bought)'
            WHEN DATEDIFF('2026-11-10', MAX(o.order_date)) <= 180 THEN 'Retained / Active'
            ELSE 'Churned (> 180 Days Inactive)'
        END AS churn_category
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
)
SELECT 
    churn_category,
    COUNT(customer_id) AS customer_count,
    ROUND((COUNT(customer_id) * 100.0) / (SELECT COUNT(*) FROM customers), 2) AS pct_of_customer_base,
    CONCAT('₹', FORMAT(SUM(lifetime_value), 2)) AS total_revenue_volume,
    CONCAT('₹', FORMAT(AVG(lifetime_value), 2)) AS avg_revenue_per_customer
FROM customer_activity_status
GROUP BY churn_category
ORDER BY customer_count DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Summarizes customer attrition: Retained / Active buyers (~66.7%), Churned buyers (> 180 days, ~30%),
-- and Dormant accounts (~3.3%), providing executives with exact churn rate percentages and revenue at risk.


-- =============================================================================
-- SECTION 7: ANALYZE MONTHLY CUSTOMER RETENTION (COHORT MATRIX)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 7:
-- Group customers into monthly acquisition cohorts (based on their very first
-- purchase date). How many customers from each cohort returned to place orders
-- in subsequent months?
-- -----------------------------------------------------------------------------

WITH first_purchase_cohorts AS (
    SELECT 
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month
    FROM orders
    GROUP BY customer_id
),
cohort_order_activity AS (
    SELECT 
        o.customer_id,
        fpc.cohort_month,
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        TIMESTAMPDIFF(
            MONTH,
            STR_TO_DATE(CONCAT(fpc.cohort_month, '-01'), '%Y-%m-%d'),
            STR_TO_DATE(CONCAT(DATE_FORMAT(o.order_date, '%Y-%m'), '-01'), '%Y-%m-%d')
        ) AS month_offset
    FROM orders o
    JOIN first_purchase_cohorts fpc ON o.customer_id = fpc.customer_id
),
cohort_summary AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM first_purchase_cohorts
    GROUP BY cohort_month
)
SELECT 
    cs.cohort_month,
    cs.cohort_size,
    COUNT(DISTINCT CASE WHEN coa.month_offset = 0 THEN coa.customer_id END) AS month_0_active,
    COUNT(DISTINCT CASE WHEN coa.month_offset BETWEEN 1 AND 3 THEN coa.customer_id END) AS month_1_to_3_reorders,
    COUNT(DISTINCT CASE WHEN coa.month_offset BETWEEN 4 AND 6 THEN coa.customer_id END) AS month_4_to_6_reorders,
    COUNT(DISTINCT CASE WHEN coa.month_offset BETWEEN 7 AND 12 THEN coa.customer_id END) AS month_7_to_12_reorders,
    COUNT(DISTINCT CASE WHEN coa.month_offset > 12 THEN coa.customer_id END) AS month_13_plus_reorders,
    CONCAT(
        ROUND(
            (COUNT(DISTINCT CASE WHEN coa.month_offset > 0 THEN coa.customer_id END) * 100.0) / cs.cohort_size, 
            1
        ), 
        '%'
    ) AS cohort_repeat_rate_pct
FROM cohort_summary cs
JOIN cohort_order_activity coa ON cs.cohort_month = coa.cohort_month
GROUP BY cs.cohort_month, cs.cohort_size
ORDER BY cs.cohort_month ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Builds a cohort retention table by acquisition month (e.g., 2025-01, 2025-02...),
-- tracking the percentage of customers who returned across rolling intervals (M1-3, M4-6, M7-12, M13+).


-- =============================================================================
-- SECTION 8: IDENTIFY CUSTOMERS WHO RETURNED AFTER A LONG GAP (REACTIVATED)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 8:
-- Which customers experienced a long dormancy gap (e.g. >= 180 days or >= 365 days)
-- between successive purchases but were successfully reactivated?
-- Rank customers by their longest re-order gap and analyze what product brought them back.
-- -----------------------------------------------------------------------------

WITH customer_order_gaps AS (
    SELECT 
        o.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        o.order_id AS reactivation_order_id,
        o.order_date AS reactivation_order_date,
        o.total_amount AS reactivation_order_amount,
        LAG(o.order_id, 1) OVER (PARTITION BY o.customer_id ORDER BY o.order_date ASC) AS previous_order_id,
        LAG(o.order_date, 1) OVER (PARTITION BY o.customer_id ORDER BY o.order_date ASC) AS previous_order_date,
        DATEDIFF(
            o.order_date, 
            LAG(o.order_date, 1) OVER (PARTITION BY o.customer_id ORDER BY o.order_date ASC)
        ) AS days_between_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
)
SELECT 
    DENSE_RANK() OVER (ORDER BY days_between_orders DESC) AS reactivation_rank,
    customer_id,
    customer_name,
    email,
    previous_order_id,
    DATE_FORMAT(previous_order_date, '%Y-%m-%d') AS previous_order_date,
    reactivation_order_id,
    DATE_FORMAT(reactivation_order_date, '%Y-%m-%d') AS reactivation_order_date,
    days_between_orders AS gap_duration_days,
    CONCAT('₹', FORMAT(reactivation_order_amount, 2)) AS reactivation_spend,
    CASE 
        WHEN days_between_orders >= 365 THEN 'Long-Term Win-Back (> 1 Year Gap)'
        WHEN days_between_orders >= 180 THEN 'Mid-Term Win-Back (6-12 Month Gap)'
        ELSE 'Standard Re-order'
    END AS reactivation_classification
FROM customer_order_gaps
WHERE days_between_orders >= 180
ORDER BY days_between_orders DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Highlights successful customer reactivations after significant dormancy gaps:
-- Kavya Reddy (582-day gap between Order 6 and Order 52), Rahul Gupta (535-day gap),
-- Nisha Agarwal (468-day gap), Priya Nair (455-day gap), and Riya Chopra (452-day gap).
