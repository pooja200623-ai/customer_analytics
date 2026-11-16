-- =============================================================================
-- PROJECT : Customer Segmentation & Purchase Behavior Analytics Using SQL
-- FILE    : reporting_views.sql
-- PURPOSE : Reusable Database Views for BI Reporting & Analytics Layer
--           Materializes standard analytical reporting structures:
--             1. view_customer_rfm_segments
--                Customer segmentation based on Recency, Frequency & Monetary metrics
--             2. view_customer_purchase_summary
--                Customer order counts, lifetime spending, AOV, and last purchase date
--             3. view_monthly_sales_summary
--                Monthly order volume, gross revenue, net revenue, and average order value
--             4. view_product_performance
--                Product-level units sold, order frequency, gross & net sales revenue
--
-- DESIGN PRINCIPLES:
--   - 100% MySQL 8.0+ compatible (CREATE OR REPLACE VIEW)
--   - Strictly avoids JOIN fan-out by using pre-aggregated CTEs/subqueries
--   - Preserves referential integrity and standard database naming conventions
--   - Handles inactive/zero-order customers gracefully using LEFT JOIN & COALESCE
-- =============================================================================

USE customer_analytics;


-- =============================================================================
-- VIEW 1: view_customer_rfm_segments
-- =============================================================================
-- Description:
--   Segments customers dynamically using standard RFM (Recency, Frequency,
--   Monetary) analysis based on their transactional history in the orders table.
--
-- Available Schema Metrics & Definitions:
--   - Recency (R)   : Days elapsed between the customer's most recent order date
--                     and CURRENT_DATE. Handled gracefully with NULL for customers
--                     with no orders.
--   - Frequency (F) : Count of distinct orders placed (COUNT(DISTINCT order_id)).
--   - Monetary (M)  : Total net expenditure (SUM(total_amount)) across orders.
--
-- Fan-out Protection:
--   Directly aggregates the `orders` header table without joining to `order_items`
--   or `payments`, preventing duplicate count and spending inflation.
-- =============================================================================

CREATE OR REPLACE VIEW view_customer_rfm_segments AS
WITH customer_orders_aggregated AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS frequency_orders,
        COALESCE(SUM(total_amount), 0.00) AS monetary_spend,
        COALESCE(AVG(total_amount), 0.00) AS avg_order_value,
        MAX(order_date) AS last_order_date,
        DATEDIFF(CURRENT_DATE, MAX(order_date)) AS recency_days
    FROM orders
    GROUP BY customer_id
),
customer_rfm_base AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.segment AS registered_segment,
        c.city,
        c.state,
        c.registration_date,
        COALESCE(coa.frequency_orders, 0) AS total_orders,
        COALESCE(coa.monetary_spend, 0.00) AS total_spending,
        COALESCE(coa.avg_order_value, 0.00) AS average_order_value,
        coa.last_order_date,
        coa.recency_days,
        PERCENT_RANK() OVER (
            ORDER BY COALESCE(coa.monetary_spend, 0.00) ASC
        ) AS monetary_percentile
    FROM customers c
    LEFT JOIN customer_orders_aggregated coa ON c.customer_id = coa.customer_id
)
SELECT 
    customer_id,
    customer_name,
    email,
    registered_segment,
    city,
    state,
    registration_date,
    total_orders,
    total_spending,
    average_order_value,
    last_order_date,
    recency_days,
    ROUND(monetary_percentile * 100, 2) AS monetary_percentile_pct,
    CASE 
        -- Rule 1: Never purchased
        WHEN total_orders = 0 THEN 'Never Purchased (Prospect)'
        
        -- Rule 2: Top Spenders & Active Repeat Buyers
        WHEN monetary_percentile >= 0.75 AND total_orders >= 3 AND recency_days <= 120 
            THEN 'VIP Champion'
            
        -- Rule 3: High-Value Spenders regardless of frequency
        WHEN monetary_percentile >= 0.75 AND recency_days <= 180 
            THEN 'High-Value Customer'
            
        -- Rule 4: Loyal Frequent Shoppers
        WHEN total_orders >= 3 AND recency_days <= 180 
            THEN 'Loyal Customer'
            
        -- Rule 5: Returning Buyers
        WHEN total_orders = 2 AND recency_days <= 180 
            THEN 'Returning Customer'
            
        -- Rule 6: Recent First-Time Buyer
        WHEN total_orders = 1 AND recency_days <= 90 
            THEN 'New Customer'
            
        -- Rule 7: Dormant / At-Risk Account
        WHEN recency_days > 180 
            THEN 'At-Risk / Dormant'
            
        -- Default fallback
        ELSE 'Active Regular Customer'
    END AS dynamic_rfm_segment
FROM customer_rfm_base;


-- =============================================================================
-- VIEW 2: view_customer_purchase_summary
-- =============================================================================
-- Description:
--   Comprehensive customer purchasing lifetime summary, reporting total orders,
--   total lifetime spending, average order value (AOV), and most recent purchase
--   date for every registered customer.
--
-- Fan-out Protection:
--   Pre-aggregates `orders` in a CTE before joining to `customers`, guaranteeing
--   that order totals are not replicated or inflated. Customers with zero orders
--   are preserved with 0 values and NULL dates.
-- =============================================================================

CREATE OR REPLACE VIEW view_customer_purchase_summary AS
WITH customer_order_totals AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders,
        SUM(subtotal) AS total_subtotal,
        SUM(discount_amount) AS total_discounts,
        SUM(tax_amount) AS total_tax,
        SUM(shipping_charge) AS total_shipping,
        SUM(total_amount) AS total_spending,
        AVG(total_amount) AS average_order_value,
        MIN(order_date) AS first_purchase_date,
        MAX(order_date) AS last_purchase_date
    FROM orders
    GROUP BY customer_id
)
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    c.phone,
    c.gender,
    c.segment AS static_segment,
    c.city,
    c.state,
    c.registration_date,
    COALESCE(cot.total_orders, 0) AS total_orders,
    COALESCE(cot.total_subtotal, 0.00) AS total_subtotal,
    COALESCE(cot.total_discounts, 0.00) AS total_discounts,
    COALESCE(cot.total_tax, 0.00) AS total_tax,
    COALESCE(cot.total_shipping, 0.00) AS total_shipping,
    COALESCE(cot.total_spending, 0.00) AS total_spending,
    COALESCE(cot.average_order_value, 0.00) AS average_order_value,
    cot.first_purchase_date,
    cot.last_purchase_date,
    CASE 
        WHEN cot.last_purchase_date IS NULL THEN NULL 
        ELSE DATEDIFF(CURRENT_DATE, cot.last_purchase_date) 
    END AS days_since_last_purchase
FROM customers c
LEFT JOIN customer_order_totals cot ON c.customer_id = cot.customer_id;


-- =============================================================================
-- VIEW 3: view_monthly_sales_summary
-- =============================================================================
-- Description:
--   Monthly sales performance tracking total order volume, distinct buyers,
--   gross subtotal, total discounts, net revenue, and average order value (AOV)
--   grouped by calendar year and month.
--
-- Fan-out Protection:
--   Aggregates directly from `orders` at the order header level without joining
--   child tables.
-- =============================================================================

CREATE OR REPLACE VIEW view_monthly_sales_summary AS
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS sales_month,
    YEAR(order_date) AS sales_year,
    MONTH(order_date) AS sales_month_num,
    MONTHNAME(order_date) AS sales_month_name,
    COUNT(order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_buyers,
    SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_orders,
    SUM(CASE WHEN status = 'Returned' THEN 1 ELSE 0 END) AS returned_orders,
    SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    SUM(subtotal) AS gross_subtotal,
    SUM(discount_amount) AS total_discounts,
    SUM(tax_amount) AS total_tax,
    SUM(shipping_charge) AS total_shipping,
    SUM(total_amount) AS net_revenue,
    AVG(total_amount) AS average_order_value
FROM orders
GROUP BY 
    DATE_FORMAT(order_date, '%Y-%m'),
    YEAR(order_date),
    MONTH(order_date),
    MONTHNAME(order_date);


-- =============================================================================
-- VIEW 4: view_product_performance
-- =============================================================================
-- Description:
--   Product-wise sales analytics reporting total physical units sold, distinct
--   order appearances, distinct purchasing customers, gross catalog sales,
--   and net sales revenue generated after item discounts.
--
-- Fan-out Protection:
--   Aggregates `order_items` at the product level before joining with `products`
--   and `categories`. Avoids joining `orders` directly to prevent row Cartesian
--   multiplication across multiple parent/child attributes.
-- =============================================================================

CREATE OR REPLACE VIEW view_product_performance AS
WITH product_sales_aggregated AS (
    SELECT 
        oi.product_id,
        COUNT(DISTINCT oi.order_id) AS order_appearances_count,
        SUM(oi.quantity) AS total_units_sold,
        SUM(oi.quantity * oi.unit_price) AS gross_product_revenue,
        SUM(oi.line_total) AS net_product_revenue,
        AVG(oi.discount_pct) AS avg_item_discount_pct
    FROM order_items oi
    GROUP BY oi.product_id
),
product_buyer_counts AS (
    SELECT 
        oi.product_id,
        COUNT(DISTINCT o.customer_id) AS distinct_buyers_count
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    p.brand,
    c.category_id,
    c.category_name,
    p.unit_price AS catalog_unit_price,
    p.cost_price,
    p.stock_quantity,
    p.is_active,
    COALESCE(psa.total_units_sold, 0) AS total_units_sold,
    COALESCE(psa.order_appearances_count, 0) AS total_orders_featured,
    COALESCE(pbc.distinct_buyers_count, 0) AS distinct_buyers_count,
    COALESCE(psa.gross_product_revenue, 0.00) AS gross_product_revenue,
    COALESCE(psa.net_product_revenue, 0.00) AS net_product_revenue,
    COALESCE(psa.avg_item_discount_pct, 0.00) AS avg_item_discount_pct,
    -- Estimated Gross Profit calculation when cost_price is populated
    CASE 
        WHEN p.cost_price IS NOT NULL AND psa.total_units_sold IS NOT NULL 
            THEN psa.net_product_revenue - (psa.total_units_sold * p.cost_price)
        ELSE NULL 
    END AS estimated_gross_profit
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN product_sales_aggregated psa ON p.product_id = psa.product_id
LEFT JOIN product_buyer_counts pbc ON p.product_id = pbc.product_id;
