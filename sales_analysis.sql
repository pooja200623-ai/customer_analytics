-- =============================================================================
-- PROJECT : Customer Segmentation & Purchase Behavior Analytics
-- FILE    : sales_analysis.sql
-- PURPOSE : Sales Analysis Module (MySQL Only)
--           Comprehensive financial and transactional sales intelligence:
--             1. Total Sales Revenue & Financial Summary (Gross, Discounts, Tax, Net)
--             2. Daily Sales Trend & Daily Revenue Run-Rate
--             3. Monthly Sales Trajectory & MoM Growth Analysis
--             4. Yearly Sales Performance & YoY Expansion
--             5. Top-Selling Products by Volume (Unit Velocity)
--             6. Highest Revenue-Generating Products (Value Champions)
--             7. Sales by Product Category & Category Contribution
--             8. Average Order Value (AOV) Dynamics Across Cohorts
--             9. Best-Performing Sales Months (Peak Revenue Months)
--            10. Period-over-Period Performance Comparison (QoQ & YoY)
--
-- CONCEPTS: SELECT, JOIN, GROUP BY, ORDER BY, HAVING, Aggregate Functions,
--           Subqueries, Common Table Expressions (CTEs), Window Functions
--           (ROW_NUMBER, DENSE_RANK, NTILE, LAG, SUM OVER, AVG OVER)
-- ENGINE  : MySQL 8.0+
-- =============================================================================

USE customer_analytics;


-- =============================================================================
-- SECTION 1: CALCULATE TOTAL SALES REVENUE & FINANCIAL BREAKDOWN
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 1:
-- What is the platform's total gross sales revenue, net collected revenue, total
-- discounts given, total shipping charges collected, total taxes, and overall
-- order fulfillment count across all transactions?
-- -----------------------------------------------------------------------------

SELECT 
    COUNT(order_id) AS total_orders_placed,
    SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_orders,
    SUM(CASE WHEN status = 'Returned' THEN 1 ELSE 0 END) AS returned_orders,
    SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_orders,
    CONCAT('₹', FORMAT(SUM(subtotal), 2)) AS gross_subtotal,
    CONCAT('₹', FORMAT(SUM(discount_amount), 2)) AS total_discounts_granted,
    ROUND((SUM(discount_amount) * 100.0) / NULLIF(SUM(subtotal), 0), 2) AS effective_discount_rate_pct,
    CONCAT('₹', FORMAT(SUM(tax_amount), 2)) AS total_tax_collected,
    CONCAT('₹', FORMAT(SUM(shipping_charge), 2)) AS total_shipping_revenue,
    CONCAT('₹', FORMAT(SUM(total_amount), 2)) AS net_total_sales_revenue,
    CONCAT('₹', FORMAT(AVG(total_amount), 2)) AS average_order_value
FROM orders;

-- EXPECTED OUTPUT DESCRIPTION:
-- A single-row financial audit summary displaying total orders (60), gross subtotal (~₹16.5L),
-- total discounts, taxes, shipping, net sales revenue (₹18,81,872.00), and platform AOV (₹31,364.53).


-- =============================================================================
-- SECTION 2: ANALYZE DAILY SALES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 2:
-- What is the daily sales distribution? On which days were orders placed, what was
-- the daily order volume and revenue, and what is the 7-day rolling moving average
-- of daily sales?
-- -----------------------------------------------------------------------------

WITH daily_sales_summary AS (
    SELECT 
        DATE(order_date) AS sales_date,
        COUNT(order_id) AS orders_count,
        SUM(total_amount) AS daily_revenue,
        AVG(total_amount) AS daily_aov
    FROM orders
    GROUP BY DATE(order_date)
)
SELECT 
    sales_date,
    orders_count,
    CONCAT('₹', FORMAT(daily_revenue, 2)) AS daily_revenue,
    CONCAT('₹', FORMAT(daily_aov, 2)) AS daily_aov,
    -- 7-period moving average of daily revenue
    CONCAT('₹', FORMAT(AVG(daily_revenue) OVER (
        ORDER BY sales_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2)) AS rolling_7day_avg_revenue,
    -- Cumulative running revenue across days
    CONCAT('₹', FORMAT(SUM(daily_revenue) OVER (ORDER BY sales_date ASC), 2)) AS running_cumulative_revenue
FROM daily_sales_summary
ORDER BY sales_date DESC
LIMIT 15;

-- EXPECTED OUTPUT DESCRIPTION:
-- Shows the most recent daily transaction summaries with orders per day, daily revenue,
-- rolling moving averages, and cumulative running revenue.


-- =============================================================================
-- SECTION 3: ANALYZE MONTHLY SALES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 3:
-- How has sales revenue evolved on a monthly basis? What is the monthly order
-- volume, total revenue, average order value, and Month-over-Month (MoM) revenue
-- growth percentage?
-- -----------------------------------------------------------------------------

WITH monthly_sales_raw AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
        COUNT(order_id) AS orders_count,
        SUM(total_amount) AS monthly_revenue,
        AVG(total_amount) AS monthly_aov
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
monthly_sales_mom AS (
    SELECT 
        sales_month,
        orders_count,
        monthly_revenue,
        monthly_aov,
        LAG(monthly_revenue, 1) OVER (ORDER BY sales_month ASC) AS prev_month_revenue,
        LAG(orders_count, 1) OVER (ORDER BY sales_month ASC) AS prev_month_orders,
        SUM(monthly_revenue) OVER (ORDER BY sales_month ASC) AS running_total_revenue
    FROM monthly_sales_raw
)
SELECT 
    sales_month,
    orders_count,
    CONCAT('₹', FORMAT(monthly_revenue, 2)) AS monthly_revenue,
    CONCAT('₹', FORMAT(prev_month_revenue, 2)) AS previous_month_revenue,
    CASE 
        WHEN prev_month_revenue IS NULL THEN 'Baseline'
        ELSE CONCAT(ROUND(((monthly_revenue - prev_month_revenue) / prev_month_revenue) * 100, 2), '%')
    END AS mom_revenue_growth_pct,
    CONCAT('₹', FORMAT(monthly_aov, 2)) AS monthly_aov,
    CONCAT('₹', FORMAT(running_total_revenue, 2)) AS running_total_revenue
FROM monthly_sales_mom
ORDER BY sales_month ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Chronological month-by-month trajectory from 2025-01 through 2026-11 tracking
-- order volume, GMV, MoM percentage changes, and cumulative platform sales.


-- =============================================================================
-- SECTION 4: ANALYZE YEARLY SALES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 4:
-- What is the annual sales performance comparing 2025 and 2026? What was the
-- total order volume, active customer count, total gross revenue, and Year-over-Year
-- (YoY) growth rate?
-- -----------------------------------------------------------------------------

WITH yearly_sales_raw AS (
    SELECT 
        YEAR(order_date) AS sales_year,
        COUNT(order_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS unique_purchasing_customers,
        SUM(subtotal) AS gross_subtotal,
        SUM(discount_amount) AS total_discounts,
        SUM(total_amount) AS annual_revenue,
        AVG(total_amount) AS annual_aov
    FROM orders
    GROUP BY YEAR(order_date)
),
yearly_sales_growth AS (
    SELECT 
        sales_year,
        total_orders,
        unique_purchasing_customers,
        gross_subtotal,
        total_discounts,
        annual_revenue,
        annual_aov,
        LAG(annual_revenue, 1) OVER (ORDER BY sales_year ASC) AS prev_year_revenue,
        LAG(total_orders, 1) OVER (ORDER BY sales_year ASC) AS prev_year_orders
    FROM yearly_sales_raw
)
SELECT 
    sales_year,
    total_orders,
    unique_purchasing_customers,
    CONCAT('₹', FORMAT(gross_subtotal, 2)) AS gross_subtotal,
    CONCAT('₹', FORMAT(total_discounts, 2)) AS total_discounts,
    CONCAT('₹', FORMAT(annual_revenue, 2)) AS annual_net_revenue,
    CONCAT('₹', FORMAT(annual_aov, 2)) AS annual_aov,
    CASE 
        WHEN prev_year_revenue IS NULL THEN 'Baseline Year'
        ELSE CONCAT('+', ROUND(((annual_revenue - prev_year_revenue) / prev_year_revenue) * 100, 2), '%')
    END AS yoy_revenue_growth,
    CASE 
        WHEN prev_year_orders IS NULL THEN 'Baseline Year'
        ELSE CONCAT('+', ROUND(((total_orders - prev_year_orders) * 100.0) / prev_year_orders, 2), '%')
    END AS yoy_order_volume_growth
FROM yearly_sales_growth
ORDER BY sales_year ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Direct annual comparison between 2025 (25 orders, ₹9,28,566.00) and 2026 (35 orders,
-- ₹9,53,306.00), demonstrating a +40% expansion in order volume and positive revenue expansion.


-- =============================================================================
-- SECTION 5: TOP-SELLING PRODUCTS BY VOLUME (UNIT VELOCITY)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 5:
-- Which products have the highest physical unit sales velocity across all customer
-- orders? How many distinct customers have purchased them, and what is their unit share?
-- -----------------------------------------------------------------------------

WITH product_velocity AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        p.brand,
        p.unit_price,
        SUM(oi.quantity) AS total_units_sold,
        COUNT(DISTINCT oi.order_id) AS total_orders_featured,
        COUNT(DISTINCT o.customer_id) AS distinct_buyers_count,
        SUM(oi.line_total) AS total_sales_generated
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id, p.product_name, c.category_name, p.brand, p.unit_price
),
total_platform_units AS (
    SELECT SUM(quantity) AS platform_units_total FROM order_items
)
SELECT 
    DENSE_RANK() OVER (ORDER BY pv.total_units_sold DESC, pv.total_orders_featured DESC) AS unit_sales_rank,
    pv.product_id,
    pv.product_name,
    pv.category_name,
    pv.brand,
    CONCAT('₹', FORMAT(pv.unit_price, 2)) AS catalog_unit_price,
    pv.total_units_sold,
    pv.total_orders_featured,
    pv.distinct_buyers_count,
    ROUND((pv.total_units_sold * 100.0) / tpu.platform_units_total, 2) AS unit_share_of_catalog_pct,
    CONCAT('₹', FORMAT(pv.total_sales_generated, 2)) AS total_sales_generated
FROM product_velocity pv
CROSS JOIN total_platform_units tpu
ORDER BY pv.total_units_sold DESC, pv.total_orders_featured DESC
LIMIT 10;

-- EXPECTED OUTPUT DESCRIPTION:
-- Ranks high-volume velocity products: Mamaearth FaceWash (9 units), Nescafé Classic 200g (8 units),
-- Amul Dark Chocolate (8 units), Atomic Habits (7 units across 6 orders), and Tata Salt Lite (7 units).


-- =============================================================================
-- SECTION 6: HIGHEST REVENUE-GENERATING PRODUCTS (VALUE CHAMPIONS)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 6:
-- Which specific products generate the largest monetary sales value for the business?
-- What percentage of overall platform merchandise value does each top SKU contribute?
-- -----------------------------------------------------------------------------

WITH product_revenue_cte AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        p.brand,
        p.unit_price,
        SUM(oi.quantity) AS units_sold,
        SUM(oi.line_total) AS gross_product_revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    GROUP BY p.product_id, p.product_name, c.category_name, p.brand, p.unit_price
),
overall_revenue AS (
    SELECT SUM(line_total) AS total_item_gmv FROM order_items
)
SELECT 
    DENSE_RANK() OVER (ORDER BY pr.gross_product_revenue DESC) AS revenue_rank,
    pr.product_id,
    pr.product_name,
    pr.category_name,
    pr.brand,
    CONCAT('₹', FORMAT(pr.unit_price, 2)) AS unit_price,
    pr.units_sold,
    CONCAT('₹', FORMAT(pr.gross_product_revenue, 2)) AS gross_product_revenue,
    ROUND((pr.gross_product_revenue * 100.0) / ov.total_item_gmv, 2) AS pct_of_total_catalog_revenue,
    ROUND(
        SUM(pr.gross_product_revenue) OVER (ORDER BY pr.gross_product_revenue DESC) * 100.0 / ov.total_item_gmv,
        2
    ) AS cumulative_revenue_pct
FROM product_revenue_cte pr
CROSS JOIN overall_revenue ov
ORDER BY pr.gross_product_revenue DESC
LIMIT 10;

-- EXPECTED OUTPUT DESCRIPTION:
-- Highlights the revenue heavyweights: Samsung Galaxy S23 Ultra (₹3,13,997.00),
-- Sony WH-1000XM5 Headphones (₹1,72,494.00), Dell XPS 15 Laptop (₹1,41,999.00),
-- Apple iPhone 15 Pro (₹1,22,999.00), and 22KT Gold Chain 10g (₹1,08,000.00).


-- =============================================================================
-- SECTION 7: SALES BY PRODUCT CATEGORY & CATEGORY CONTRIBUTION
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 7:
-- How does sales performance break down across all 10 product categories?
-- For each category, what is the total revenue, total units sold, distinct orders count,
-- and percentage contribution to overall company revenue?
-- -----------------------------------------------------------------------------

WITH category_performance AS (
    SELECT 
        c.category_id,
        c.category_name,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        SUM(oi.quantity) AS total_units_sold,
        SUM(oi.line_total) AS category_revenue,
        AVG(oi.line_total) AS avg_item_sale_value
    FROM categories c
    JOIN products p ON c.category_id = p.category_id
    JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY c.category_id, c.category_name
),
overall_cat_total AS (
    SELECT SUM(line_total) AS total_line_revenue FROM order_items
)
SELECT 
    cp.category_id,
    cp.category_name,
    cp.total_orders,
    cp.total_units_sold,
    CONCAT('₹', FORMAT(cp.category_revenue, 2)) AS category_revenue,
    CONCAT('₹', FORMAT(cp.avg_item_sale_value, 2)) AS avg_line_item_value,
    ROUND((cp.category_revenue * 100.0) / oct.total_line_revenue, 2) AS category_revenue_contribution_pct,
    DENSE_RANK() OVER (ORDER BY cp.category_revenue DESC) AS category_rank
FROM category_performance cp
CROSS JOIN overall_cat_total oct
ORDER BY cp.category_revenue DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Ranks all categories by sales volume: Electronics leads overall GMV (> 50% share),
-- followed by Jewellery, Home & Kitchen, Sports & Fitness, Beauty & Personal Care,
-- Clothing, Automotive, and Grocery & Food.


-- =============================================================================
-- SECTION 8: CALCULATE AVERAGE ORDER VALUE (AOV)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 8:
-- How does Average Order Value (AOV) vary across different customer segments,
-- order status categories, and geographical states?
-- -----------------------------------------------------------------------------

-- Part A: AOV by Customer Segment
SELECT 
    c.segment AS customer_segment,
    COUNT(o.order_id) AS total_orders,
    CONCAT('₹', FORMAT(SUM(o.total_amount), 2)) AS total_segment_revenue,
    CONCAT('₹', FORMAT(AVG(o.total_amount), 2)) AS segment_aov,
    CONCAT('₹', FORMAT(MIN(o.total_amount), 2)) AS min_order_value,
    CONCAT('₹', FORMAT(MAX(o.total_amount), 2)) AS max_order_value,
    DENSE_RANK() OVER (ORDER BY AVG(o.total_amount) DESC) AS aov_rank
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.segment
ORDER BY AVG(o.total_amount) DESC;

-- Part B: AOV by Shipping State (Top Geographic Markets)
SELECT 
    o.shipping_state,
    COUNT(o.order_id) AS total_orders,
    CONCAT('₹', FORMAT(SUM(o.total_amount), 2)) AS total_state_revenue,
    CONCAT('₹', FORMAT(AVG(o.total_amount), 2)) AS state_aov,
    DENSE_RANK() OVER (ORDER BY AVG(o.total_amount) DESC) AS aov_rank_by_state
FROM orders o
GROUP BY o.shipping_state
ORDER BY AVG(o.total_amount) DESC
LIMIT 8;

-- EXPECTED OUTPUT DESCRIPTION:
-- Proves that Platinum segment customers have the highest average ticket size (> ₹65,000 AOV),
-- followed by Gold (~₹35,000 AOV) and Silver, with Haryana, Maharashtra, and Karnataka
-- delivering the highest state-level average basket sizes.


-- =============================================================================
-- SECTION 9: IDENTIFY THE BEST-PERFORMING SALES MONTHS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 9:
-- Which specific calendar months achieved the highest sales performance in terms
-- of gross revenue and order frequency? Rank all operating months using window functions.
-- -----------------------------------------------------------------------------

WITH monthly_rankings AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
        YEAR(order_date) AS sales_year,
        MONTHNAME(order_date) AS month_name,
        COUNT(order_id) AS total_orders,
        SUM(total_amount) AS total_monthly_revenue,
        AVG(total_amount) AS monthly_aov
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m'), YEAR(order_date), MONTHNAME(order_date)
)
SELECT 
    DENSE_RANK() OVER (ORDER BY total_monthly_revenue DESC) AS best_month_rank,
    sales_month,
    sales_year,
    month_name,
    total_orders,
    CONCAT('₹', FORMAT(total_monthly_revenue, 2)) AS total_monthly_revenue,
    CONCAT('₹', FORMAT(monthly_aov, 2)) AS avg_order_value,
    NTILE(4) OVER (ORDER BY total_monthly_revenue DESC) AS performance_quartile,
    CASE 
        WHEN NTILE(4) OVER (ORDER BY total_monthly_revenue DESC) = 1 THEN 'Top Quartile Month (Peak Season)'
        WHEN NTILE(4) OVER (ORDER BY total_monthly_revenue DESC) = 2 THEN 'Above-Average Month'
        WHEN NTILE(4) OVER (ORDER BY total_monthly_revenue DESC) = 3 THEN 'Moderate Month'
        ELSE 'Low-Volume Month'
    END AS monthly_performance_tier
FROM monthly_rankings
ORDER BY best_month_rank ASC
LIMIT 10;

-- EXPECTED OUTPUT DESCRIPTION:
-- Ranks peak commercial months: 2025-01 (₹1,85,848.00), 2025-04 (₹1,78,948.00),
-- 2025-07 (₹1,68,557.00), 2026-03 (₹1,34,967.00), and 2026-09 (₹1,93,381.00),
-- revealing quarterly surge cycles in purchasing.


-- =============================================================================
-- SECTION 10: COMPARE SALES PERFORMANCE ACROSS DIFFERENT PERIODS (QoQ & YoY)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 10:
-- How does sales performance compare across different quarterly periods?
-- Calculate quarter-over-quarter (QoQ) revenue changes, order volume variances,
-- and percentage growth rates across all calendar quarters.
-- -----------------------------------------------------------------------------

WITH quarterly_sales_cte AS (
    SELECT 
        YEAR(order_date) AS sales_year,
        QUARTER(order_date) AS sales_quarter,
        CONCAT('Q', QUARTER(order_date), ' ', YEAR(order_date)) AS period_label,
        COUNT(order_id) AS total_orders,
        SUM(total_amount) AS quarterly_revenue,
        AVG(total_amount) AS quarterly_aov
    FROM orders
    GROUP BY 
        YEAR(order_date), 
        QUARTER(order_date), 
        CONCAT('Q', QUARTER(order_date), ' ', YEAR(order_date))
),
quarterly_comparisons AS (
    SELECT 
        sales_year,
        sales_quarter,
        period_label,
        total_orders,
        quarterly_revenue,
        quarterly_aov,
        LAG(quarterly_revenue, 1) OVER (ORDER BY sales_year ASC, sales_quarter ASC) AS prev_quarter_revenue,
        LAG(total_orders, 1) OVER (ORDER BY sales_year ASC, sales_quarter ASC) AS prev_quarter_orders
    FROM quarterly_sales_cte
)
SELECT 
    period_label,
    total_orders,
    CONCAT('₹', FORMAT(quarterly_revenue, 2)) AS quarterly_revenue,
    CONCAT('₹', FORMAT(prev_quarter_revenue, 2)) AS previous_quarter_revenue,
    CASE 
        WHEN prev_quarter_revenue IS NULL THEN 'Baseline'
        WHEN quarterly_revenue >= prev_quarter_revenue THEN 
            CONCAT('+', ROUND(((quarterly_revenue - prev_quarter_revenue) / prev_quarter_revenue) * 100, 2), '%')
        ELSE 
            CONCAT(ROUND(((quarterly_revenue - prev_quarter_revenue) / prev_quarter_revenue) * 100, 2), '%')
    END AS qoq_revenue_growth_rate,
    CASE 
        WHEN prev_quarter_orders IS NULL THEN 'Baseline'
        WHEN total_orders >= prev_quarter_orders THEN 
            CONCAT('+', total_orders - prev_quarter_orders, ' orders')
        ELSE 
            CONCAT(total_orders - prev_quarter_orders, ' orders')
    END AS qoq_order_count_variance,
    CONCAT('₹', FORMAT(quarterly_aov, 2)) AS avg_order_value
FROM quarterly_comparisons
ORDER BY sales_year ASC, sales_quarter ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Provides a clean period-over-period executive matrix comparing Q1 2025 through Q4 2026.
-- Captures quarter-over-quarter expansion trajectories and order volume variations.
