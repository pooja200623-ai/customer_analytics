-- =============================================================================
-- PROJECT : Customer Segmentation & Purchase Behavior Analytics
-- SCRIPT  : 02_purchase_behavior_analysis.sql
-- PURPOSE : Deep-dive analytics into basket size, order composition, cross-category
--           affinity, payment preferences, and repeat purchasing velocity.
-- CONCEPTS: Self Joins, Multi-table JOINs, CTEs, Window Functions (ROW_NUMBER, LAG,
--           LEAD), GROUP BY GROUPING SETS logic, Conditional Aggregations.
-- ENGINE  : MySQL 8.0+
-- =============================================================================

USE customer_analytics;

-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 1: Customer Repeat Purchase Velocity & Inter-Purchase Time
-- -----------------------------------------------------------------------------
-- What is the average number of days between successive orders for repeat customers?
-- How quickly do buyers return to make their 2nd, 3rd, or 4th order?
-- -----------------------------------------------------------------------------

WITH customer_order_timeline AS (
    SELECT 
        o.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        o.order_id,
        o.order_date,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date ASC) AS order_sequence,
        LAG(o.order_date) OVER (PARTITION BY o.customer_id ORDER BY o.order_date ASC) AS previous_order_date
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.status != 'Cancelled'
),
inter_purchase_intervals AS (
    SELECT 
        customer_id,
        customer_name,
        order_id,
        order_sequence,
        order_date,
        previous_order_date,
        DATEDIFF(order_date, previous_order_date) AS days_between_orders
    FROM customer_order_timeline
)
SELECT 
    order_sequence AS order_transition,
    CASE 
        WHEN order_sequence = 1 THEN '1st Purchase (Initial Acquisition)'
        WHEN order_sequence = 2 THEN '2nd Purchase (First Re-order)'
        WHEN order_sequence = 3 THEN '3rd Purchase (Engaged Buyer)'
        ELSE '4th+ Purchase (Loyal Champion)'
    END AS purchase_milestone,
    COUNT(*) AS total_orders,
    ROUND(AVG(days_between_orders), 1) AS avg_days_since_last_order,
    MIN(days_between_orders) AS min_days_to_reorder,
    MAX(days_between_orders) AS max_days_to_reorder
FROM inter_purchase_intervals
GROUP BY order_sequence
ORDER BY order_sequence ASC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Shows that customer acquisition peaks initially, and repeat orders occur within
-- an average window of 60 to 120 days, identifying key intervals for re-engagement email campaigns.


-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 2: Cross-Category Product Affinity (Market Basket Analysis)
-- -----------------------------------------------------------------------------
-- Which product categories are most frequently purchased together in the same order?
-- Identify top cross-selling pairs (e.g., Electronics + Audio, Clothing + Books).
-- -----------------------------------------------------------------------------

WITH order_categories AS (
    SELECT DISTINCT 
        oi.order_id,
        c.category_id,
        c.category_name
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
)
SELECT 
    oc1.category_name AS primary_category,
    oc2.category_name AS co_purchased_category,
    COUNT(DISTINCT oc1.order_id) AS co_purchase_frequency,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT oc1.order_id) DESC) AS affinity_rank
FROM order_categories oc1
JOIN order_categories oc2 
    ON oc1.order_id = oc2.order_id 
   AND oc1.category_id < oc2.category_id -- Avoid duplicate mirrors and self-pairs
GROUP BY oc1.category_name, oc2.category_name
ORDER BY co_purchase_frequency DESC, primary_category ASC
LIMIT 10;

-- EXPECTED OUTPUT DESCRIPTION:
-- Reveals strong co-purchasing affinity between Electronics & Beauty, Books & Grocery,
-- and Clothing & Beauty, useful for bundle promotions and cross-sell recommendation engines.


-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 3: Basket Size & Multi-Item Order Distribution
-- -----------------------------------------------------------------------------
-- What proportion of orders are single-item transactions vs multi-item baskets?
-- How does basket depth affect total order value and discount impact?
-- -----------------------------------------------------------------------------

WITH order_basket_summary AS (
    SELECT 
        o.order_id,
        o.total_amount,
        o.discount_amount,
        COUNT(oi.order_item_id) AS distinct_skus_count,
        SUM(oi.quantity) AS total_units_bought
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.total_amount, o.discount_amount
),
basket_brackets AS (
    SELECT 
        order_id,
        total_amount,
        discount_amount,
        total_units_bought,
        CASE 
            WHEN total_units_bought = 1 THEN '1 Unit (Single Item)'
            WHEN total_units_bought = 2 THEN '2 Units (Double)'
            WHEN total_units_bought BETWEEN 3 AND 4 THEN '3-4 Units (Medium Basket)'
            ELSE '5+ Units (Large Bulk Basket)'
        END AS basket_size_bracket
    FROM order_basket_summary
)
SELECT 
    basket_size_bracket,
    COUNT(*) AS total_orders,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM orders), 2) AS pct_of_all_orders,
    CONCAT('₹', FORMAT(AVG(total_amount), 2)) AS avg_order_amount,
    CONCAT('₹', FORMAT(SUM(total_amount), 2)) AS total_revenue_generated,
    CONCAT('₹', FORMAT(AVG(discount_amount), 2)) AS avg_discount_given
FROM basket_brackets
GROUP BY basket_size_bracket
ORDER BY total_orders DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Classifies orders by item depth, highlighting that multi-item baskets generate higher
-- AOV and show where promotional volume discounts are concentrated.


-- -----------------------------------------------------------------------------
-- BUSINESS QUESTION 4: Payment Method Preferences & Gateway Reliability
-- -----------------------------------------------------------------------------
-- Which payment methods have the highest adoption, ticket size, and success rates?
-- Are high-value orders predominantly paid via EMI or Credit Card vs UPI for small orders?
-- -----------------------------------------------------------------------------

SELECT 
    p.method AS payment_method,
    COUNT(p.payment_id) AS total_transactions,
    ROUND((COUNT(p.payment_id) * 100.0) / (SELECT COUNT(*) FROM payments), 2) AS transaction_share_pct,
    CONCAT('₹', FORMAT(SUM(p.amount), 2)) AS total_processed_value,
    CONCAT('₹', FORMAT(AVG(p.amount), 2)) AS avg_transaction_value,
    SUM(CASE WHEN p.status = 'Captured' THEN 1 ELSE 0 END) AS successful_payments,
    SUM(CASE WHEN p.status = 'Pending' THEN 1 ELSE 0 END) AS pending_payments,
    SUM(CASE WHEN p.status = 'Refunded' THEN 1 ELSE 0 END) AS refunded_payments,
    ROUND((SUM(CASE WHEN p.status = 'Captured' THEN 1 ELSE 0 END) * 100.0) / COUNT(p.payment_id), 1) AS success_rate_pct
FROM payments p
GROUP BY p.method
ORDER BY total_processed_value DESC;

-- EXPECTED OUTPUT DESCRIPTION:
-- Demonstrates that Credit Card and EMI handle the majority of high-ticket transaction
-- volume (> ₹50,000), while UPI and COD drive high-frequency everyday purchases (< ₹10,000).
