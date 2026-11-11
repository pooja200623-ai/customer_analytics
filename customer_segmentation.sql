-- =============================================================================
-- PROJECT : Customer Segmentation & Purchase Behavior Analytics
-- FILE    : customer_segmentation.sql
-- PURPOSE : Customer Segmentation Module (MySQL Only)
--           Analyzes customer purchase history and segments the customer base
--           into distinct behavioral cohorts:
--             1. Customer Purchasing History Summary (Total Orders & Total Spend)
--             2. New Customers (Recently acquired / single initial purchase)
--             3. Returning Customers (Multiple purchases across different dates)
--             4. Loyal Customers (High order frequency & repeat buying history)
--             5. High-Value Customers (Top spenders & revenue generators)
--             6. Low-Value Customers (Low basket size / bottom spending tier)
--             7. Inactive Customers (Lapsed accounts / high days since last order)
--             8. Master Comprehensive Multi-Tier Customer Segmentation Matrix
--
-- CONCEPTS: JOIN, GROUP BY, HAVING, CASE statements, Subqueries, CTEs,
--           Window Functions (ROW_NUMBER, DENSE_RANK, NTILE, PERCENT_RANK, AVG OVER)
-- ENGINE  : MySQL 8.0+
-- =============================================================================

USE customer_analytics;


-- =============================================================================
-- SECTION 1: CUSTOMER PURCHASING HISTORY (TOTAL ORDERS & TOTAL SPENDING)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 1:
-- How can we aggregate the complete purchasing history for every customer,
-- calculating their total orders placed, total monetary spend, average order value
-- (AOV), first purchase date, and most recent purchase date?
-- -----------------------------------------------------------------------------

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    c.city,
    c.state,
    c.registration_date,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0.00) AS total_spend_numeric,
    CONCAT('₹', FORMAT(COALESCE(SUM(o.total_amount), 0.00), 2)) AS total_spend_formatted,
    CONCAT('₹', FORMAT(COALESCE(AVG(o.total_amount), 0.00), 2)) AS average_order_value,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date,
    COALESCE(DATEDIFF('2026-11-10', MAX(o.order_date)), 9999) AS days_since_last_order
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY 
    c.customer_id, 
    c.first_name, 
    c.last_name, 
    c.email, 
    c.city, 
    c.state, 
    c.registration_date
ORDER BY total_spend_numeric DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- A comprehensive summary table containing all 30 customers ranked by lifetime spend.
-- For each customer, it reveals order counts (ranging from 1 to 4 orders), cumulative
-- revenue (e.g. Karan Malhotra at ₹3,54,847.00, Varun Kapoor at ₹2,41,889.00),
-- their average order value, and recency in days.


-- =============================================================================
-- SECTION 2: IDENTIFY NEW CUSTOMERS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 2:
-- Which customers are classified as "New Customers" based on having placed
-- exactly 1 order or having registered within the recent onboarding cycle?
-- How much revenue did their first order contribute?
-- -----------------------------------------------------------------------------

-- Using CTE and Subquery with HAVING:
WITH customer_order_counts AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.registration_date,
        COUNT(o.order_id) AS lifetime_orders,
        SUM(o.total_amount) AS total_spend,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS latest_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.registration_date
    HAVING COUNT(o.order_id) = 1
)
SELECT 
    coc.customer_id,
    coc.customer_name,
    coc.email,
    coc.registration_date,
    coc.first_order_date AS initial_purchase_date,
    CONCAT('₹', FORMAT(coc.total_spend, 2)) AS first_order_value,
    DATEDIFF('2026-11-10', coc.latest_order_date) AS days_since_initial_purchase,
    'New Customer (1 Order Placed)' AS customer_cohort,
    CASE 
        WHEN DATEDIFF('2026-11-10', coc.latest_order_date) <= 30 THEN 'Fresh Onboarding (< 30 days)'
        WHEN DATEDIFF('2026-11-10', coc.latest_order_date) <= 90 THEN 'Recent Buyer (30-90 days)'
        ELSE 'Single Buyer Requiring Nudge (> 90 days)'
    END AS onboarding_status
FROM customer_order_counts coc
ORDER BY coc.first_order_date DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Lists all one-time buyers (e.g. Pallavi Nambiar, Ananya Das, Ritika Saxena, etc.),
-- their single purchase date, and ticket size. Allows CRM marketing teams to deploy
-- personalized second-order incentive campaigns.


-- =============================================================================
-- SECTION 3: IDENTIFY RETURNING CUSTOMERS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 3:
-- Which customers have transitioned from first-time buyers into "Returning Customers"
-- by placing multiple orders (2 or more orders) across different dates?
-- What is their return velocity (days between first and most recent order)?
-- -----------------------------------------------------------------------------

-- Using CTE and Window Functions:
WITH customer_repeat_orders AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.city,
        c.state,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS total_revenue,
        AVG(o.total_amount) AS aov,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS latest_order_date,
        DATEDIFF(MAX(o.order_date), MIN(o.order_date)) AS customer_lifespan_days
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.city, c.state
    HAVING COUNT(DISTINCT o.order_id) >= 2
)
SELECT 
    customer_id,
    customer_name,
    email,
    CONCAT(city, ', ', state) AS location,
    total_orders,
    CONCAT('₹', FORMAT(total_revenue, 2)) AS cumulative_revenue,
    CONCAT('₹', FORMAT(aov, 2)) AS avg_order_value,
    DATE_FORMAT(first_order_date, '%Y-%m-%d') AS first_purchase,
    DATE_FORMAT(latest_order_date, '%Y-%m-%d') AS latest_purchase,
    customer_lifespan_days AS days_between_first_and_latest_order,
    ROUND(customer_lifespan_days / NULLIF((total_orders - 1), 0), 1) AS avg_days_between_reorders,
    DENSE_RANK() OVER (ORDER BY total_orders DESC, total_revenue DESC) AS repeat_buyer_rank
FROM customer_repeat_orders
ORDER BY total_orders DESC, total_revenue DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Returns all accounts that placed 2 or more orders. Demonstrates long customer lifespans
-- (e.g. Aarav Sharma, Priya Nair, Sneha Kulkarni spanning over 400+ days) and
-- highlights the average interval between consecutive re-orders.


-- =============================================================================
-- SECTION 4: IDENTIFY LOYAL CUSTOMERS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 4:
-- Which customers demonstrate the highest loyalty based on sustained purchase
-- frequency (e.g., 3 or more orders) and consistent brand engagement?
-- Rank them using window functions to identify our top brand advocates.
-- -----------------------------------------------------------------------------

-- Using CTE, HAVING, and Window Functions (ROW_NUMBER & DENSE_RANK):
WITH customer_frequency AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.segment AS current_segment,
        COUNT(o.order_id) AS total_orders_placed,
        SUM(o.total_amount) AS total_lifetime_spend,
        AVG(o.total_amount) AS avg_spend_per_order,
        MIN(o.order_date) AS earliest_order,
        MAX(o.order_date) AS most_recent_order
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.segment
    HAVING COUNT(o.order_id) >= 3
)
SELECT 
    DENSE_RANK() OVER (ORDER BY total_orders_placed DESC, total_lifetime_spend DESC) AS loyalty_rank,
    customer_id,
    customer_name,
    email,
    current_segment,
    total_orders_placed,
    CONCAT('₹', FORMAT(total_lifetime_spend, 2)) AS total_lifetime_spend,
    CONCAT('₹', FORMAT(avg_spend_per_order, 2)) AS avg_order_value,
    DATEDIFF('2026-11-10', most_recent_order) AS days_since_last_order,
    CASE 
        WHEN total_orders_placed >= 4 THEN 'Tier 1: Super Loyalist (4+ Orders)'
        WHEN total_orders_placed = 3 THEN 'Tier 2: Core Loyalist (3 Orders)'
        ELSE 'Tier 3: Emerging Loyalist'
    END AS loyalty_tier
FROM customer_frequency
ORDER BY loyalty_rank ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Highlights the top loyalty tier: customers with 3 to 4 distinct orders.
-- Identifies top loyalists such as Karan Malhotra (4 orders), Harsh Shah (4 orders),
-- Aarav Sharma (4 orders), Varun Kapoor (3 orders), and Meera Iyer (3 orders).


-- =============================================================================
-- SECTION 5: IDENTIFY HIGH-VALUE CUSTOMERS (HVCs)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 5:
-- Who are our "High-Value Customers" (HVCs) whose total spending exceeds the
-- company-wide average customer spend or places them in the top quartile (75th+ percentile)?
-- -----------------------------------------------------------------------------

-- Using Subqueries, Window Functions (PERCENT_RANK, NTILE, AVG OVER):
WITH customer_spend_summary AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.city,
        c.state,
        COUNT(o.order_id) AS total_orders,
        SUM(o.total_amount) AS customer_total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.city, c.state
),
customer_benchmark AS (
    SELECT 
        customer_id,
        customer_name,
        email,
        city,
        state,
        total_orders,
        customer_total_spend,
        AVG(customer_total_spend) OVER () AS overall_avg_customer_spend,
        PERCENT_RANK() OVER (ORDER BY customer_total_spend ASC) AS spend_percentile,
        NTILE(4) OVER (ORDER BY customer_total_spend DESC) AS spend_quartile
    FROM customer_spend_summary
)
SELECT 
    customer_id,
    customer_name,
    email,
    CONCAT(city, ', ', state) AS location,
    total_orders,
    CONCAT('₹', FORMAT(customer_total_spend, 2)) AS total_spend,
    CONCAT('₹', FORMAT(overall_avg_customer_spend, 2)) AS benchmark_avg_spend,
    CONCAT('+', FORMAT(customer_total_spend - overall_avg_customer_spend, 2)) AS spend_above_average,
    ROUND(spend_percentile * 100, 1) AS percentile_ranking,
    CASE 
        WHEN spend_percentile >= 0.90 THEN 'VIP Elite (Top 10%)'
        WHEN spend_percentile >= 0.75 THEN 'High-Value Tier (Top 25%)'
        ELSE 'Above Average Customer'
    END AS high_value_classification
FROM customer_benchmark
WHERE customer_total_spend > overall_avg_customer_spend
ORDER BY customer_total_spend DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Filters down to customers spending significantly above the company average (~₹62,729).
-- Spotlights VIP spenders contributing ₹1,00,000 to ₹3,50,000+ each, providing key targets
-- for dedicated account managers and exclusive early-access perks.


-- =============================================================================
-- SECTION 6: IDENTIFY LOW-VALUE CUSTOMERS (LVCs)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 6:
-- Which customers fall into the "Low-Value Customer" cohort based on lowest total
-- spend (bottom quartile / below 25th percentile) or having an AOV under ₹5,000?
-- How can marketing cross-sell or increase their basket sizes?
-- -----------------------------------------------------------------------------

-- Using Subqueries, NTILE window function, and CASE:
WITH customer_spend_tiers AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.city,
        c.state,
        COUNT(o.order_id) AS total_orders,
        COALESCE(SUM(o.total_amount), 0.00) AS total_spend,
        COALESCE(AVG(o.total_amount), 0.00) AS avg_order_value,
        NTILE(4) OVER (ORDER BY COALESCE(SUM(o.total_amount), 0.00) ASC) AS spend_quartile
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.city, c.state
)
SELECT 
    customer_id,
    customer_name,
    email,
    CONCAT(city, ', ', state) AS location,
    total_orders,
    CONCAT('₹', FORMAT(total_spend, 2)) AS total_spend,
    CONCAT('₹', FORMAT(avg_order_value, 2)) AS avg_order_value,
    spend_quartile,
    CASE 
        WHEN total_spend = 0 THEN 'Zero-Spend Inactive'
        WHEN total_spend < 2000 THEN 'Micro-Spender (< ₹2,000)'
        WHEN total_spend < 5000 THEN 'Low-Basket Spender (₹2,000 - ₹5,000)'
        ELSE 'Modest Entry-Level Spender'
    END AS value_bracket,
    'Recommend bundle discounts, free shipping thresholds, or cross-sell recommendations' AS growth_recommendation
FROM customer_spend_tiers
WHERE spend_quartile = 1 OR total_spend < 5000
ORDER BY total_spend ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Identifies the bottom quartile of spenders (e.g. Pallavi Nambiar, Tanvi Desai, Suresh Pillai,
-- Ananya Das with spends < ₹3,000). Provides actionable strategies to elevate their order value.


-- =============================================================================
-- SECTION 7: IDENTIFY INACTIVE & AT-RISK CUSTOMERS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 7:
-- Which customers are considered "Inactive" or "At-Risk of Churn" because they
-- have not placed an order in over 120 days or have never made a purchase?
-- -----------------------------------------------------------------------------

-- Using JOIN, DATEDIFF, and CASE:
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    c.phone,
    c.city,
    c.state,
    c.registration_date,
    COUNT(o.order_id) AS lifetime_orders,
    CONCAT('₹', FORMAT(COALESCE(SUM(o.total_amount), 0), 2)) AS total_lifetime_spend,
    COALESCE(DATE_FORMAT(MAX(o.order_date), '%Y-%m-%d'), 'No Orders Placed') AS last_order_date,
    COALESCE(DATEDIFF('2026-11-10', MAX(o.order_date)), 9999) AS days_since_last_order,
    CASE 
        WHEN MAX(o.order_date) IS NULL THEN 'Dormant Account (Never Ordered)'
        WHEN DATEDIFF('2026-11-10', MAX(o.order_date)) > 240 THEN 'Severely Lapsed (> 240 days inactive)'
        WHEN DATEDIFF('2026-11-10', MAX(o.order_date)) > 120 THEN 'At-Risk Inactive (120-240 days inactive)'
        ELSE 'Active'
    END AS inactivity_tier,
    CASE 
        WHEN MAX(o.order_date) IS NULL THEN 'Trigger new-user onboarding coupon'
        WHEN DATEDIFF('2026-11-10', MAX(o.order_date)) > 240 THEN 'Deploy deep reactivation win-back campaign'
        ELSE 'Send targeted product recommendation reminder'
    END AS recommended_retention_action
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY 
    c.customer_id, 
    c.first_name, 
    c.last_name, 
    c.email, 
    c.phone, 
    c.city, 
    c.state, 
    c.registration_date
HAVING MAX(o.order_date) IS NULL OR DATEDIFF('2026-11-10', MAX(o.order_date)) > 120
ORDER BY days_since_last_order DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Highlights churn-vulnerable accounts (e.g. Vikram Singh, Suresh Pillai, Shruti Jain
-- inactive for 200+ days). Equips marketing teams with a direct reactivation checklist.


-- =============================================================================
-- SECTION 8: MASTER COMPREHENSIVE CUSTOMER SEGMENTATION MATRIX
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 8:
-- How can we synthesize all behavioral dimensions into a unified Master
-- Segmentation Matrix for every customer in our database, combining:
--   - Lifetime Orders & Spend
--   - Recency & Inactivity Status
--   - Final Actionable Customer Segment Tag
-- -----------------------------------------------------------------------------

-- Using CTEs, Window Functions, and Multi-Tier CASE Statements:
WITH customer_history AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.gender,
        c.city,
        c.state,
        c.registration_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COALESCE(SUM(o.total_amount), 0.00) AS total_spending,
        COALESCE(AVG(o.total_amount), 0.00) AS avg_order_value,
        MAX(o.order_date) AS latest_order_date,
        COALESCE(DATEDIFF('2026-11-10', MAX(o.order_date)), 9999) AS days_inactive,
        -- Calculate percentile rank based on spend
        PERCENT_RANK() OVER (ORDER BY COALESCE(SUM(o.total_amount), 0.00) ASC) AS spend_percentile
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY 
        c.customer_id, 
        c.first_name, 
        c.last_name, 
        c.email, 
        c.gender, 
        c.city, 
        c.state, 
        c.registration_date
)
SELECT 
    customer_id,
    customer_name,
    email,
    gender,
    CONCAT(city, ', ', state) AS location,
    registration_date,
    total_orders,
    CONCAT('₹', FORMAT(total_spending, 2)) AS total_spending,
    CONCAT('₹', FORMAT(avg_order_value, 2)) AS avg_order_value,
    days_inactive AS days_since_last_order,
    CASE 
        -- Rule 1: High-Value Champions (Top spenders & active)
        WHEN spend_percentile >= 0.75 AND total_orders >= 3 AND days_inactive <= 120 
            THEN 'VIP Champion (High Value & Loyal)'
        
        -- Rule 2: Loyal Repeat Customers (Multiple orders, steady spend)
        WHEN total_orders >= 3 AND days_inactive <= 180 
            THEN 'Loyal Customer (Frequent Buyer)'
        
        -- Rule 3: Returning Customers (2 orders, healthy activity)
        WHEN total_orders = 2 AND days_inactive <= 180 
            THEN 'Returning Customer'
        
        -- Rule 4: New Customers (1 order placed recently)
        WHEN total_orders = 1 AND days_inactive <= 90 
            THEN 'New Customer (Recent Onboarding)'
        
        -- Rule 5: Low-Value Customers (Small basket, low spend)
        WHEN spend_percentile < 0.25 AND days_inactive <= 180 
            THEN 'Low-Value Active Customer'
        
        -- Rule 6: Inactive / At-Risk Customers
        WHEN days_inactive > 180 
            THEN 'Inactive / At-Risk Customer'
        
        -- Default fallback
        ELSE 'Standard Active Customer'
    END AS unified_customer_segment
FROM customer_history
ORDER BY total_spending DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- A complete, executive-ready master table classifying all 30 customers into their
-- strategic segment. Seamlessly unites purchase frequency, total monetary spend,
-- recency of purchase, and loyalty status into a single view.
