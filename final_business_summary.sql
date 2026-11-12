-- =============================================================================
-- PROJECT  : Customer Segmentation & Purchase Behavior Analytics Using SQL
-- FILE     : final_business_summary.sql
-- PURPOSE  : Final Business Summary — 10 executive-level KPI modules
-- ENGINE   : MySQL 8.0+
-- CHARSET  : utf8mb4 / utf8mb4_unicode_ci
-- CREATED  : 2026-11-12
-- NOTE     : Read-only. Zero INSERT / UPDATE / DELETE / DDL statements.
--            Run schema.sql + sample_data.sql before executing.
--            All monetary values are in Indian Rupees (INR ₹).
-- =============================================================================

USE customer_analytics;

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION INDEX
-- ─────────────────────────────────────────────────────────────────────────────
--  1.  TOTAL NUMBER OF CUSTOMERS
--      1a. Overall customer count
--      1b. Customer count by registration year
--      1c. Active vs inactive customer split
--
--  2.  TOTAL NUMBER OF ORDERS
--      2a. Overall order count
--      2b. Order count by status
--      2c. Orders per year
--
--  3.  TOTAL SALES REVENUE
--      3a. Gross and net revenue overview
--      3b. Revenue by order status
--      3c. Revenue contribution by country / state
--
--  4.  AVERAGE ORDER VALUE (AOV)
--      4a. Overall AOV
--      4b. AOV by customer segment
--      4c. AOV by order status
--
--  5.  TOP 5 HIGHEST-SPENDING CUSTOMERS
--      5a. By lifetime total_amount paid
--      5b. With order count, AOV, and segment details
--
--  6.  TOP 5 BEST-SELLING PRODUCTS
--      6a. By total units sold
--      6b. By total revenue generated
--
--  7.  MOST PROFITABLE PRODUCT CATEGORIES
--      7a. Revenue, cost, and gross profit per category
--      7b. Category profit margin ranking
--
--  8.  CUSTOMER SEGMENT DISTRIBUTION
--      8a. Count and percentage per segment
--      8b. Revenue and AOV per segment
--
--  9.  CUSTOMER RETENTION SUMMARY
--      9a. Single-order vs repeat customers
--      9b. Repeat purchase rate
--      9c. Customer lifetime order frequency
--
-- 10.  MONTHLY SALES PERFORMANCE
--      10a. Month-by-month revenue and order count
--      10b. Month-over-month revenue growth
--      10c. Best and worst performing months
-- ─────────────────────────────────────────────────────────────────────────────


-- =============================================================================
-- SECTION 1 — TOTAL NUMBER OF CUSTOMERS
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1a. Overall Customer Count
-- ---------------------------------------------------------------------------
-- Business Question:
--   How many customers are currently registered in the platform?
--   This is the fundamental audience size metric used in all per-customer
--   KPI calculations.
--
-- Joins / Aggregates : COUNT on customers table
--
-- Expected Output:
--   A single summary row showing:
--   total_customers — the absolute count of all registered customers.
--   active_customers — customers with is_active = 1.
--   inactive_customers — customers with is_active = 0.
--   newest_registration — the most recent registration date.
--   oldest_registration — the earliest registration date.
-- ---------------------------------------------------------------------------

SELECT
    COUNT(*)                                                   AS total_customers,
    SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END)            AS active_customers,
    SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END)            AS inactive_customers,
    MIN(registration_date)                                     AS oldest_registration,
    MAX(registration_date)                                     AS newest_registration,
    DATEDIFF(MAX(registration_date), MIN(registration_date))   AS days_span_of_registrations
FROM customers;


-- ---------------------------------------------------------------------------
-- 1b. Customer Count by Registration Year
-- ---------------------------------------------------------------------------
-- Business Question:
--   How has the customer base grown year over year? Understanding acquisition
--   velocity per year informs marketing budget allocation and growth planning.
--
-- Joins / Aggregates : COUNT + GROUP BY YEAR(registration_date)
--
-- Expected Output:
--   One row per registration year showing the number of new customers
--   acquired that year, with a running cumulative total.
-- ---------------------------------------------------------------------------

SELECT
    YEAR(registration_date)                                    AS registration_year,
    COUNT(*)                                                   AS new_customers,
    SUM(COUNT(*)) OVER (ORDER BY YEAR(registration_date))      AS cumulative_customers
FROM customers
GROUP BY YEAR(registration_date)
ORDER BY registration_year;


-- ---------------------------------------------------------------------------
-- 1c. Active vs Inactive Customer Split
-- ---------------------------------------------------------------------------
-- Business Question:
--   What proportion of the customer base is currently active? A high inactive
--   rate may indicate churn problems or stale data that needs archiving.
--
-- Joins / Aggregates : COUNT + CASE + subquery for percentage
--
-- Expected Output:
--   Two rows (Active / Inactive) with count and percentage of total.
-- ---------------------------------------------------------------------------

SELECT
    CASE WHEN is_active = 1 THEN 'Active' ELSE 'Inactive' END  AS customer_status,
    COUNT(*)                                                    AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)         AS pct_of_total
FROM customers
GROUP BY is_active
ORDER BY is_active DESC;


-- =============================================================================
-- SECTION 2 — TOTAL NUMBER OF ORDERS
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 2a. Overall Order Count
-- ---------------------------------------------------------------------------
-- Business Question:
--   How many orders have been placed across the entire history of the
--   platform? This is the foundational transaction volume metric.
--
-- Joins / Aggregates : COUNT on orders table
--
-- Expected Output:
--   Single row with total orders, the date range of orders, and the number
--   of distinct customers who have ever ordered.
-- ---------------------------------------------------------------------------

SELECT
    COUNT(order_id)                             AS total_orders,
    COUNT(DISTINCT customer_id)                 AS ordering_customers,
    MIN(DATE(order_date))                       AS first_order_date,
    MAX(DATE(order_date))                       AS last_order_date,
    DATEDIFF(MAX(order_date), MIN(order_date))  AS days_of_trading
FROM orders;


-- ---------------------------------------------------------------------------
-- 2b. Order Count by Status
-- ---------------------------------------------------------------------------
-- Business Question:
--   What is the current pipeline of orders across all fulfillment stages?
--   Understanding the split across Pending / Confirmed / Shipped / Delivered
--   / Cancelled / Returned helps operations teams prioritise workload.
--
-- Joins / Aggregates : COUNT + GROUP BY status
--
-- Expected Output:
--   One row per status showing count, percentage of total, and total revenue
--   tied to orders in that status.
-- ---------------------------------------------------------------------------

SELECT
    status,
    COUNT(order_id)                                             AS order_count,
    ROUND(COUNT(order_id) * 100.0 / SUM(COUNT(order_id)) OVER (), 2)
                                                                AS pct_of_total,
    ROUND(SUM(total_amount), 2)                                 AS total_revenue,
    ROUND(AVG(total_amount), 2)                                 AS avg_order_value
FROM orders
GROUP BY status
ORDER BY order_count DESC;


-- ---------------------------------------------------------------------------
-- 2c. Orders Per Year
-- ---------------------------------------------------------------------------
-- Business Question:
--   Is order volume growing year on year? Year-over-year order growth is a
--   primary indicator of business momentum.
--
-- Joins / Aggregates : COUNT + GROUP BY YEAR
--
-- Expected Output:
--   One row per year showing order count, total revenue that year, and
--   average order value for the year.
-- ---------------------------------------------------------------------------

SELECT
    YEAR(order_date)            AS order_year,
    COUNT(order_id)             AS total_orders,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_order_value,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM orders
GROUP BY YEAR(order_date)
ORDER BY order_year;


-- =============================================================================
-- SECTION 3 — TOTAL SALES REVENUE
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 3a. Gross and Net Revenue Overview
-- ---------------------------------------------------------------------------
-- Business Question:
--   What is the platform's overall gross revenue (subtotal before discounts),
--   total discounts given, total taxes collected, shipping income, and
--   net revenue (total_amount)? This is the top-line P&L headline.
--
-- Joins / Aggregates : SUM aggregates on orders table
--
-- Expected Output:
--   Single row with gross_revenue, total_discounts, total_tax, total_shipping,
--   net_revenue, and effective discount rate as a percentage.
-- ---------------------------------------------------------------------------

SELECT
    ROUND(SUM(subtotal), 2)                                     AS gross_revenue,
    ROUND(SUM(discount_amount), 2)                              AS total_discounts,
    ROUND(SUM(tax_amount), 2)                                   AS total_tax_collected,
    ROUND(SUM(shipping_charge), 2)                              AS total_shipping_income,
    ROUND(SUM(total_amount), 2)                                 AS net_revenue,
    ROUND(SUM(discount_amount) / SUM(subtotal) * 100, 2)        AS discount_rate_pct,
    ROUND(SUM(tax_amount) / SUM(subtotal) * 100, 2)             AS effective_tax_rate_pct
FROM orders
WHERE status NOT IN ('Cancelled', 'Returned');


-- ---------------------------------------------------------------------------
-- 3b. Revenue by Order Status
-- ---------------------------------------------------------------------------
-- Business Question:
--   How much revenue is locked in each order status stage? Revenue in
--   'Pending' or 'Processing' represents exposure; revenue in 'Returned'
--   or 'Cancelled' represents value already lost.
--
-- Joins / Aggregates : SUM + GROUP BY status
--
-- Expected Output:
--   One row per status with subtotal, discounts, net revenue, and percentage
--   of platform-wide revenue.
-- ---------------------------------------------------------------------------

WITH total_rev AS (
    SELECT SUM(total_amount) AS grand_total FROM orders
)
SELECT
    o.status,
    COUNT(o.order_id)                                           AS order_count,
    ROUND(SUM(o.subtotal), 2)                                   AS gross_revenue,
    ROUND(SUM(o.discount_amount), 2)                            AS discounts_given,
    ROUND(SUM(o.total_amount), 2)                               AS net_revenue,
    ROUND(SUM(o.total_amount) / tr.grand_total * 100, 2)        AS pct_of_total_revenue
FROM orders o
CROSS JOIN total_rev tr
GROUP BY o.status, tr.grand_total
ORDER BY net_revenue DESC;


-- ---------------------------------------------------------------------------
-- 3c. Revenue Contribution by State
-- ---------------------------------------------------------------------------
-- Business Question:
--   Which Indian states generate the most revenue? Geographic revenue
--   concentration informs regional logistics investment and marketing spend.
--
-- Joins / Aggregates : SUM + GROUP BY shipping_state + window function
--
-- Expected Output:
--   One row per shipping state with order count, total revenue, percentage
--   of total revenue, and cumulative revenue share (Pareto view).
-- ---------------------------------------------------------------------------

WITH state_revenue AS (
    SELECT
        shipping_state,
        COUNT(order_id)             AS order_count,
        ROUND(SUM(total_amount), 2) AS total_revenue
    FROM orders
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY shipping_state
),
grand AS (
    SELECT SUM(total_revenue) AS grand_total FROM state_revenue
)
SELECT
    sr.shipping_state,
    sr.order_count,
    sr.total_revenue,
    ROUND(sr.total_revenue / g.grand_total * 100, 2)            AS revenue_pct,
    ROUND(
        SUM(sr.total_revenue) OVER (
            ORDER BY sr.total_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / g.grand_total * 100, 2
    )                                                           AS cumulative_revenue_pct
FROM state_revenue sr
CROSS JOIN grand g
ORDER BY sr.total_revenue DESC;


-- =============================================================================
-- SECTION 4 — AVERAGE ORDER VALUE (AOV)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 4a. Overall Average Order Value
-- ---------------------------------------------------------------------------
-- Business Question:
--   What is the platform's average order value (AOV)? AOV is a key growth
--   lever — increasing it via upsell and cross-sell improves revenue without
--   acquiring new customers.
--
-- Joins / Aggregates : AVG + COUNT + SUM
--
-- Expected Output:
--   Single summary row with overall AOV, median-proxy (via ordering), min,
--   and max order values, plus count of orders included.
-- ---------------------------------------------------------------------------

SELECT
    COUNT(order_id)                             AS orders_included,
    ROUND(MIN(total_amount), 2)                 AS min_order_value,
    ROUND(MAX(total_amount), 2)                 AS max_order_value,
    ROUND(AVG(total_amount), 2)                 AS avg_order_value,
    ROUND(SUM(total_amount), 2)                 AS total_revenue,
    ROUND(STDDEV(total_amount), 2)              AS std_dev_order_value
FROM orders
WHERE status NOT IN ('Cancelled', 'Returned');


-- ---------------------------------------------------------------------------
-- 4b. Average Order Value by Customer Segment
-- ---------------------------------------------------------------------------
-- Business Question:
--   Do higher-tier customer segments (Platinum, Gold) place larger orders?
--   Segment-level AOV guides tier-benefit design and upsell strategies.
--
-- Joins / Aggregates : JOIN + AVG + GROUP BY segment
--
-- Expected Output:
--   One row per segment showing order count, total revenue, AOV, and
--   the segment's share of platform revenue. Ordered by AOV descending.
-- ---------------------------------------------------------------------------

WITH segment_stats AS (
    SELECT
        c.segment,
        COUNT(o.order_id)                AS order_count,
        ROUND(SUM(o.total_amount), 2)    AS total_revenue,
        ROUND(AVG(o.total_amount), 2)    AS avg_order_value,
        COUNT(DISTINCT o.customer_id)    AS customer_count
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.status NOT IN ('Cancelled', 'Returned')
    GROUP BY c.segment
),
grand AS (SELECT SUM(total_revenue) AS grand_total FROM segment_stats)
SELECT
    ss.segment,
    ss.customer_count,
    ss.order_count,
    ss.total_revenue,
    ss.avg_order_value,
    ROUND(ss.total_revenue / g.grand_total * 100, 2)   AS revenue_pct
FROM segment_stats ss
CROSS JOIN grand g
ORDER BY ss.avg_order_value DESC;


-- ---------------------------------------------------------------------------
-- 4c. Average Order Value by Payment Method
-- ---------------------------------------------------------------------------
-- Business Question:
--   Do customers paying via EMI or Credit Card spend more per order than
--   those using Cash on Delivery or UPI? Payment-method AOV can guide
--   checkout incentive design (e.g., 5% cashback on Credit Card orders).
--
-- Joins / Aggregates : JOIN payments + orders + AVG + GROUP BY method
--
-- Expected Output:
--   One row per payment method with number of orders, total amount paid
--   via that method, and effective AOV.
-- ---------------------------------------------------------------------------

SELECT
    pay.method                              AS payment_method,
    COUNT(DISTINCT pay.order_id)            AS order_count,
    ROUND(SUM(pay.amount), 2)               AS total_collected,
    ROUND(AVG(o.total_amount), 2)           AS avg_order_value,
    ROUND(MIN(o.total_amount), 2)           AS min_order_value,
    ROUND(MAX(o.total_amount), 2)           AS max_order_value
FROM payments pay
JOIN orders o ON o.order_id = pay.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
  AND pay.status IN ('Captured', 'Authorized')
GROUP BY pay.method
ORDER BY avg_order_value DESC;


-- =============================================================================
-- SECTION 5 — TOP 5 HIGHEST-SPENDING CUSTOMERS
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 5a. Top 5 Customers by Lifetime Spend
-- ---------------------------------------------------------------------------
-- Business Question:
--   Who are the five customers who have spent the most money on the platform
--   over their entire lifetime? These VIP customers deserve white-glove
--   treatment, loyalty rewards, and dedicated account management.
--
-- Joins / Aggregates : JOIN + SUM + GROUP BY customer + ORDER BY + LIMIT
--
-- Expected Output:
--   Rank, customer_id, full name, city, segment, number of orders,
--   total lifetime spend, and average spend per order. Limited to 5 rows.
-- ---------------------------------------------------------------------------

SELECT
    RANK() OVER (ORDER BY SUM(o.total_amount) DESC)     AS spend_rank,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)              AS customer_name,
    c.email,
    c.city,
    c.state,
    c.segment,
    COUNT(o.order_id)                                   AS total_orders,
    ROUND(SUM(o.total_amount), 2)                       AS lifetime_spend,
    ROUND(AVG(o.total_amount), 2)                       AS avg_order_value,
    ROUND(SUM(o.discount_amount), 2)                    AS total_discounts_received,
    MIN(DATE(o.order_date))                             AS first_order_date,
    MAX(DATE(o.order_date))                             AS last_order_date
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY
    c.customer_id, c.first_name, c.last_name,
    c.email, c.city, c.state, c.segment
ORDER BY lifetime_spend DESC
LIMIT 5;


-- ---------------------------------------------------------------------------
-- 5b. Top 5 Customers — Detailed Spending Breakdown by Category
-- ---------------------------------------------------------------------------
-- Business Question:
--   For the top 5 spenders, which product categories are they buying most?
--   Category affinity data for VIPs helps personalise offers and stock
--   decisions for high-value customer micro-segments.
--
-- Joins / Aggregates : CTE for top 5 IDs + multi-table JOIN + GROUP BY
--
-- Expected Output:
--   One row per (top-customer, category) combination showing units purchased
--   and total spend in that category for that customer.
-- ---------------------------------------------------------------------------

WITH top5_customers AS (
    SELECT c.customer_id
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.status NOT IN ('Cancelled', 'Returned')
    GROUP BY c.customer_id
    ORDER BY SUM(o.total_amount) DESC
    LIMIT 5
)
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)   AS customer_name,
    c.segment,
    cat.category_name,
    SUM(oi.quantity)                         AS units_purchased,
    ROUND(SUM(oi.line_total), 2)             AS category_spend,
    COUNT(DISTINCT o.order_id)               AS orders_in_category
FROM top5_customers t5
JOIN customers     c   ON c.customer_id   = t5.customer_id
JOIN orders        o   ON o.customer_id   = c.customer_id
JOIN order_items   oi  ON oi.order_id     = o.order_id
JOIN products      p   ON p.product_id    = oi.product_id
JOIN categories    cat ON cat.category_id = p.category_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY c.customer_id, c.first_name, c.last_name, c.segment, cat.category_name
ORDER BY c.customer_id, category_spend DESC;


-- =============================================================================
-- SECTION 6 — TOP 5 BEST-SELLING PRODUCTS
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 6a. Top 5 Products by Total Units Sold
-- ---------------------------------------------------------------------------
-- Business Question:
--   Which five products have the highest unit sales volume? High-volume
--   products are inventory priorities; stockouts here directly damage revenue.
--
-- Joins / Aggregates : JOIN + SUM(quantity) + GROUP BY product + LIMIT 5
--
-- Expected Output:
--   Rank, product_id, product name, SKU, brand, category, total units sold,
--   number of distinct orders containing this product.
-- ---------------------------------------------------------------------------

SELECT
    RANK() OVER (ORDER BY SUM(oi.quantity) DESC)     AS volume_rank,
    p.product_id,
    p.product_name,
    p.sku,
    p.brand,
    cat.category_name,
    p.unit_price                                     AS current_unit_price,
    SUM(oi.quantity)                                 AS total_units_sold,
    COUNT(DISTINCT oi.order_id)                      AS orders_containing_product,
    ROUND(SUM(oi.line_total), 2)                     AS total_revenue_generated
FROM order_items oi
JOIN products   p   ON p.product_id    = oi.product_id
JOIN categories cat ON cat.category_id = p.category_id
JOIN orders     o   ON o.order_id      = oi.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY p.product_id, p.product_name, p.sku, p.brand, cat.category_name, p.unit_price
ORDER BY total_units_sold DESC
LIMIT 5;


-- ---------------------------------------------------------------------------
-- 6b. Top 5 Products by Total Revenue Generated
-- ---------------------------------------------------------------------------
-- Business Question:
--   Which five products contribute the most to total revenue? A high-revenue
--   product that sells fewer units at a premium is very different from a
--   high-volume low-margin product — both matter differently to strategy.
--
-- Joins / Aggregates : JOIN + SUM(line_total) + GROUP BY product + LIMIT 5
--
-- Expected Output:
--   Rank, product details, total revenue, units sold, revenue per unit
--   (effective ASP), and gross margin per unit where cost data is available.
-- ---------------------------------------------------------------------------

SELECT
    RANK() OVER (ORDER BY SUM(oi.line_total) DESC)     AS revenue_rank,
    p.product_id,
    p.product_name,
    p.sku,
    p.brand,
    cat.category_name,
    SUM(oi.quantity)                                   AS units_sold,
    ROUND(SUM(oi.line_total), 2)                       AS total_revenue,
    ROUND(SUM(oi.line_total) / SUM(oi.quantity), 2)    AS effective_avg_selling_price,
    p.unit_price                                       AS list_price,
    p.cost_price,
    CASE
        WHEN p.cost_price IS NOT NULL
        THEN ROUND(
            (SUM(oi.line_total) - p.cost_price * SUM(oi.quantity))
            / SUM(oi.line_total) * 100, 2)
        ELSE NULL
    END                                                AS gross_margin_pct
FROM order_items oi
JOIN products   p   ON p.product_id    = oi.product_id
JOIN categories cat ON cat.category_id = p.category_id
JOIN orders     o   ON o.order_id      = oi.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY
    p.product_id, p.product_name, p.sku, p.brand,
    cat.category_name, p.unit_price, p.cost_price
ORDER BY total_revenue DESC
LIMIT 5;


-- ---------------------------------------------------------------------------
-- 6c. Full Product Sales Leaderboard (All Products, Ranked)
-- ---------------------------------------------------------------------------
-- Business Question:
--   How does every product rank by revenue? A complete ranked list reveals
--   the long tail — products that never sell and should be discontinued.
--
-- Joins / Aggregates : CTE + RANK() window function
--
-- Expected Output:
--   All products ranked by revenue descending, with volume rank alongside
--   revenue rank to identify divergence (high volume, low revenue = cheap).
-- ---------------------------------------------------------------------------

WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.sku,
        p.brand,
        cat.category_name,
        p.unit_price,
        p.cost_price,
        p.is_active,
        COALESCE(SUM(oi.quantity), 0)        AS units_sold,
        COALESCE(ROUND(SUM(oi.line_total), 2), 0.00) AS total_revenue,
        COUNT(DISTINCT oi.order_id)          AS order_appearances
    FROM products p
    JOIN categories cat ON cat.category_id = p.category_id
    LEFT JOIN order_items oi ON oi.product_id = p.product_id
    LEFT JOIN orders      o  ON o.order_id    = oi.order_id
                             AND o.status NOT IN ('Cancelled', 'Returned')
    GROUP BY
        p.product_id, p.product_name, p.sku, p.brand,
        cat.category_name, p.unit_price, p.cost_price, p.is_active
)
SELECT
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    RANK() OVER (ORDER BY units_sold DESC)    AS volume_rank,
    product_id,
    product_name,
    sku,
    brand,
    category_name,
    unit_price,
    units_sold,
    total_revenue,
    order_appearances,
    CASE
        WHEN units_sold = 0 THEN 'NEVER SOLD'
        WHEN units_sold < 5 THEN 'LOW SELLER'
        WHEN units_sold < 20 THEN 'MODERATE SELLER'
        ELSE 'HIGH SELLER'
    END AS sales_tier
FROM product_sales
ORDER BY revenue_rank;


-- =============================================================================
-- SECTION 7 — MOST PROFITABLE PRODUCT CATEGORIES
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 7a. Revenue, Cost, and Gross Profit per Category
-- ---------------------------------------------------------------------------
-- Business Question:
--   Which product categories generate the highest gross profit?
--   Revenue alone is misleading; a category with slim margins may be less
--   valuable than a smaller but higher-margin one.
--
-- Joins / Aggregates : Multi-table JOIN + SUM + GROUP BY category
--
-- Expected Output:
--   One row per category with:
--   total_revenue      — sum of line_total for all items sold in this category
--   total_cost         — sum of (cost_price × quantity) for items sold
--   gross_profit       — total_revenue − total_cost
--   gross_margin_pct   — gross_profit / total_revenue × 100
--   units_sold         — total quantity moved
-- ---------------------------------------------------------------------------

SELECT
    cat.category_id,
    cat.category_name,
    COUNT(DISTINCT p.product_id)                                AS products_in_category,
    COUNT(DISTINCT o.order_id)                                  AS orders_containing_category,
    SUM(oi.quantity)                                            AS total_units_sold,
    ROUND(SUM(oi.line_total), 2)                                AS total_revenue,
    ROUND(SUM(p.cost_price * oi.quantity), 2)                   AS total_cost,
    ROUND(SUM(oi.line_total) - SUM(p.cost_price * oi.quantity), 2)
                                                                AS gross_profit,
    ROUND(
        (SUM(oi.line_total) - SUM(p.cost_price * oi.quantity))
        / SUM(oi.line_total) * 100,
        2
    )                                                           AS gross_margin_pct
FROM categories cat
JOIN products    p   ON p.category_id  = cat.category_id
JOIN order_items oi  ON oi.product_id  = p.product_id
JOIN orders      o   ON o.order_id     = oi.order_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
  AND p.cost_price IS NOT NULL
GROUP BY cat.category_id, cat.category_name
ORDER BY gross_profit DESC;


-- ---------------------------------------------------------------------------
-- 7b. Category Profit Margin Ranking with Tier Labels
-- ---------------------------------------------------------------------------
-- Business Question:
--   Which categories are Premium (>40% margin), Healthy (20–40%), Thin
--   (<20%), or at a Loss (<0%)? Tier labels help leadership quickly
--   prioritise category investment and renegotiate supplier costs.
--
-- Joins / Aggregates : CTE on category profit + CASE for tier label
--
-- Expected Output:
--   Profitability rank, category name, gross margin %, tier label, revenue
--   and profit. Sorted by margin percentage descending.
-- ---------------------------------------------------------------------------

WITH category_profit AS (
    SELECT
        cat.category_id,
        cat.category_name,
        ROUND(SUM(oi.line_total), 2)                              AS total_revenue,
        ROUND(SUM(p.cost_price * oi.quantity), 2)                 AS total_cost,
        ROUND(SUM(oi.line_total) - SUM(p.cost_price * oi.quantity), 2)
                                                                  AS gross_profit,
        ROUND(
            (SUM(oi.line_total) - SUM(p.cost_price * oi.quantity))
            / NULLIF(SUM(oi.line_total), 0) * 100,
            2
        )                                                         AS gross_margin_pct
    FROM categories cat
    JOIN products    p   ON p.category_id  = cat.category_id
    JOIN order_items oi  ON oi.product_id  = p.product_id
    JOIN orders      o   ON o.order_id     = oi.order_id
    WHERE o.status NOT IN ('Cancelled', 'Returned')
      AND p.cost_price IS NOT NULL
    GROUP BY cat.category_id, cat.category_name
)
SELECT
    RANK() OVER (ORDER BY gross_margin_pct DESC)   AS profitability_rank,
    category_name,
    total_revenue,
    total_cost,
    gross_profit,
    gross_margin_pct,
    CASE
        WHEN gross_margin_pct >= 40  THEN 'Premium Margin (≥40%)'
        WHEN gross_margin_pct >= 20  THEN 'Healthy Margin (20–39%)'
        WHEN gross_margin_pct >= 0   THEN 'Thin Margin (0–19%)'
        ELSE                              'Loss-Making (<0%)'
    END                                            AS margin_tier
FROM category_profit
ORDER BY profitability_rank;


-- =============================================================================
-- SECTION 8 — CUSTOMER SEGMENT DISTRIBUTION
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 8a. Customer Count and Percentage per Segment
-- ---------------------------------------------------------------------------
-- Business Question:
--   How is the customer base distributed across loyalty segments (New,
--   Bronze, Silver, Gold, Platinum)? A healthy pyramid has many Bronze/Silver
--   customers progressing upwards; a flat distribution may signal a stalled
--   loyalty programme.
--
-- Joins / Aggregates : COUNT + GROUP BY segment + window for percentage
--
-- Expected Output:
--   One row per segment with count, percentage of total, and the gender
--   breakdown within each segment.
-- ---------------------------------------------------------------------------

SELECT
    segment,
    COUNT(customer_id)                                           AS customer_count,
    ROUND(COUNT(customer_id) * 100.0 / SUM(COUNT(customer_id)) OVER (), 2)
                                                                 AS pct_of_total,
    SUM(CASE WHEN gender = 'Male'            THEN 1 ELSE 0 END)  AS male_count,
    SUM(CASE WHEN gender = 'Female'          THEN 1 ELSE 0 END)  AS female_count,
    SUM(CASE WHEN gender = 'Other'           THEN 1 ELSE 0 END)  AS other_gender_count,
    SUM(CASE WHEN gender = 'Prefer not to say' THEN 1 ELSE 0 END) AS unspecified_gender,
    SUM(CASE WHEN is_active = 1              THEN 1 ELSE 0 END)  AS active_in_segment
FROM customers
GROUP BY segment
ORDER BY
    FIELD(segment, 'Platinum', 'Gold', 'Silver', 'Bronze', 'New');


-- ---------------------------------------------------------------------------
-- 8b. Revenue and AOV per Customer Segment
-- ---------------------------------------------------------------------------
-- Business Question:
--   How much revenue does each segment contribute, and what is their
--   average order value? This validates whether the segment tier correctly
--   predicts spending behaviour.
--
-- Joins / Aggregates : JOIN customers + orders + SUM + AVG + GROUP BY segment
--
-- Expected Output:
--   One row per segment with total revenue, AOV, order count, revenue per
--   customer (LTV proxy), and percentage of platform revenue.
-- ---------------------------------------------------------------------------

WITH segment_revenue AS (
    SELECT
        c.segment,
        COUNT(DISTINCT c.customer_id)        AS customer_count,
        COUNT(o.order_id)                    AS order_count,
        ROUND(SUM(o.total_amount), 2)        AS total_revenue,
        ROUND(AVG(o.total_amount), 2)        AS avg_order_value
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.status NOT IN ('Cancelled', 'Returned')
    GROUP BY c.segment
),
grand AS (SELECT SUM(total_revenue) AS grand_total FROM segment_revenue)
SELECT
    sr.segment,
    sr.customer_count,
    sr.order_count,
    ROUND(sr.order_count / sr.customer_count, 1)      AS avg_orders_per_customer,
    sr.avg_order_value,
    sr.total_revenue,
    ROUND(sr.total_revenue / sr.customer_count, 2)    AS revenue_per_customer,
    ROUND(sr.total_revenue / g.grand_total * 100, 2)  AS revenue_pct
FROM segment_revenue sr
CROSS JOIN grand g
ORDER BY
    FIELD(sr.segment, 'Platinum', 'Gold', 'Silver', 'Bronze', 'New');


-- ---------------------------------------------------------------------------
-- 8c. Segment Geography — Top City per Segment
-- ---------------------------------------------------------------------------
-- Business Question:
--   Where are Platinum and Gold customers concentrated geographically?
--   Knowing which cities have the most high-value customers guides decisions
--   on physical showrooms, regional warehouses, and hyperlocal campaigns.
--
-- Joins / Aggregates : CTE + RANK() window to find top city per segment
--
-- Expected Output:
--   For each segment, the top 3 cities by customer count, with counts.
-- ---------------------------------------------------------------------------

WITH city_segment AS (
    SELECT
        segment,
        city,
        COUNT(*) AS customer_count,
        RANK() OVER (PARTITION BY segment ORDER BY COUNT(*) DESC) AS city_rank
    FROM customers
    GROUP BY segment, city
)
SELECT
    segment,
    city_rank,
    city,
    customer_count
FROM city_segment
WHERE city_rank <= 3
ORDER BY
    FIELD(segment, 'Platinum', 'Gold', 'Silver', 'Bronze', 'New'),
    city_rank;


-- =============================================================================
-- SECTION 9 — CUSTOMER RETENTION SUMMARY
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 9a. Single-Order vs Repeat Customers
-- ---------------------------------------------------------------------------
-- Business Question:
--   What proportion of customers have placed more than one order?
--   The repeat-purchase rate is one of the strongest indicators of product
--   market fit and customer satisfaction.
--
-- Joins / Aggregates : CTE counting orders per customer + CASE bucket
--
-- Expected Output:
--   Two rows — 'One-Time Buyer' and 'Repeat Buyer' — with count, percentage
--   of ordering customers, and their combined revenue contribution.
-- ---------------------------------------------------------------------------

WITH customer_order_counts AS (
    SELECT
        customer_id,
        COUNT(order_id)         AS order_count,
        SUM(total_amount)       AS lifetime_spend
    FROM orders
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-Time Buyer'
        WHEN order_count BETWEEN 2 AND 3 THEN 'Occasional Buyer (2–3 orders)'
        ELSE 'Loyal Buyer (4+ orders)'
    END                                              AS buyer_type,
    COUNT(customer_id)                               AS customer_count,
    ROUND(COUNT(customer_id) * 100.0
        / SUM(COUNT(customer_id)) OVER (), 2)        AS pct_of_customers,
    ROUND(SUM(lifetime_spend), 2)                    AS total_revenue,
    ROUND(AVG(lifetime_spend), 2)                    AS avg_lifetime_spend,
    ROUND(AVG(order_count), 1)                       AS avg_orders_per_customer
FROM customer_order_counts
GROUP BY
    CASE
        WHEN order_count = 1 THEN 'One-Time Buyer'
        WHEN order_count BETWEEN 2 AND 3 THEN 'Occasional Buyer (2–3 orders)'
        ELSE 'Loyal Buyer (4+ orders)'
    END
ORDER BY avg_orders_per_customer DESC;


-- ---------------------------------------------------------------------------
-- 9b. Repeat Purchase Rate
-- ---------------------------------------------------------------------------
-- Business Question:
--   What percentage of customers who have ever ordered came back to place a
--   second or more orders? This single metric (Repeat Purchase Rate) is
--   often called the North Star of e-commerce retention.
--
-- Joins / Aggregates : Subquery counting repeat customers / total customers
--
-- Expected Output:
--   Single summary row with total ordering customers, repeat customers,
--   repeat purchase rate percentage, and revenue split.
-- ---------------------------------------------------------------------------

WITH customer_summary AS (
    SELECT
        customer_id,
        COUNT(order_id)   AS orders_placed,
        SUM(total_amount) AS total_spent
    FROM orders
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY customer_id
)
SELECT
    COUNT(*)                                                    AS total_ordering_customers,
    SUM(CASE WHEN orders_placed  = 1 THEN 1 ELSE 0 END)        AS one_time_buyers,
    SUM(CASE WHEN orders_placed >= 2 THEN 1 ELSE 0 END)        AS repeat_buyers,
    ROUND(
        SUM(CASE WHEN orders_placed >= 2 THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 2
    )                                                           AS repeat_purchase_rate_pct,
    ROUND(SUM(CASE WHEN orders_placed  = 1 THEN total_spent ELSE 0 END), 2)
                                                                AS one_time_buyer_revenue,
    ROUND(SUM(CASE WHEN orders_placed >= 2 THEN total_spent ELSE 0 END), 2)
                                                                AS repeat_buyer_revenue,
    ROUND(
        SUM(CASE WHEN orders_placed >= 2 THEN total_spent ELSE 0 END)
        / SUM(total_spent) * 100, 2
    )                                                           AS repeat_buyer_revenue_pct
FROM customer_summary;


-- ---------------------------------------------------------------------------
-- 9c. Customer Lifetime Order Frequency Leaderboard
-- ---------------------------------------------------------------------------
-- Business Question:
--   Which customers are placing the most orders, and how does their spending
--   compare to their order frequency? High-frequency, high-spending customers
--   are champions who should be enrolled in ambassador programmes.
--
-- Joins / Aggregates : JOIN + COUNT + SUM + GROUP BY customer + ORDER BY
--
-- Expected Output:
--   All customers with at least one order, ranked by order frequency, with
--   lifetime spend, AOV, days since first order, and an activity label.
-- ---------------------------------------------------------------------------

SELECT
    RANK() OVER (ORDER BY COUNT(o.order_id) DESC, SUM(o.total_amount) DESC)
                                                            AS frequency_rank,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)                  AS customer_name,
    c.segment,
    c.city,
    COUNT(o.order_id)                                       AS total_orders,
    ROUND(SUM(o.total_amount), 2)                           AS lifetime_spend,
    ROUND(AVG(o.total_amount), 2)                           AS avg_order_value,
    MIN(DATE(o.order_date))                                 AS first_order_date,
    MAX(DATE(o.order_date))                                 AS last_order_date,
    DATEDIFF(MAX(o.order_date), MIN(o.order_date))          AS tenure_days,
    DATEDIFF(CURDATE(), MAX(o.order_date))                  AS days_since_last_order,
    CASE
        WHEN DATEDIFF(CURDATE(), MAX(o.order_date)) <= 30   THEN 'Active'
        WHEN DATEDIFF(CURDATE(), MAX(o.order_date)) <= 90   THEN 'At Risk'
        WHEN DATEDIFF(CURDATE(), MAX(o.order_date)) <= 180  THEN 'Lapsing'
        ELSE 'Churned'
    END                                                     AS recency_status
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.status NOT IN ('Cancelled', 'Returned')
GROUP BY c.customer_id, c.first_name, c.last_name, c.segment, c.city
ORDER BY frequency_rank;


-- ---------------------------------------------------------------------------
-- 9d. Inter-Order Gap Analysis — Days Between Consecutive Orders
-- ---------------------------------------------------------------------------
-- Business Question:
--   On average, how many days elapse between a customer's consecutive orders?
--   The inter-order gap informs the optimal timing for reorder reminder
--   emails and push notifications.
--
-- Joins / Aggregates : CTE + LAG() window function + AVG
--
-- Expected Output:
--   Per-customer average inter-order gap in days. Summary row at end shows
--   platform-wide average gap across all repeat buyers.
-- ---------------------------------------------------------------------------

WITH ordered_orders AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        )                           AS prev_order_date
    FROM orders
    WHERE status NOT IN ('Cancelled', 'Returned')
),
inter_order_gaps AS (
    SELECT
        customer_id,
        DATEDIFF(order_date, prev_order_date)   AS days_between_orders
    FROM ordered_orders
    WHERE prev_order_date IS NOT NULL
)
SELECT
    ig.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)      AS customer_name,
    c.segment,
    COUNT(*)                                    AS gap_count,
    ROUND(AVG(ig.days_between_orders), 1)       AS avg_days_between_orders,
    MIN(ig.days_between_orders)                 AS min_gap_days,
    MAX(ig.days_between_orders)                 AS max_gap_days
FROM inter_order_gaps ig
JOIN customers c ON c.customer_id = ig.customer_id
GROUP BY ig.customer_id, c.first_name, c.last_name, c.segment
ORDER BY avg_days_between_orders ASC;


-- =============================================================================
-- SECTION 10 — MONTHLY SALES PERFORMANCE
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 10a. Month-by-Month Revenue and Order Count
-- ---------------------------------------------------------------------------
-- Business Question:
--   How does revenue and order volume trend month over month? Monthly
--   granularity reveals seasonality patterns, campaign lifts, and
--   post-holiday dips.
--
-- Joins / Aggregates : SUM + COUNT + GROUP BY YEAR/MONTH
--
-- Expected Output:
--   One row per calendar month with:
--   order_count, unique_customers, total_revenue, avg_order_value,
--   total_discount_given, net_revenue.
-- ---------------------------------------------------------------------------

SELECT
    YEAR(order_date)                              AS order_year,
    MONTH(order_date)                             AS order_month,
    DATE_FORMAT(order_date, '%b %Y')              AS month_label,
    COUNT(order_id)                               AS order_count,
    COUNT(DISTINCT customer_id)                   AS unique_customers,
    ROUND(SUM(subtotal), 2)                       AS gross_revenue,
    ROUND(SUM(discount_amount), 2)                AS total_discounts,
    ROUND(SUM(tax_amount), 2)                     AS total_tax,
    ROUND(SUM(shipping_charge), 2)                AS total_shipping,
    ROUND(SUM(total_amount), 2)                   AS net_revenue,
    ROUND(AVG(total_amount), 2)                   AS avg_order_value,
    SUM(CASE WHEN status = 'Delivered'  THEN 1 ELSE 0 END)  AS delivered_orders,
    SUM(CASE WHEN status = 'Cancelled'  THEN 1 ELSE 0 END)  AS cancelled_orders,
    SUM(CASE WHEN status = 'Returned'   THEN 1 ELSE 0 END)  AS returned_orders
FROM orders
GROUP BY YEAR(order_date), MONTH(order_date), DATE_FORMAT(order_date, '%b %Y')
ORDER BY order_year, order_month;


-- ---------------------------------------------------------------------------
-- 10b. Month-over-Month Revenue Growth
-- ---------------------------------------------------------------------------
-- Business Question:
--   Is revenue growing or declining month over month? The MoM growth rate
--   is used in board-level reporting to demonstrate business trajectory.
--
-- Joins / Aggregates : CTE + LAG() window function for previous month revenue
--
-- Expected Output:
--   Each month's revenue, the previous month's revenue, absolute change,
--   and MoM growth percentage. Positive values = growth; negative = decline.
-- ---------------------------------------------------------------------------

WITH monthly_revenue AS (
    SELECT
        YEAR(order_date)                                   AS order_year,
        MONTH(order_date)                                  AS order_month,
        DATE_FORMAT(order_date, '%b %Y')                   AS month_label,
        COUNT(order_id)                                    AS order_count,
        ROUND(SUM(total_amount), 2)                        AS monthly_revenue
    FROM orders
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY YEAR(order_date), MONTH(order_date), DATE_FORMAT(order_date, '%b %Y')
),
mom_growth AS (
    SELECT
        order_year,
        order_month,
        month_label,
        order_count,
        monthly_revenue,
        LAG(monthly_revenue) OVER (ORDER BY order_year, order_month) AS prev_month_revenue
    FROM monthly_revenue
)
SELECT
    order_year,
    order_month,
    month_label,
    order_count,
    monthly_revenue,
    COALESCE(prev_month_revenue, 0)                                     AS prev_month_revenue,
    ROUND(monthly_revenue - COALESCE(prev_month_revenue, 0), 2)         AS revenue_change,
    CASE
        WHEN prev_month_revenue IS NULL THEN NULL
        ELSE ROUND(
            (monthly_revenue - prev_month_revenue) / prev_month_revenue * 100,
            2)
    END                                                                 AS mom_growth_pct,
    CASE
        WHEN prev_month_revenue IS NULL                      THEN 'First Month'
        WHEN monthly_revenue >= prev_month_revenue * 1.20   THEN 'Strong Growth (≥20%)'
        WHEN monthly_revenue >= prev_month_revenue * 1.05   THEN 'Moderate Growth (5–19%)'
        WHEN monthly_revenue >= prev_month_revenue * 0.95   THEN 'Stable (±5%)'
        WHEN monthly_revenue >= prev_month_revenue * 0.80   THEN 'Moderate Decline (5–19%)'
        ELSE                                                      'Sharp Decline (≥20%)'
    END                                                                 AS growth_label
FROM mom_growth
ORDER BY order_year, order_month;


-- ---------------------------------------------------------------------------
-- 10c. Best and Worst Performing Months (All-Time)
-- ---------------------------------------------------------------------------
-- Business Question:
--   Which calendar months (by name, e.g., January, July) consistently
--   perform best and worst? Month-of-year patterns reveal seasonality that
--   can be built into annual planning and promotional calendars.
--
-- Joins / Aggregates : CTE + GROUP BY month name + RANK
--
-- Expected Output:
--   Each month of the year with average revenue across all years, total
--   revenue, and best/worst year for that month.
-- ---------------------------------------------------------------------------

WITH monthly_totals AS (
    SELECT
        MONTH(order_date)                       AS month_num,
        DATE_FORMAT(order_date, '%M')           AS month_name,
        YEAR(order_date)                        AS yr,
        ROUND(SUM(total_amount), 2)             AS monthly_revenue,
        COUNT(order_id)                         AS monthly_orders
    FROM orders
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY MONTH(order_date), DATE_FORMAT(order_date, '%M'), YEAR(order_date)
)
SELECT
    month_num,
    month_name,
    COUNT(DISTINCT yr)                              AS years_with_data,
    ROUND(AVG(monthly_revenue), 2)                  AS avg_monthly_revenue,
    ROUND(SUM(monthly_revenue), 2)                  AS total_revenue_all_years,
    ROUND(AVG(monthly_orders), 1)                   AS avg_monthly_orders,
    MAX(monthly_revenue)                            AS best_year_revenue,
    MIN(monthly_revenue)                            AS worst_year_revenue,
    RANK() OVER (ORDER BY AVG(monthly_revenue) DESC) AS performance_rank,
    CASE
        WHEN RANK() OVER (ORDER BY AVG(monthly_revenue) DESC) <= 3
            THEN 'Top Performer'
        WHEN RANK() OVER (ORDER BY AVG(monthly_revenue) DESC) >= 10
            THEN 'Low Performer'
        ELSE 'Average Performer'
    END                                             AS performance_label
FROM monthly_totals
GROUP BY month_num, month_name
ORDER BY month_num;


-- ---------------------------------------------------------------------------
-- 10d. Quarterly Revenue Rollup
-- ---------------------------------------------------------------------------
-- Business Question:
--   How does revenue break down by fiscal quarter? Quarterly rollups are
--   the standard reporting cadence for executive leadership and investors.
--
-- Joins / Aggregates : QUARTER() + GROUP BY year/quarter + SUM
--
-- Expected Output:
--   One row per year-quarter combination with order count, revenue,
--   AOV, and percentage of that year's total revenue.
-- ---------------------------------------------------------------------------

WITH quarterly_data AS (
    SELECT
        YEAR(order_date)                              AS order_year,
        QUARTER(order_date)                           AS order_quarter,
        COUNT(order_id)                               AS order_count,
        ROUND(SUM(total_amount), 2)                   AS quarterly_revenue,
        ROUND(AVG(total_amount), 2)                   AS avg_order_value,
        COUNT(DISTINCT customer_id)                   AS unique_customers
    FROM orders
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY YEAR(order_date), QUARTER(order_date)
),
yearly_totals AS (
    SELECT
        order_year,
        SUM(quarterly_revenue) AS yearly_revenue
    FROM quarterly_data
    GROUP BY order_year
)
SELECT
    qd.order_year,
    CONCAT('Q', qd.order_quarter)                    AS quarter,
    qd.order_count,
    qd.unique_customers,
    qd.quarterly_revenue,
    qd.avg_order_value,
    ROUND(qd.quarterly_revenue / yt.yearly_revenue * 100, 2)
                                                     AS pct_of_year_revenue
FROM quarterly_data qd
JOIN yearly_totals  yt ON yt.order_year = qd.order_year
ORDER BY qd.order_year, qd.order_quarter;


-- =============================================================================
-- MASTER EXECUTIVE SUMMARY — Single-Screen KPI Snapshot
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Executive KPI Dashboard
-- ---------------------------------------------------------------------------
-- Business Question:
--   What are the most critical business metrics at a glance? This single
--   query consolidates all headline KPIs into one result set, designed
--   to be the first query run in any board-level data review.
--
-- Joins / Aggregates : Cross-join of multiple single-value subqueries
--
-- Expected Output:
--   One row containing every headline metric: customer count, order count,
--   total revenue, AOV, repeat rate, top segment, top category, top city.
-- ---------------------------------------------------------------------------

SELECT
    -- Customer metrics
    (SELECT COUNT(*) FROM customers)                                   AS total_customers,
    (SELECT COUNT(*) FROM customers WHERE is_active = 1)               AS active_customers,

    -- Order metrics
    (SELECT COUNT(*) FROM orders)                                      AS total_orders,
    (SELECT COUNT(*) FROM orders WHERE status = 'Delivered')           AS delivered_orders,
    (SELECT COUNT(*) FROM orders WHERE status IN ('Cancelled','Returned'))
                                                                       AS cancelled_returned_orders,

    -- Revenue metrics
    (SELECT ROUND(SUM(total_amount), 2)
     FROM orders WHERE status NOT IN ('Cancelled','Returned'))         AS total_net_revenue,

    (SELECT ROUND(SUM(discount_amount), 2)
     FROM orders WHERE status NOT IN ('Cancelled','Returned'))         AS total_discounts_given,

    -- AOV
    (SELECT ROUND(AVG(total_amount), 2)
     FROM orders WHERE status NOT IN ('Cancelled','Returned'))         AS avg_order_value,

    -- Top customer segment by revenue
    (SELECT segment
     FROM customers c
     JOIN orders o ON o.customer_id = c.customer_id
     WHERE o.status NOT IN ('Cancelled','Returned')
     GROUP BY c.segment
     ORDER BY SUM(o.total_amount) DESC
     LIMIT 1)                                                          AS top_revenue_segment,

    -- Top product category by gross profit
    (SELECT cat.category_name
     FROM categories cat
     JOIN products p ON p.category_id = cat.category_id
     JOIN order_items oi ON oi.product_id = p.product_id
     JOIN orders o ON o.order_id = oi.order_id
     WHERE o.status NOT IN ('Cancelled','Returned')
       AND p.cost_price IS NOT NULL
     GROUP BY cat.category_name
     ORDER BY SUM(oi.line_total) - SUM(p.cost_price * oi.quantity) DESC
     LIMIT 1)                                                          AS most_profitable_category,

    -- Top city by order count
    (SELECT shipping_city
     FROM orders
     WHERE status NOT IN ('Cancelled','Returned')
     GROUP BY shipping_city
     ORDER BY COUNT(*) DESC
     LIMIT 1)                                                          AS top_city_by_orders,

    -- Repeat purchase rate
    (SELECT ROUND(
        SUM(CASE WHEN cnt >= 2 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2)
     FROM (
         SELECT customer_id, COUNT(*) AS cnt
         FROM orders
         WHERE status NOT IN ('Cancelled','Returned')
         GROUP BY customer_id
     ) x)                                                              AS repeat_purchase_rate_pct,

    -- Best month by revenue
    (SELECT DATE_FORMAT(order_date, '%b %Y')
     FROM orders
     WHERE status NOT IN ('Cancelled','Returned')
     GROUP BY DATE_FORMAT(order_date, '%b %Y'), YEAR(order_date), MONTH(order_date)
     ORDER BY SUM(total_amount) DESC
     LIMIT 1)                                                          AS best_revenue_month;


-- =============================================================================
-- END OF final_business_summary.sql
-- =============================================================================
