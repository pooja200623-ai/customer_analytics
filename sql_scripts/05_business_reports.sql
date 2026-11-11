-- =============================================================================
-- PROJECT : Customer Segmentation & Purchase Behavior Analytics
-- SCRIPT  : 05_business_reports.sql
-- PURPOSE : Executive-ready analytical summaries, comprehensive customer lifetime value
--           (LTV), quarterly business review (QBR), and strategic product KPIs.
-- CONCEPTS: Advanced CTEs, Multiple Window Functions (ROW_NUMBER, SUM OVER, AVG OVER),
--           Cross Joins, Complex Conditional Pivots, Subqueries.
-- ENGINE  : MySQL 8.0+
-- =============================================================================

USE customer_analytics;

-- -----------------------------------------------------------------------------
-- REPORT 1: Executive KPI Scorecard & High-Level Health Check
-- -----------------------------------------------------------------------------
-- Purpose: A single-row C-level summary of all primary business indicators:
--   - Total Customers & Active Accounts
--   - Total Gross Merchandise Value (GMV)
--   - Net Revenue (Subtotal - Discounts + Tax + Shipping)
--   - Total Orders Placed & Delivered
--   - Average Order Value (AOV)
--   - Average Customer Lifetime Spend
-- -----------------------------------------------------------------------------

WITH customer_stats AS (
    SELECT 
        COUNT(customer_id) AS total_customers,
        SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS active_customers
    FROM customers
),
order_stats AS (
    SELECT 
        COUNT(order_id) AS total_orders,
        SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_orders,
        SUM(CASE WHEN status = 'Returned' THEN 1 ELSE 0 END) AS returned_orders,
        SUM(subtotal) AS gross_subtotal,
        SUM(discount_amount) AS total_discounts_granted,
        SUM(tax_amount) AS total_tax_collected,
        SUM(shipping_charge) AS total_shipping_revenue,
        SUM(total_amount) AS net_company_revenue,
        AVG(total_amount) AS avg_order_value
    FROM orders
),
product_stats AS (
    SELECT 
        COUNT(product_id) AS catalog_skus_count,
        SUM(stock_quantity) AS total_units_in_stock
    FROM products
)
SELECT 
    cs.total_customers,
    cs.active_customers,
    CONCAT(ROUND((cs.active_customers * 100.0) / cs.total_customers, 1), '%') AS customer_health_rate,
    os.total_orders,
    os.delivered_orders,
    os.returned_orders,
    ps.catalog_skus_count,
    ps.total_units_in_stock,
    CONCAT('₹', FORMAT(os.gross_subtotal, 2)) AS gross_merchandise_subtotal,
    CONCAT('₹', FORMAT(os.total_discounts_granted, 2)) AS total_discounts_given,
    CONCAT('₹', FORMAT(os.total_shipping_revenue, 2)) AS shipping_charges_collected,
    CONCAT('₹', FORMAT(os.net_company_revenue, 2)) AS total_net_revenue,
    CONCAT('₹', FORMAT(os.avg_order_value, 2)) AS overall_avg_order_value,
    CONCAT('₹', FORMAT(os.net_company_revenue / cs.total_customers, 2)) AS avg_revenue_per_customer_arpu
FROM customer_stats cs
CROSS JOIN order_stats os
CROSS JOIN product_stats ps;

-- EXPECTED OUTPUT DESCRIPTION:
-- Produces an executive KPI dashboard summary table giving leadership immediate visibility
-- into sales performance, discount impact, and active user health.


-- -----------------------------------------------------------------------------
-- REPORT 2: Quarterly Business Review (QBR) Sales Matrix
-- -----------------------------------------------------------------------------
-- Purpose: Evaluates quarterly sales trajectory across 2025 and 2026, comparing
-- order counts, total discounts, tax, and net revenue quarter-over-quarter.
-- -----------------------------------------------------------------------------

WITH quarterly_data AS (
    SELECT 
        YEAR(order_date) AS order_year,
        QUARTER(order_date) AS order_quarter,
        CONCAT('Q', QUARTER(order_date), ' ', YEAR(order_date)) AS quarter_label,
        COUNT(order_id) AS total_orders,
        SUM(subtotal) AS gross_subtotal,
        SUM(discount_amount) AS total_discount,
        SUM(total_amount) AS net_sales
    FROM orders
    WHERE status != 'Cancelled'
    GROUP BY YEAR(order_date), QUARTER(order_date), CONCAT('Q', QUARTER(order_date), ' ', YEAR(order_date))
)
SELECT 
    quarter_label,
    total_orders,
    CONCAT('₹', FORMAT(gross_subtotal, 2)) AS gross_subtotal,
    CONCAT('₹', FORMAT(total_discount, 2)) AS total_discount,
    CONCAT('₹', FORMAT(net_sales, 2)) AS net_sales,
    ROUND((total_discount * 100.0) / NULLIF(gross_subtotal, 0), 2) AS effective_discount_rate_pct,
    CONCAT('₹', FORMAT(net_sales / total_orders, 2)) AS quarterly_aov,
    LAG(net_sales) OVER (ORDER BY order_year, order_quarter) AS prev_quarter_sales,
    CASE 
        WHEN LAG(net_sales) OVER (ORDER BY order_year, order_quarter) IS NULL THEN 'N/A'
        ELSE CONCAT(
            ROUND(((net_sales - LAG(net_sales) OVER (ORDER BY order_year, order_quarter)) / 
                   LAG(net_sales) OVER (ORDER BY order_year, order_quarter)) * 100, 2),
            '%'
        )
    END AS qoq_growth_rate
FROM quarterly_data
ORDER BY order_year ASC, order_quarter ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Summarizes financial performance on a quarterly rhythm (Q1 2025 through Q4 2026),
-- calculating QoQ expansion and tracking effective discount rates over time.


-- -----------------------------------------------------------------------------
-- REPORT 3: Complete Customer 360 Lifetime Profile (Single View of Customer)
-- -----------------------------------------------------------------------------
-- Purpose: Produces a holistic 360-degree analytical profile for every customer,
-- combining demographic info, loyalty tier, lifetime order counts, total spent,
-- favorite product category, preferred payment method, and last active date.
-- -----------------------------------------------------------------------------

WITH customer_spending_base AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.gender,
        c.segment,
        CONCAT(c.city, ', ', c.state) AS location,
        c.registration_date,
        COUNT(DISTINCT o.order_id) AS lifetime_orders,
        COALESCE(SUM(o.total_amount), 0) AS lifetime_spend,
        COALESCE(AVG(o.total_amount), 0) AS customer_aov,
        MAX(o.order_date) AS most_recent_order
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status != 'Cancelled'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.gender, c.segment, c.city, c.state, c.registration_date
),
customer_fav_category AS (
    SELECT 
        o.customer_id,
        cat.category_name,
        COUNT(*) AS category_purchases,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY COUNT(*) DESC) AS rn
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories cat ON p.category_id = cat.category_id
    GROUP BY o.customer_id, cat.category_name
),
customer_fav_payment AS (
    SELECT 
        o.customer_id,
        pm.method,
        COUNT(*) AS method_uses,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY COUNT(*) DESC) AS rn
    FROM orders o
    JOIN payments pm ON o.order_id = pm.order_id
    GROUP BY o.customer_id, pm.method
)
SELECT 
    cs.customer_id,
    cs.customer_name,
    cs.email,
    cs.segment AS loyalty_segment,
    cs.location,
    cs.lifetime_orders,
    CONCAT('₹', FORMAT(cs.lifetime_spend, 2)) AS lifetime_spend,
    CONCAT('₹', FORMAT(cs.customer_aov, 2)) AS average_order_value,
    COALESCE(fc.category_name, 'None') AS preferred_category,
    COALESCE(fp.method, 'None') AS preferred_payment_method,
    COALESCE(DATE_FORMAT(cs.most_recent_order, '%Y-%m-%d'), 'Never Ordered') AS last_order_date,
    DENSE_RANK() OVER (ORDER BY cs.lifetime_spend DESC) AS overall_customer_rank
FROM customer_spending_base cs
LEFT JOIN customer_fav_category fc ON cs.customer_id = fc.customer_id AND fc.rn = 1
LEFT JOIN customer_fav_payment fp ON cs.customer_id = fp.customer_id AND fp.rn = 1
ORDER BY cs.lifetime_spend DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Master Customer 360 table giving marketing, operations, and support teams an
-- exhaustive profile of each buyer, ranked by total lifetime monetary contribution.
