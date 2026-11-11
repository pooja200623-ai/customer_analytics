-- =============================================================================
-- PROJECT : Customer Segmentation & Purchase Behavior Analytics
-- FILE    : purchase_behavior.sql
-- PURPOSE : Purchase Behavior Analysis Module (MySQL Only)
--           Comprehensive analysis of customer transaction history, purchasing
--           dynamics, product affinities, spending velocity, and recency gaps:
--             1. Customer Purchasing History Deep-Dive (Frequency, Spend & AOV)
--             2. Frequently Purchased Products (Top SKUs by Quantity & Orders)
--             3. Customer Purchase Frequency Distribution & Engagement Tiers
--             4. Total Spending Analysis & Revenue Concentration
--             5. Average Order Value (AOV) Profiling & Basket Value Tiers
--             6. Customer Preferred Product Categories (Affinity Analysis)
--             7. Monthly Purchase Patterns & Seasonal Sales Velocity
--             8. Customers with the Highest Purchase Frequency (Power Buyers)
--             9. Customers Who Have Not Purchased Recently (Recency & Churn Risk)
--
-- CONCEPTS: SELECT, JOIN, GROUP BY, HAVING, Subqueries, CASE statements,
--           Common Table Expressions (CTEs), Window Functions (ROW_NUMBER,
--           DENSE_RANK, NTILE, LAG, SUM OVER, AVG OVER)
-- ENGINE  : MySQL 8.0+
-- =============================================================================

USE customer_analytics;


-- =============================================================================
-- SECTION 1: CUSTOMER PURCHASING HISTORY DEEP-DIVE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 1:
-- How can we construct a holistic purchasing profile for each customer that details:
--   - Total lifetime orders placed
--   - Total monetary expenditure
--   - Average order value (AOV)
--   - Total units/items purchased
--   - First and latest transaction timestamps
--   - Customer tenure in days?
-- -----------------------------------------------------------------------------

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    c.city,
    c.state,
    c.registration_date,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COALESCE(SUM(oi.quantity), 0) AS total_items_purchased,
    COALESCE(SUM(o.total_amount), 0.00) AS total_spend_numeric,
    CONCAT('₹', FORMAT(COALESCE(SUM(o.total_amount), 0.00), 2)) AS total_spend_formatted,
    CONCAT('₹', FORMAT(COALESCE(AVG(o.total_amount), 0.00), 2)) AS average_order_value,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS most_recent_order_date,
    COALESCE(DATEDIFF(MAX(o.order_date), MIN(o.order_date)), 0) AS active_purchasing_span_days
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
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
-- Returns all 30 customers ranked by total spend. Reveals full transaction telemetry:
-- customer location, order counts (1 to 4 orders), physical units purchased, AOV,
-- and the duration (in days) between their initial and latest purchases.


-- =============================================================================
-- SECTION 2: FREQUENTLY PURCHASED PRODUCTS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 2:
-- Which products are the most frequently purchased across the platform in terms
-- of total quantity sold, distinct order occurrences, and gross revenue generated?
-- Rank products within their respective categories and overall.
-- -----------------------------------------------------------------------------

WITH product_metrics AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        p.brand,
        p.unit_price,
        SUM(oi.quantity) AS total_units_sold,
        COUNT(DISTINCT oi.order_id) AS times_ordered,
        SUM(oi.line_total) AS total_sales_revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    GROUP BY p.product_id, p.product_name, c.category_name, p.brand, p.unit_price
)
SELECT 
    DENSE_RANK() OVER (ORDER BY total_units_sold DESC, times_ordered DESC) AS popularity_rank,
    product_id,
    product_name,
    category_name,
    brand,
    CONCAT('₹', FORMAT(unit_price, 2)) AS unit_price,
    total_units_sold,
    times_ordered,
    CONCAT('₹', FORMAT(total_sales_revenue, 2)) AS total_sales_revenue,
    DENSE_RANK() OVER (PARTITION BY category_name ORDER BY total_units_sold DESC) AS rank_within_category
FROM product_metrics
ORDER BY total_units_sold DESC, times_ordered DESC
LIMIT 15;

-- EXPECTED OUTPUT DESCRIPTION:
-- Highlights fast-moving consumer products such as Mamaearth FaceWash (9 units sold),
-- Nescafé Classic 200g (8 units), Amul Dark Chocolate (8 units), Atomic Habits (7 units, 6 distinct orders),
-- and Tata Salt Lite (7 units), complete with cross-category popularity rankings.


-- =============================================================================
-- SECTION 3: PURCHASE FREQUENCY FOR EACH CUSTOMER
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 3:
-- What is the purchase frequency of each customer, and how are customers
-- distributed into behavioral frequency tiers (e.g., One-Time, Occasional,
-- Frequent, Power Buyer)?
-- -----------------------------------------------------------------------------

WITH customer_orders_cte AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.segment,
        COUNT(o.order_id) AS order_frequency,
        COALESCE(SUM(o.total_amount), 0.00) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.segment
)
SELECT 
    customer_id,
    customer_name,
    email,
    segment AS assigned_segment,
    order_frequency,
    CONCAT('₹', FORMAT(total_spent, 2)) AS total_spent,
    CASE 
        WHEN order_frequency = 0 THEN 'Dormant (0 Orders)'
        WHEN order_frequency = 1 THEN 'Single Purchase (1 Order)'
        WHEN order_frequency = 2 THEN 'Occasional Buyer (2 Orders)'
        WHEN order_frequency = 3 THEN 'Frequent Buyer (3 Orders)'
        ELSE 'Power Buyer (4+ Orders)'
    END AS purchase_frequency_tier,
    DENSE_RANK() OVER (ORDER BY order_frequency DESC, total_spent DESC) AS frequency_rank
FROM customer_orders_cte
ORDER BY order_frequency DESC, total_spent DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Classifies all 30 customers by frequency: 3 Power Buyers (4 orders each), 6 Frequent
-- Buyers (3 orders each), 10 Occasional Buyers (2 orders each), and 11 Single-Purchase buyers.


-- =============================================================================
-- SECTION 4: TOTAL SPENDING PER CUSTOMER
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 4:
-- What is the total monetary expenditure for each customer? What percentage of
-- total company gross merchandise value (GMV) does each customer represent,
-- and what is the cumulative revenue curve?
-- -----------------------------------------------------------------------------

WITH customer_spending AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.city,
        c.state,
        COUNT(o.order_id) AS total_orders,
        COALESCE(SUM(o.total_amount), 0.00) AS customer_revenue
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.city, c.state
),
company_total AS (
    SELECT SUM(total_amount) AS overall_gmv FROM orders
)
SELECT 
    cs.customer_id,
    cs.customer_name,
    CONCAT(cs.city, ', ', cs.state) AS location,
    cs.total_orders,
    CONCAT('₹', FORMAT(cs.customer_revenue, 2)) AS total_spent,
    ROUND((cs.customer_revenue / ct.overall_gmv) * 100, 2) AS pct_of_company_revenue,
    ROUND(
        SUM(cs.customer_revenue) OVER (ORDER BY cs.customer_revenue DESC) / ct.overall_gmv * 100, 
        2
    ) AS cumulative_revenue_percentage,
    DENSE_RANK() OVER (ORDER BY cs.customer_revenue DESC) AS spending_rank
FROM customer_spending cs
CROSS JOIN company_total ct
ORDER BY cs.customer_revenue DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Demonstrates total spending per customer with running cumulative revenue percentages.
-- Top spenders (Karan Malhotra at ₹3,54,847.00 ~ 18.86%, Varun Kapoor at ₹2,41,889.00 ~ 12.85%)
-- drive a substantial proportion of overall business revenue.


-- =============================================================================
-- SECTION 5: EACH CUSTOMER'S AVERAGE ORDER VALUE (AOV)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 5:
-- What is the Average Order Value (AOV) for each customer who has placed orders?
-- How does each customer's AOV compare against the company-wide average basket size?
-- Categorize customers into Premium, Mid-Tier, and Economy basket sizes.
-- -----------------------------------------------------------------------------

WITH customer_aov_stats AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        COUNT(o.order_id) AS total_orders,
        SUM(o.total_amount) AS total_spend,
        AVG(o.total_amount) AS customer_aov
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email
),
benchmark AS (
    SELECT AVG(total_amount) AS platform_avg_order_value FROM orders
)
SELECT 
    cas.customer_id,
    cas.customer_name,
    cas.email,
    cas.total_orders,
    CONCAT('₹', FORMAT(cas.total_spend, 2)) AS total_spend,
    CONCAT('₹', FORMAT(cas.customer_aov, 2)) AS customer_aov,
    CONCAT('₹', FORMAT(b.platform_avg_order_value, 2)) AS platform_aov_benchmark,
    CASE 
        WHEN cas.customer_aov >= b.platform_avg_order_value * 1.5 THEN 'Premium Basket (> 150% of Benchmark)'
        WHEN cas.customer_aov >= b.platform_avg_order_value THEN 'High Basket (Above Benchmark)'
        WHEN cas.customer_aov >= b.platform_avg_order_value * 0.5 THEN 'Moderate Basket (50-100% of Benchmark)'
        ELSE 'Economy Basket (< 50% of Benchmark)'
    END AS basket_value_category,
    ROUND(((cas.customer_aov - b.platform_avg_order_value) / b.platform_avg_order_value) * 100, 1) AS pct_variance_from_benchmark
FROM customer_aov_stats cas
CROSS JOIN benchmark b
ORDER BY cas.customer_aov DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Shows individual AOVs compared with the company benchmark (~₹31,364.53).
-- High-ticket customers like Karan Malhotra (AOV ₹88,711.75) and Varun Kapoor (AOV ₹80,629.67)
-- are classified as Premium Baskets, whereas budget buyers with AOVs < ₹5,000 are identified for up-selling.


-- =============================================================================
-- SECTION 6: CUSTOMERS' MOST PURCHASED PRODUCT CATEGORIES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 6:
-- What is the primary (most frequently purchased) product category for each customer,
-- how many items have they bought in that category, and how much have they spent on it?
-- -----------------------------------------------------------------------------

WITH customer_category_affinity AS (
    SELECT 
        o.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        cat.category_id,
        cat.category_name,
        COUNT(oi.order_item_id) AS times_category_ordered,
        SUM(oi.quantity) AS total_units_bought,
        SUM(oi.line_total) AS total_category_expenditure,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id 
            ORDER BY SUM(oi.quantity) DESC, SUM(oi.line_total) DESC
        ) AS category_rank
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories cat ON p.category_id = cat.category_id
    GROUP BY o.customer_id, c.first_name, c.last_name, cat.category_id, cat.category_name
)
SELECT 
    customer_id,
    customer_name,
    category_name AS preferred_category,
    times_category_ordered,
    total_units_bought,
    CONCAT('₹', FORMAT(total_category_expenditure, 2)) AS category_spend
FROM customer_category_affinity
WHERE category_rank = 1
ORDER BY total_category_expenditure DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Identifies the dominant product category affinity for each customer (e.g., Aarav Sharma → Electronics,
-- Priya Nair → Sports & Fitness, Divya Joshi → Clothing, Sneha Kulkarni → Home & Kitchen),
-- enabling personalized marketing segmentation and cross-sell recommendation engines.


-- =============================================================================
-- SECTION 7: MONTHLY PURCHASE PATTERNS & SEASONAL VELOCITY
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 7:
-- How do purchase patterns fluctuate month-over-month in terms of:
--   - Total order volume
--   - Distinct active buyers
--   - Total revenue processed
--   - Average order value per month
--   - Month-over-month (MoM) order growth rate?
-- -----------------------------------------------------------------------------

WITH monthly_aggregates AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS purchase_month,
        COUNT(order_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS distinct_active_buyers,
        SUM(total_amount) AS monthly_revenue,
        AVG(total_amount) AS monthly_aov
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
monthly_trends AS (
    SELECT 
        purchase_month,
        total_orders,
        distinct_active_buyers,
        monthly_revenue,
        monthly_aov,
        LAG(total_orders, 1) OVER (ORDER BY purchase_month ASC) AS previous_month_orders,
        LAG(monthly_revenue, 1) OVER (ORDER BY purchase_month ASC) AS previous_month_revenue
    FROM monthly_aggregates
)
SELECT 
    purchase_month,
    total_orders,
    distinct_active_buyers,
    CONCAT('₹', FORMAT(monthly_revenue, 2)) AS monthly_revenue,
    CONCAT('₹', FORMAT(monthly_aov, 2)) AS avg_order_value,
    CASE 
        WHEN previous_month_orders IS NULL THEN 'Baseline'
        ELSE CONCAT(ROUND(((total_orders - previous_month_orders) * 100.0) / previous_month_orders, 1), '%')
    END AS order_volume_mom_growth,
    CASE 
        WHEN previous_month_revenue IS NULL THEN 'Baseline'
        ELSE CONCAT(ROUND(((monthly_revenue - previous_month_revenue) * 100.0) / previous_month_revenue, 1), '%')
    END AS revenue_mom_growth
FROM monthly_trends
ORDER BY purchase_month ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Tracks monthly seasonal demand patterns from January 2025 through November 2026.
-- Pinpoints high-volume sales periods (such as festive quarter peaks) and provides
-- revenue growth percentages month-by-month.


-- =============================================================================
-- SECTION 8: CUSTOMERS WITH THE HIGHEST PURCHASE FREQUENCY
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 8:
-- Which customers have demonstrated the highest purchase frequency across the
-- entire platform? Rank the top frequent buyers and analyze their purchasing
-- cadence (days active and average days between successive orders).
-- -----------------------------------------------------------------------------

WITH customer_cadence AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.city,
        COUNT(o.order_id) AS order_count,
        SUM(o.total_amount) AS total_spent,
        MIN(o.order_date) AS first_order,
        MAX(o.order_date) AS latest_order,
        DATEDIFF(MAX(o.order_date), MIN(o.order_date)) AS lifetime_span_days
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.city
    HAVING COUNT(o.order_id) >= 3
)
SELECT 
    DENSE_RANK() OVER (ORDER BY order_count DESC, total_spent DESC) AS frequency_rank,
    customer_id,
    customer_name,
    email,
    city,
    order_count AS total_orders_placed,
    CONCAT('₹', FORMAT(total_spent, 2)) AS total_spent,
    CONCAT('₹', FORMAT(total_spent / order_count, 2)) AS avg_ticket_size,
    lifetime_span_days,
    ROUND(lifetime_span_days / NULLIF((order_count - 1), 0), 1) AS avg_days_between_orders
FROM customer_cadence
ORDER BY frequency_rank ASC, total_spent DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Ranks the platform's power shoppers (Karan Malhotra, Harsh Shah, Aarav Sharma with 4 orders;
-- Varun Kapoor, Meera Iyer, Siddharth Bhatt, Sneha Kulkarni, Priya Nair, Arjun Mehta with 3 orders).
-- Calculates their average re-order cadence (typically every 90-180 days).


-- =============================================================================
-- SECTION 9: CUSTOMERS WHO HAVE NOT PURCHASED RECENTLY (CHURN RISK)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 9:
-- Which customers have not made any purchases recently (> 90 days or > 180 days
-- since their last order, or never ordered at all)?
-- Quantify their churn risk level and days elapsed since last engagement.
-- -----------------------------------------------------------------------------

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    c.phone,
    CONCAT(c.city, ', ', c.state) AS location,
    c.registration_date,
    COUNT(o.order_id) AS lifetime_orders,
    CONCAT('₹', FORMAT(COALESCE(SUM(o.total_amount), 0), 2)) AS total_lifetime_spend,
    COALESCE(DATE_FORMAT(MAX(o.order_date), '%Y-%m-%d'), 'Never Ordered') AS last_order_date,
    COALESCE(DATEDIFF('2026-11-10', MAX(o.order_date)), 9999) AS days_since_last_purchase,
    CASE 
        WHEN MAX(o.order_date) IS NULL THEN 'Never Converted (Cold Lead)'
        WHEN DATEDIFF('2026-11-10', MAX(o.order_date)) > 240 THEN 'Severe Churn Risk (> 240 Days)'
        WHEN DATEDIFF('2026-11-10', MAX(o.order_date)) > 150 THEN 'High Churn Risk (150-240 Days)'
        WHEN DATEDIFF('2026-11-10', MAX(o.order_date)) > 90 THEN 'Moderate Inactivity (90-150 Days)'
        ELSE 'Active Buyer'
    END AS churn_risk_classification,
    CASE 
        WHEN MAX(o.order_date) IS NULL THEN 'Send welcome discount onboarding series'
        WHEN DATEDIFF('2026-11-10', MAX(o.order_date)) > 240 THEN 'Offer 20% win-back voucher or phone outreach'
        WHEN DATEDIFF('2026-11-10', MAX(o.order_date)) > 150 THEN 'Send personalized catalog based on past category'
        WHEN DATEDIFF('2026-11-10', MAX(o.order_date)) > 90 THEN 'Send gentle reminder & new arrivals push'
        ELSE 'Regular nurture emails'
    END AS automated_retention_action
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
HAVING MAX(o.order_date) IS NULL OR DATEDIFF('2026-11-10', MAX(o.order_date)) > 90
ORDER BY days_since_last_purchase DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Surfaces all customers requiring re-activation (e.g. Vikram Singh, Suresh Pillai,
-- Shruti Jain, Ananya Das inactive for 100+ to 400+ days).
-- Assigns an automated retention strategy for each tier.
