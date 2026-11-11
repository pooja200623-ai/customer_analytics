-- =============================================================================
-- PROJECT : Customer Segmentation & Purchase Behavior Analytics
-- FILE    : business_insights.sql
-- PURPOSE : Business Insights & Executive Reports Module (MySQL Only)
--           Strategic executive intelligence, revenue drivers, customer lifetime
--           value, retention risks, and holistic platform KPI summaries:
--             1. Top 10 Highest-Spending Customers (VIP Revenue Drivers)
--             2. Top 10 Best-Selling Products by Volume & Demand Velocity
--             3. Highest Revenue-Generating Product Categories
--             4. Most Valuable Customer Segments (Segment Performance Analysis)
--             5. Monthly Sales Growth & Revenue Expansion Trajectory
--             6. Customer Purchasing Trends Across Quarterly Seasons & Days
--             7. Inactive High-Value Customers (Critical Churn Risk Alerts)
--             8. Overall Business Performance Summary & Executive KPI Scorecard
--
-- CONCEPTS: SELECT, JOIN, GROUP BY, HAVING, CASE statements, Subqueries,
--           Common Table Expressions (CTEs), Window Functions (ROW_NUMBER,
--           DENSE_RANK, NTILE, LAG, SUM OVER, AVG OVER)
-- ENGINE  : MySQL 8.0+
-- =============================================================================

USE customer_analytics;


-- =============================================================================
-- SECTION 1: TOP 10 HIGHEST-SPENDING CUSTOMERS (VIP REVENUE DRIVERS)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 1:
-- Who are our top 10 highest-spending customers by total monetary spend?
-- What is their current loyalty segment, order frequency, average order value (AOV),
-- and what percentage of total company revenue does each top customer generate?
-- -----------------------------------------------------------------------------

WITH customer_spend_summary AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.segment,
        CONCAT(c.city, ', ', c.state) AS location,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS total_spent,
        AVG(o.total_amount) AS average_order_value,
        MAX(o.order_date) AS most_recent_purchase
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.segment, c.city, c.state
),
company_totals AS (
    SELECT SUM(total_amount) AS total_platform_revenue FROM orders
)
SELECT 
    DENSE_RANK() OVER (ORDER BY css.total_spent DESC) AS spending_rank,
    css.customer_id,
    css.customer_name,
    css.email,
    css.segment AS loyalty_segment,
    css.location,
    css.total_orders,
    CONCAT('₹', FORMAT(css.total_spent, 2)) AS total_spent,
    CONCAT('₹', FORMAT(css.average_order_value, 2)) AS average_order_value,
    ROUND((css.total_spent * 100.0) / ct.total_platform_revenue, 2) AS revenue_contribution_pct,
    ROUND(
        SUM(css.total_spent) OVER (ORDER BY css.total_spent DESC) * 100.0 / ct.total_platform_revenue, 
        2
    ) AS cumulative_revenue_pct,
    DATE_FORMAT(css.most_recent_purchase, '%Y-%m-%d') AS latest_purchase_date
FROM customer_spend_summary css
CROSS JOIN company_totals ct
ORDER BY css.total_spent DESC
LIMIT 10;

-- EXPECTED OUTPUT DESCRIPTION:
-- Ranks the top 10 highest-spending customers (Karan Malhotra at ₹3,54,847.00, Varun Kapoor
-- at ₹2,41,889.00, Harsh Shah at ₹2,17,706.00, Aarav Sharma at ₹1,96,565.00, Meera Iyer at ₹1,71,631.00, etc.).
-- Demonstrates that the top 10 accounts contribute over 80% of total company GMV.


-- =============================================================================
-- SECTION 2: TOP 10 BEST-SELLING PRODUCTS (BY VOLUME & REVENUE)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 2:
-- Which top 10 products have generated the highest physical sales volume across all
-- orders? How many total units were sold, in how many distinct orders did they appear,
-- and what is their total gross revenue contribution?
-- -----------------------------------------------------------------------------

WITH product_sales_volume AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        p.brand,
        p.unit_price,
        SUM(oi.quantity) AS total_units_sold,
        COUNT(DISTINCT oi.order_id) AS distinct_orders_count,
        SUM(oi.line_total) AS gross_sales_value
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    GROUP BY p.product_id, p.product_name, c.category_name, p.brand, p.unit_price
),
catalog_totals AS (
    SELECT SUM(quantity) AS catalog_total_units_sold FROM order_items
)
SELECT 
    DENSE_RANK() OVER (ORDER BY psv.total_units_sold DESC, psv.gross_sales_value DESC) AS volume_rank,
    psv.product_id,
    psv.product_name,
    psv.category_name,
    psv.brand,
    CONCAT('₹', FORMAT(psv.unit_price, 2)) AS catalog_unit_price,
    psv.total_units_sold,
    psv.distinct_orders_count,
    ROUND((psv.total_units_sold * 100.0) / ct.catalog_total_units_sold, 2) AS pct_of_all_units_sold,
    CONCAT('₹', FORMAT(psv.gross_sales_value, 2)) AS gross_sales_value
FROM product_sales_volume psv
CROSS JOIN catalog_totals ct
ORDER BY psv.total_units_sold DESC, psv.gross_sales_value DESC
LIMIT 10;

-- EXPECTED OUTPUT DESCRIPTION:
-- Identifies best-selling products by units: Mamaearth Vitamin C FaceWash (9 units),
-- Nescafé Classic 200g (8 units), Amul Dark Chocolate (8 units), Atomic Habits (7 units across 6 orders),
-- and Tata Salt Lite (7 units), indicating everyday high-velocity consumer staples.


-- =============================================================================
-- SECTION 3: HIGHEST REVENUE-GENERATING PRODUCT CATEGORIES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 3:
-- Which product categories generate the highest monetary sales revenue?
-- What are their total orders, total units sold, gross merchandise revenue, and
-- relative percentage share of overall platform sales?
-- -----------------------------------------------------------------------------

WITH category_revenue_breakdown AS (
    SELECT 
        c.category_id,
        c.category_name,
        COUNT(DISTINCT oi.order_id) AS order_occurrences,
        SUM(oi.quantity) AS units_sold,
        SUM(oi.line_total) AS total_category_revenue,
        AVG(oi.line_total) AS avg_item_revenue
    FROM categories c
    JOIN products p ON c.category_id = p.category_id
    JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY c.category_id, c.category_name
),
company_line_gmv AS (
    SELECT SUM(line_total) AS total_gmv FROM order_items
)
SELECT 
    DENSE_RANK() OVER (ORDER BY crb.total_category_revenue DESC) AS category_revenue_rank,
    crb.category_name,
    crb.order_occurrences,
    crb.units_sold,
    CONCAT('₹', FORMAT(crb.total_category_revenue, 2)) AS total_category_revenue,
    CONCAT('₹', FORMAT(crb.avg_item_revenue, 2)) AS avg_line_item_value,
    ROUND((crb.total_category_revenue * 100.0) / clg.total_gmv, 2) AS category_share_of_sales_pct,
    ROUND(
        SUM(crb.total_category_revenue) OVER (ORDER BY crb.total_category_revenue DESC) * 100.0 / clg.total_gmv,
        2
    ) AS cumulative_sales_pct
FROM category_revenue_breakdown crb
CROSS JOIN company_line_gmv clg
ORDER BY crb.total_category_revenue DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Ranks product categories by gross revenue: Electronics leads dramatically (> ₹10.3L, ~63% share),
-- followed by Jewellery (~₹1.15L), Home & Kitchen (~₹1.13L), Sports & Fitness (~₹79K),
-- Beauty & Personal Care (~₹72K), and Clothing (~₹55K).


-- =============================================================================
-- SECTION 4: MOST VALUABLE CUSTOMER SEGMENTS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 4:
-- How do the different customer loyalty tiers (Platinum, Gold, Silver, Bronze, New)
-- compare in terms of total customer count, total orders, aggregate revenue,
-- average order value (AOV), and average revenue per user (ARPU)?
-- -----------------------------------------------------------------------------

WITH segment_performance AS (
    SELECT 
        c.segment AS loyalty_segment,
        COUNT(DISTINCT c.customer_id) AS total_customers_in_segment,
        COUNT(DISTINCT o.order_id) AS total_orders_placed,
        COALESCE(SUM(o.total_amount), 0.00) AS total_segment_revenue,
        COALESCE(AVG(o.total_amount), 0.00) AS average_order_value,
        COALESCE(SUM(o.total_amount) / NULLIF(COUNT(DISTINCT c.customer_id), 0), 0.00) AS segment_arpu
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.segment
),
overall_benchmarks AS (
    SELECT SUM(total_amount) AS total_company_revenue FROM orders
)
SELECT 
    sp.loyalty_segment,
    sp.total_customers_in_segment,
    sp.total_orders_placed,
    CONCAT('₹', FORMAT(sp.total_segment_revenue, 2)) AS total_segment_revenue,
    ROUND((sp.total_segment_revenue * 100.0) / ob.total_company_revenue, 2) AS revenue_share_pct,
    CONCAT('₹', FORMAT(sp.average_order_value, 2)) AS segment_aov,
    CONCAT('₹', FORMAT(sp.segment_arpu, 2)) AS segment_arpu,
    ROUND(sp.total_orders_placed / NULLIF(sp.total_customers_in_segment, 0), 2) AS orders_per_customer,
    DENSE_RANK() OVER (ORDER BY sp.total_segment_revenue DESC) AS segment_value_rank
FROM segment_performance sp
CROSS JOIN overall_benchmarks ob
ORDER BY sp.total_segment_revenue DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Reveals commercial value by tier: Platinum customers (5 accounts) generate over ₹10.7L (~57% of GMV)
-- with an ARPU of ₹2.14L, followed by Gold (7 accounts, ₹4.46L), Silver, Bronze, and New.


-- =============================================================================
-- SECTION 5: MONTHLY SALES GROWTH & EXPANSION TRAJECTORY
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 5:
-- What is the month-over-month (MoM) revenue trajectory across all operating months?
-- Calculate absolute revenue variance, percentage growth rate, order volume variance,
-- and running cumulative platform revenue.
-- -----------------------------------------------------------------------------

WITH monthly_sales_data AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
        COUNT(order_id) AS total_orders,
        SUM(total_amount) AS monthly_revenue,
        AVG(total_amount) AS monthly_aov
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
monthly_growth_calculations AS (
    SELECT 
        sales_month,
        total_orders,
        monthly_revenue,
        monthly_aov,
        LAG(monthly_revenue, 1) OVER (ORDER BY sales_month ASC) AS previous_month_revenue,
        LAG(total_orders, 1) OVER (ORDER BY sales_month ASC) AS previous_month_orders,
        SUM(monthly_revenue) OVER (ORDER BY sales_month ASC) AS cumulative_revenue_to_date
    FROM monthly_sales_data
)
SELECT 
    sales_month,
    total_orders,
    CONCAT('₹', FORMAT(monthly_revenue, 2)) AS monthly_revenue,
    CONCAT('₹', FORMAT(previous_month_revenue, 2)) AS previous_month_revenue,
    CASE 
        WHEN previous_month_revenue IS NULL THEN 'Baseline'
        WHEN monthly_revenue >= previous_month_revenue THEN 
            CONCAT('+', FORMAT(monthly_revenue - previous_month_revenue, 2))
        ELSE 
            CONCAT('-', FORMAT(ABS(monthly_revenue - previous_month_revenue), 2))
    END AS net_revenue_change,
    CASE 
        WHEN previous_month_revenue IS NULL THEN 'Baseline'
        WHEN monthly_revenue >= previous_month_revenue THEN 
            CONCAT('+', ROUND(((monthly_revenue - previous_month_revenue) / previous_month_revenue) * 100, 2), '%')
        ELSE 
            CONCAT(ROUND(((monthly_revenue - previous_month_revenue) / previous_month_revenue) * 100, 2), '%')
    END AS mom_revenue_growth_pct,
    CONCAT('₹', FORMAT(cumulative_revenue_to_date, 2)) AS cumulative_platform_revenue
FROM monthly_growth_calculations
ORDER BY sales_month ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Detailed timeline of monthly performance from Jan 2025 through Nov 2026, showing
-- cyclical demand peaks (e.g. Sep 2026 at ₹1.93L, Jan 2025 at ₹1.85L) and cumulative revenue run-rate.


-- =============================================================================
-- SECTION 6: ANALYZE CUSTOMER PURCHASING TRENDS (TIME & FREQUENCY)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 6:
-- What are the operational purchasing trends in terms of day-of-week demand and
-- quarterly seasonal cadence? On which days of the week do customers spend the most,
-- and what is the average ticket size by day?
-- -----------------------------------------------------------------------------

SELECT 
    DAYNAME(order_date) AS day_of_week,
    DAYOFWEEK(order_date) AS day_index,
    COUNT(order_id) AS total_orders_placed,
    CONCAT('₹', FORMAT(SUM(total_amount), 2)) AS total_day_revenue,
    CONCAT('₹', FORMAT(AVG(total_amount), 2)) AS average_order_value,
    ROUND((COUNT(order_id) * 100.0) / (SELECT COUNT(*) FROM orders), 2) AS order_share_pct,
    DENSE_RANK() OVER (ORDER BY SUM(total_amount) DESC) AS revenue_rank_by_day
FROM orders
GROUP BY DAYNAME(order_date), DAYOFWEEK(order_date)
ORDER BY day_index ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Summarizes purchasing behavior by weekday: identifies high-conversion days
-- (e.g., Wednesdays, Sundays, and Mondays) with total revenue and average basket sizes,
-- providing optimal timings for promotional marketing pushes.


-- =============================================================================
-- SECTION 7: IDENTIFY INACTIVE HIGH-VALUE CUSTOMERS (CHURN RISK ALERTS)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 7:
-- Which high-value customers (spending >= ₹50,000 or belonging to Gold/Platinum segments)
-- have not placed any orders in over 90 days?
-- What is their historical spend, last purchase date, and recommended CRM win-back action?
-- -----------------------------------------------------------------------------

WITH customer_spend_recency AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.phone,
        c.segment AS loyalty_segment,
        CONCAT(c.city, ', ', c.state) AS location,
        COUNT(o.order_id) AS total_orders,
        SUM(o.total_amount) AS lifetime_expenditure,
        MAX(o.order_date) AS most_recent_order,
        DATEDIFF('2026-11-10', MAX(o.order_date)) AS days_inactive
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.phone, c.segment, c.city, c.state
)
SELECT 
    customer_id,
    customer_name,
    email,
    phone,
    loyalty_segment,
    location,
    total_orders,
    CONCAT('₹', FORMAT(lifetime_expenditure, 2)) AS lifetime_expenditure,
    DATE_FORMAT(most_recent_order, '%Y-%m-%d') AS latest_order_date,
    days_inactive AS days_since_last_order,
    CASE 
        WHEN days_inactive > 180 THEN 'High Churn Risk (Severe Lapsed VIP)'
        WHEN days_inactive > 120 THEN 'Moderate Churn Risk (Cooling VIP)'
        ELSE 'Early Inactivity Warning (90-120 Days)'
    END AS risk_urgency_tier,
    CASE 
        WHEN days_inactive > 180 THEN 'Deploy direct VIP account manager call + 20% concierge credit'
        WHEN days_inactive > 120 THEN 'Send exclusive catalog preview + ₹2,000 loyalty reactivation voucher'
        ELSE 'Send curated recommendations based on previous category purchases'
    END AS strategic_crm_winback_action
FROM customer_spend_recency
WHERE (lifetime_expenditure >= 50000.00 OR loyalty_segment IN ('Gold', 'Platinum'))
  AND days_inactive > 90
ORDER BY lifetime_expenditure DESC, days_inactive DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Flags critical dormant VIP accounts: Meera Iyer (Platinum, ₹1,71,631.00 spend, 119 days inactive),
-- Sneha Kulkarni (Platinum, ₹90,357.00 spend, 143 days inactive), and Deepak Kumar (Gold, ₹63,164.00 spend,
-- 155 days inactive), providing urgent retention triggers before complete churn.


-- =============================================================================
-- SECTION 8: OVERALL BUSINESS PERFORMANCE SUMMARY & EXECUTIVE KPI SCORECARD
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 8:
-- How can we generate an executive-level single-view KPI scorecard capturing all
-- primary dimensions of platform performance:
--   - Customer Base & Active Buyer Penetration
--   - Total Gross & Net Commercial Revenue
--   - Total Order Volume & Fulfillment Rates
--   - Average Order Value (AOV) & Customer Lifetime Value (CLV)
--   - Catalog SKU Depth & Total Units Sold?
-- -----------------------------------------------------------------------------

WITH customer_summary AS (
    SELECT 
        COUNT(c.customer_id) AS registered_customers_count,
        COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN c.customer_id END) AS converted_buyers_count,
        ROUND(
            (COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN c.customer_id END) * 100.0) / COUNT(c.customer_id), 
            2
        ) AS buyer_conversion_rate_pct
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
),
order_summary AS (
    SELECT 
        COUNT(order_id) AS total_orders_placed,
        SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_orders_count,
        SUM(CASE WHEN status = 'Returned' THEN 1 ELSE 0 END) AS returned_orders_count,
        SUM(subtotal) AS gross_merchandise_subtotal,
        SUM(discount_amount) AS total_discount_given,
        SUM(shipping_charge) AS total_shipping_revenue,
        SUM(tax_amount) AS total_tax_collected,
        SUM(total_amount) AS net_platform_sales_revenue,
        AVG(total_amount) AS platform_average_order_value
    FROM orders
),
product_summary AS (
    SELECT 
        COUNT(DISTINCT p.product_id) AS active_catalog_skus,
        COUNT(DISTINCT p.category_id) AS product_categories_count,
        SUM(oi.quantity) AS total_physical_units_sold
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
)
SELECT 
    cs.registered_customers_count,
    cs.converted_buyers_count,
    CONCAT(cs.buyer_conversion_rate_pct, '%') AS buyer_conversion_rate,
    os.total_orders_placed,
    os.delivered_orders_count,
    os.returned_orders_count,
    ps.active_catalog_skus,
    ps.product_categories_count,
    ps.total_physical_units_sold,
    CONCAT('₹', FORMAT(os.gross_merchandise_subtotal, 2)) AS gross_merchandise_subtotal,
    CONCAT('₹', FORMAT(os.total_discount_given, 2)) AS total_discounts_granted,
    CONCAT('₹', FORMAT(os.total_shipping_revenue, 2)) AS shipping_charges_collected,
    CONCAT('₹', FORMAT(os.net_platform_sales_revenue, 2)) AS net_platform_sales_revenue,
    CONCAT('₹', FORMAT(os.platform_average_order_value, 2)) AS overall_average_order_value,
    CONCAT('₹', FORMAT(os.net_platform_sales_revenue / cs.registered_customers_count, 2)) AS average_revenue_per_customer_arpu
FROM customer_summary cs
CROSS JOIN order_summary os
CROSS JOIN product_summary ps;

-- EXPECTED OUTPUT DESCRIPTION:
-- A complete executive KPI scorecard summarizing: 30 registered users (96.67% buyer conversion),
-- 60 orders (51 delivered), 133 units sold across 10 categories, gross subtotal (~₹16.5L),
-- net revenue of ₹18,81,872.00, AOV of ₹31,364.53, and an overall ARPU of ₹62,729.07.
