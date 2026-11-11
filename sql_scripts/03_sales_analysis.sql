-- =============================================================================
-- PROJECT : Customer Segmentation & Purchase Behavior Analytics
-- SCRIPT  : 03_sales_analysis.sql
-- PURPOSE : Revenue trajectory analysis, Year-over-Year (YoY) & Month-over-Month (MoM)
--           growth, category profitability, top-selling SKUs, and order fulfillment status.
-- CONCEPTS: CTEs, Window Functions (SUM OVER, LAG, DENSE_RANK), Moving Averages,
--           Date Parsing & Truncation, Multi-level Aggregation.
-- ENGINE  : MySQL 8.0+
-- =============================================================================

USE customer_analytics;

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 1: Monthly Sales Trend & Month-over-Month (MoM) Growth Rate
-- -----------------------------------------------------------------------------
-- What is the month-over-month revenue trajectory, order volume, and percentage growth
-- in sales across all historical months?
-- -----------------------------------------------------------------------------

WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
        COUNT(order_id) AS total_orders,
        SUM(total_amount) AS monthly_revenue,
        AVG(total_amount) AS avg_order_value
    FROM orders
    WHERE status != 'Cancelled'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
monthly_mom AS (
    SELECT 
        sales_month,
        total_orders,
        monthly_revenue,
        avg_order_value,
        LAG(monthly_revenue, 1) OVER (ORDER BY sales_month ASC) AS prev_month_revenue,
        SUM(monthly_revenue) OVER (ORDER BY sales_month ASC) AS running_cumulative_revenue
    FROM monthly_sales
)
SELECT 
    sales_month,
    total_orders,
    CONCAT('₹', FORMAT(monthly_revenue, 2)) AS monthly_revenue,
    CONCAT('₹', FORMAT(prev_month_revenue, 2)) AS previous_month_revenue,
    CASE 
        WHEN prev_month_revenue IS NULL THEN 'N/A (Baseline)'
        ELSE CONCAT(ROUND(((monthly_revenue - prev_month_revenue) / prev_month_revenue) * 100, 2), '%')
    END AS mom_revenue_growth_pct,
    CONCAT('₹', FORMAT(running_cumulative_revenue, 2)) AS running_cumulative_revenue,
    CONCAT('₹', FORMAT(avg_order_value, 2)) AS avg_order_value
FROM monthly_mom
ORDER BY sales_month ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Shows steady commercial growth from Jan 2025 through Nov 2026, tracking cumulative
-- Gross Merchandise Value (GMV) and percentage fluctuations month-by-month.


-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 2: Product Category Performance & Profit Margin Analysis
-- -----------------------------------------------------------------------------
-- Which product categories generate the highest gross revenue, highest units sold,
-- and greatest gross profit margin (Revenue - Cost)?
-- -----------------------------------------------------------------------------

WITH category_sales AS (
    SELECT 
        c.category_name,
        COUNT(DISTINCT oi.order_id) AS orders_count,
        SUM(oi.quantity) AS total_units_sold,
        SUM(oi.line_total) AS gross_sales_value,
        SUM(oi.quantity * COALESCE(p.cost_price, 0)) AS total_cost_of_goods_sold
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status != 'Cancelled'
    GROUP BY c.category_id, c.category_name
),
category_profit AS (
    SELECT 
        category_name,
        orders_count,
        total_units_sold,
        gross_sales_value,
        total_cost_of_goods_sold,
        (gross_sales_value - total_cost_of_goods_sold) AS gross_profit,
        ROUND(((gross_sales_value - total_cost_of_goods_sold) / NULLIF(gross_sales_value, 0)) * 100, 2) AS gross_margin_pct
    FROM category_sales
)
SELECT 
    category_name,
    orders_count,
    total_units_sold,
    CONCAT('₹', FORMAT(gross_sales_value, 2)) AS gross_sales,
    CONCAT('₹', FORMAT(total_cost_of_goods_sold, 2)) AS total_cogs,
    CONCAT('₹', FORMAT(gross_profit, 2)) AS gross_profit,
    CONCAT(gross_margin_pct, '%') AS gross_margin_pct,
    DENSE_RANK() OVER (ORDER BY gross_sales_value DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY gross_profit DESC) AS profit_rank
FROM category_profit
ORDER BY gross_sales_value DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Ranks categories by revenue and profitability. Electronics leads in sheer GMV,
-- while Clothing, Books & Stationery, and Beauty yield superior percentage gross margins (> 40%).


-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 3: Top 10 Best-Selling SKUs by Revenue and Unit Velocity
-- -----------------------------------------------------------------------------
-- What are the top 10 individual products by total revenue contribution?
-- -----------------------------------------------------------------------------

SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    p.brand,
    CONCAT('₹', FORMAT(p.unit_price, 2)) AS catalog_unit_price,
    SUM(oi.quantity) AS total_units_sold,
    CONCAT('₹', FORMAT(SUM(oi.line_total), 2)) AS total_product_revenue,
    DENSE_RANK() OVER (ORDER BY SUM(oi.line_total) DESC) AS rank_by_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status != 'Cancelled'
GROUP BY p.product_id, p.product_name, c.category_name, p.brand, p.unit_price
ORDER BY SUM(oi.line_total) DESC
LIMIT 10;

-- EXPECTED OUTPUT DESCRIPTION:
-- Pinpoints champion SKUs (Samsung Galaxy S23 Ultra, Dell XPS 15, iPhone 15 Pro, 22KT Gold Chain),
-- providing supply chain teams with essential demand velocity data.


-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 4: Order Fulfillment & Delivery SLA Performance
-- -----------------------------------------------------------------------------
-- What is the status breakdown of all orders (Delivered, Shipped, Processing, Pending, Returned)?
-- For delivered orders, what percentage were delivered on or before the estimated delivery date?
-- -----------------------------------------------------------------------------

SELECT 
    status AS order_status,
    COUNT(order_id) AS total_orders,
    ROUND((COUNT(order_id) * 100.0) / (SELECT COUNT(*) FROM orders), 2) AS status_share_pct,
    CONCAT('₹', FORMAT(SUM(total_amount), 2)) AS total_order_value,
    SUM(CASE WHEN actual_delivery <= estimated_delivery THEN 1 ELSE 0 END) AS on_time_deliveries,
    SUM(CASE WHEN actual_delivery > estimated_delivery THEN 1 ELSE 0 END) AS delayed_deliveries,
    ROUND(
        (SUM(CASE WHEN actual_delivery <= estimated_delivery THEN 1 ELSE 0 END) * 100.0) / 
        NULLIF(SUM(CASE WHEN actual_delivery IS NOT NULL THEN 1 ELSE 0 END), 0),
        2
    ) AS on_time_delivery_sla_pct
FROM orders
GROUP BY status
ORDER BY total_orders DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Delivers an executive overview of logistics fulfillment SLAs, verifying that > 95% of
-- fulfilled orders met or beat promised delivery dates.
