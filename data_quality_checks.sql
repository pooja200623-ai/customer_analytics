-- =============================================================================
-- PROJECT  : Customer Segmentation & Purchase Behavior Analytics Using SQL
-- FILE     : data_quality_checks.sql
-- PURPOSE  : Data Quality & Validation Module — read-only audit queries
-- ENGINE   : MySQL 8.0+
-- CHARSET  : utf8mb4 / utf8mb4_unicode_ci
-- CREATED  : 2026-11-12
-- NOTE     : This file is 100% read-only. No INSERT / UPDATE / DELETE / DDL.
--            Run schema.sql + sample_data.sql before executing these queries.
-- =============================================================================

USE customer_analytics;

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION INDEX
-- ─────────────────────────────────────────────────────────────────────────────
--  1.  DUPLICATE CUSTOMER RECORDS
--      1a. Duplicate emails
--      1b. Duplicate full names
--      1c. Duplicate phone numbers
--  2.  NULL & MISSING VALUES
--      2a. Customer table NULLs
--      2b. Products table NULLs
--      2c. Orders table NULLs
--      2d. Payments table NULLs
--  3.  INVALID EMAIL FORMATS
--  4.  DUPLICATE ORDERS
--      4a. Same customer, same date
--      4b. Exact financial duplicate orders
--  5.  ORPHAN RECORDS
--      5a. Order items without a parent order
--      5b. Order items referencing non-existent products
--      5c. Orders referencing non-existent customers
--      5d. Products referencing non-existent categories
--      5e. Payments referencing non-existent orders
--  6.  AMOUNT & PRICE VALIDATION
--      6a. Orders where total_amount ≠ subtotal - discount + tax + shipping
--      6b. Order items where line_total ≠ quantity × unit_price × (1 - discount/100)
--      6c. Negative or zero prices in products
--      6d. Orders where total payment collected ≠ order total_amount
--      6e. Products with cost_price higher than unit_price (margin issue)
--  7.  INVALID DATE CHECKS
--      7a. Orders with order_date in the future
--      7b. Orders delivered before they were placed
--      7c. Customers with future date_of_birth
--      7d. Customers born before 1900 or unrealistically old
--      7e. Orders where actual_delivery is before estimated_delivery by > 30 days
--      7f. Payments made before order was placed
--  8.  DATABASE QUALITY SUMMARY REPORT
-- ─────────────────────────────────────────────────────────────────────────────


-- =============================================================================
-- SECTION 1 — DUPLICATE CUSTOMER RECORDS
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1a. Duplicate Emails
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are there multiple customer accounts registered with the same email address?
--   Email is the primary unique identifier for a customer. Duplicates indicate
--   data entry errors, failed deduplication at registration, or account merges
--   that were not completed.
--
-- Technique : GROUP BY + HAVING COUNT > 1
--
-- Expected Output:
--   Lists every email that appears more than once, the number of occurrences,
--   and all customer_ids and names sharing that email. In a clean database this
--   query returns 0 rows (the UNIQUE constraint on customers.email prevents
--   true duplicates; the query guards against any constraint being dropped).
-- ---------------------------------------------------------------------------

SELECT
    email,
    COUNT(*)                                        AS duplicate_count,
    GROUP_CONCAT(customer_id ORDER BY customer_id)  AS customer_ids,
    GROUP_CONCAT(
        CONCAT(first_name, ' ', last_name)
        ORDER BY customer_id
    )                                               AS customer_names
FROM customers
GROUP BY email
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, email;


-- ---------------------------------------------------------------------------
-- 1b. Duplicate Full Names (same first + last name)
-- ---------------------------------------------------------------------------
-- Business Question:
--   Do any two customer records share exactly the same full name?
--   While not necessarily erroneous, duplicate names combined with similar
--   registration dates or cities are strong indicators of accidental duplicates.
--
-- Technique : GROUP BY + HAVING + subquery to fetch detail rows
--
-- Expected Output:
--   One row per duplicated name showing the count, all customer_ids, their
--   cities, and registration dates so an analyst can judge whether they are
--   the same person. Returns 0 rows if all names are unique.
-- ---------------------------------------------------------------------------

SELECT
    full_name,
    duplicate_count,
    customer_ids,
    cities,
    registration_dates
FROM (
    SELECT
        CONCAT(first_name, ' ', last_name)                           AS full_name,
        COUNT(*)                                                     AS duplicate_count,
        GROUP_CONCAT(customer_id ORDER BY customer_id)               AS customer_ids,
        GROUP_CONCAT(city ORDER BY customer_id)                      AS cities,
        GROUP_CONCAT(registration_date ORDER BY customer_id)         AS registration_dates
    FROM customers
    GROUP BY CONCAT(first_name, ' ', last_name)
    HAVING COUNT(*) > 1
) AS dup_names
ORDER BY duplicate_count DESC, full_name;


-- ---------------------------------------------------------------------------
-- 1c. Duplicate Phone Numbers
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are multiple customer records using the same phone number?
--   A phone number shared across accounts may indicate test data, data-entry
--   errors, or a household using one number for multiple accounts.
--
-- Technique : GROUP BY + HAVING on nullable phone column
--
-- Expected Output:
--   Phone number, how many customers share it, and their IDs/names.
--   NULL phones are excluded (NULL ≠ NULL in SQL).
-- ---------------------------------------------------------------------------

SELECT
    phone,
    COUNT(*)                                        AS shared_by_count,
    GROUP_CONCAT(customer_id ORDER BY customer_id)  AS customer_ids,
    GROUP_CONCAT(
        CONCAT(first_name, ' ', last_name)
        ORDER BY customer_id
    )                                               AS customer_names
FROM customers
WHERE phone IS NOT NULL
GROUP BY phone
HAVING COUNT(*) > 1
ORDER BY shared_by_count DESC, phone;


-- =============================================================================
-- SECTION 2 — NULL & MISSING VALUES
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 2a. Customer Table — NULL / Missing Value Audit
-- ---------------------------------------------------------------------------
-- Business Question:
--   Which optional (and mandatory) customer fields are missing data, and how
--   many records are affected? Missing phone numbers reduce outreach capability;
--   missing city/state/postal hinders geo-segmentation; missing date_of_birth
--   prevents age-band analysis.
--
-- Technique : COUNT + CASE WHEN IS NULL + single-row summary
--
-- Expected Output:
--   One summary row with counts of NULLs / empty strings for each audited
--   column, plus the total customer count for context.
-- ---------------------------------------------------------------------------

SELECT
    COUNT(*)                                                     AS total_customers,
    SUM(CASE WHEN phone         IS NULL OR phone = ''
             THEN 1 ELSE 0 END)                                  AS missing_phone,
    SUM(CASE WHEN date_of_birth IS NULL
             THEN 1 ELSE 0 END)                                  AS missing_dob,
    SUM(CASE WHEN gender = 'Prefer not to say'
             THEN 1 ELSE 0 END)                                  AS unspecified_gender,
    SUM(CASE WHEN address_line1 IS NULL OR address_line1 = ''
             THEN 1 ELSE 0 END)                                  AS missing_address_line1,
    SUM(CASE WHEN city          IS NULL OR city = ''
             THEN 1 ELSE 0 END)                                  AS missing_city,
    SUM(CASE WHEN state         IS NULL OR state = ''
             THEN 1 ELSE 0 END)                                  AS missing_state,
    SUM(CASE WHEN postal_code   IS NULL OR postal_code = ''
             THEN 1 ELSE 0 END)                                  AS missing_postal_code,
    SUM(CASE WHEN last_login    IS NULL
             THEN 1 ELSE 0 END)                                  AS never_logged_in
FROM customers;


-- ---------------------------------------------------------------------------
-- 2b. Products Table — NULL / Missing Value Audit
-- ---------------------------------------------------------------------------
-- Business Question:
--   Which product fields are incomplete? Missing cost_price prevents margin
--   calculations; missing brand prevents brand-level analysis; missing
--   description affects product page completeness.
--
-- Technique : COUNT + CASE WHEN IS NULL
--
-- Expected Output:
--   Summary row with per-column NULL counts alongside total product count.
-- ---------------------------------------------------------------------------

SELECT
    COUNT(*)                                                     AS total_products,
    SUM(CASE WHEN description    IS NULL OR description = ''
             THEN 1 ELSE 0 END)                                  AS missing_description,
    SUM(CASE WHEN cost_price     IS NULL
             THEN 1 ELSE 0 END)                                  AS missing_cost_price,
    SUM(CASE WHEN brand          IS NULL OR brand = ''
             THEN 1 ELSE 0 END)                                  AS missing_brand,
    SUM(CASE WHEN stock_quantity = 0
             THEN 1 ELSE 0 END)                                  AS zero_stock,
    SUM(CASE WHEN is_active      = 0
             THEN 1 ELSE 0 END)                                  AS inactive_products
FROM products;


-- ---------------------------------------------------------------------------
-- 2c. Orders Table — NULL / Missing Value Audit
-- ---------------------------------------------------------------------------
-- Business Question:
--   How many orders have incomplete shipping information or missing delivery
--   details? NULL actual_delivery on a Delivered order is a data integrity gap.
--
-- Technique : COUNT + CASE WHEN IS NULL + status-aware logic
--
-- Expected Output:
--   Summary row showing counts of missing/NULL values per column, with a
--   special flag for delivered orders that lack an actual_delivery date.
-- ---------------------------------------------------------------------------

SELECT
    COUNT(*)                                                     AS total_orders,
    SUM(CASE WHEN shipping_address IS NULL OR shipping_address = ''
             THEN 1 ELSE 0 END)                                  AS missing_shipping_address,
    SUM(CASE WHEN shipping_city    IS NULL OR shipping_city = ''
             THEN 1 ELSE 0 END)                                  AS missing_shipping_city,
    SUM(CASE WHEN shipping_state   IS NULL OR shipping_state = ''
             THEN 1 ELSE 0 END)                                  AS missing_shipping_state,
    SUM(CASE WHEN shipping_postal  IS NULL OR shipping_postal = ''
             THEN 1 ELSE 0 END)                                  AS missing_shipping_postal,
    SUM(CASE WHEN estimated_delivery IS NULL
             THEN 1 ELSE 0 END)                                  AS missing_estimated_delivery,
    SUM(CASE WHEN actual_delivery    IS NULL
             THEN 1 ELSE 0 END)                                  AS missing_actual_delivery,
    -- Delivered orders that have no actual_delivery date recorded
    SUM(CASE WHEN status = 'Delivered'
              AND actual_delivery IS NULL
             THEN 1 ELSE 0 END)                                  AS delivered_without_actual_date,
    SUM(CASE WHEN notes IS NULL OR notes = ''
             THEN 1 ELSE 0 END)                                  AS missing_notes
FROM orders;


-- ---------------------------------------------------------------------------
-- 2d. Payments Table — NULL / Missing Value Audit
-- ---------------------------------------------------------------------------
-- Business Question:
--   Which payment records are missing transaction references or gateway details?
--   Non-COD payments without a transaction_ref cannot be reconciled with the
--   payment gateway.
--
-- Technique : COUNT + CASE WHEN IS NULL + method-aware flag
--
-- Expected Output:
--   Summary row with NULL counts; a special counter for non-COD payments
--   that lack a transaction_ref.
-- ---------------------------------------------------------------------------

SELECT
    COUNT(*)                                                     AS total_payments,
    SUM(CASE WHEN transaction_ref IS NULL OR transaction_ref = ''
             THEN 1 ELSE 0 END)                                  AS missing_transaction_ref,
    -- Flag: non-COD payments missing a transaction reference
    SUM(CASE WHEN method <> 'Cash on Delivery'
              AND (transaction_ref IS NULL OR transaction_ref = '')
             THEN 1 ELSE 0 END)                                  AS non_cod_missing_txn_ref,
    SUM(CASE WHEN gateway IS NULL OR gateway = ''
             THEN 1 ELSE 0 END)                                  AS missing_gateway,
    SUM(CASE WHEN notes   IS NULL OR notes   = ''
             THEN 1 ELSE 0 END)                                  AS missing_notes
FROM payments;


-- =============================================================================
-- SECTION 3 — INVALID EMAIL FORMATS
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 3a. Customers with Invalid Email Addresses
-- ---------------------------------------------------------------------------
-- Business Question:
--   Which customer email addresses do not conform to a valid format
--   (local@domain.tld)? Invalid emails mean marketing emails will bounce and
--   password-reset links cannot be delivered.
--
-- Technique : REGEXP / NOT REGEXP pattern matching in MySQL
--   Pattern validates:
--     • One or more characters before @
--     • @ symbol (exactly one)
--     • Domain name with at least one dot
--     • TLD of 2–10 alphabetic characters
--
-- Expected Output:
--   customer_id, full name, the invalid email, and a CASE-based diagnosis
--   describing which part of the email is malformed. Returns 0 rows if all
--   emails are properly formatted.
-- ---------------------------------------------------------------------------

SELECT
    customer_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    email,
    CASE
        WHEN email NOT LIKE '%@%'
            THEN 'Missing @ symbol'
        WHEN email LIKE '@%'
            THEN 'Nothing before @ symbol'
        WHEN email LIKE '%@'
            THEN 'Nothing after @ symbol'
        WHEN email NOT REGEXP '^[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,10}$'
            THEN 'Invalid format (special chars / missing TLD)'
        ELSE 'Valid'
    END                                AS email_issue
FROM customers
WHERE email NOT REGEXP '^[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,10}$'
   OR email IS NULL
   OR email = ''
ORDER BY customer_id;


-- ---------------------------------------------------------------------------
-- 3b. Email Domain Distribution (Spot Unusual / Suspicious Domains)
-- ---------------------------------------------------------------------------
-- Business Question:
--   What email domains are customers using? Unusually high counts on a single
--   obscure domain, or obviously fake domains (e.g., test.com, example.com),
--   may indicate bot registrations or bulk fake accounts.
--
-- Technique : SUBSTRING_INDEX + GROUP BY + ORDER BY
--
-- Expected Output:
--   Each unique email domain, the number of customers using it, sorted by
--   count descending so suspicious patterns surface at the top.
-- ---------------------------------------------------------------------------

SELECT
    SUBSTRING_INDEX(email, '@', -1)    AS email_domain,
    COUNT(*)                           AS customer_count,
    GROUP_CONCAT(customer_id ORDER BY customer_id SEPARATOR ', ') AS customer_ids
FROM customers
WHERE email IS NOT NULL AND email <> ''
GROUP BY SUBSTRING_INDEX(email, '@', -1)
ORDER BY customer_count DESC, email_domain;


-- =============================================================================
-- SECTION 4 — DUPLICATE ORDERS
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 4a. Same Customer Placing Multiple Orders on the Same Calendar Day
-- ---------------------------------------------------------------------------
-- Business Question:
--   Did any customer place more than one order on the same day? While not
--   inherently wrong, multiple same-day orders from the same customer could
--   indicate accidental double-submission, a reorder after cancellation, or
--   genuine bulk purchasing that should be reviewed.
--
-- Technique : GROUP BY customer_id + DATE(order_date) + HAVING COUNT > 1
--
-- Expected Output:
--   customer_id, full name, the duplicate order date, the number of orders
--   placed that day, and all order IDs involved.
-- ---------------------------------------------------------------------------

SELECT
    o.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)      AS customer_name,
    DATE(o.order_date)                           AS order_day,
    COUNT(o.order_id)                            AS orders_on_same_day,
    GROUP_CONCAT(o.order_id ORDER BY o.order_id) AS order_ids,
    GROUP_CONCAT(o.total_amount ORDER BY o.order_id) AS order_amounts
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY o.customer_id, DATE(o.order_date)
HAVING COUNT(o.order_id) > 1
ORDER BY orders_on_same_day DESC, o.customer_id, order_day;


-- ---------------------------------------------------------------------------
-- 4b. Exact Financial Duplicate Orders (same customer, same amounts)
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are there orders from the same customer with identical subtotal, discount,
--   tax, shipping, and total_amount? Exact financial clones are strong
--   candidates for accidental duplicate submissions.
--
-- Technique : CTE + GROUP BY multiple financial columns + HAVING COUNT > 1
--
-- Expected Output:
--   For each duplicated financial fingerprint, shows the customer, the shared
--   amounts, the count of matching orders, and their IDs. Returns 0 rows in a
--   clean dataset.
-- ---------------------------------------------------------------------------

WITH financial_fingerprint AS (
    SELECT
        customer_id,
        subtotal,
        discount_amount,
        tax_amount,
        shipping_charge,
        total_amount,
        COUNT(order_id)                             AS duplicate_count,
        GROUP_CONCAT(order_id ORDER BY order_id)    AS order_ids,
        GROUP_CONCAT(order_date ORDER BY order_id)  AS order_dates
    FROM orders
    GROUP BY
        customer_id,
        subtotal,
        discount_amount,
        tax_amount,
        shipping_charge,
        total_amount
    HAVING COUNT(order_id) > 1
)
SELECT
    ff.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)  AS customer_name,
    ff.subtotal,
    ff.discount_amount,
    ff.tax_amount,
    ff.shipping_charge,
    ff.total_amount,
    ff.duplicate_count,
    ff.order_ids,
    ff.order_dates
FROM financial_fingerprint ff
JOIN customers c ON c.customer_id = ff.customer_id
ORDER BY ff.duplicate_count DESC, ff.total_amount DESC;


-- =============================================================================
-- SECTION 5 — ORPHAN RECORDS (Referential Integrity via JOINs)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 5a. Order Items Without a Parent Order (Orphaned Line Items)
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are there order_items rows that reference an order_id that no longer
--   exists in the orders table? This would indicate that an order was hard-
--   deleted while its line items remained, breaking referential integrity.
--
-- Technique : LEFT JOIN + IS NULL (anti-join pattern)
--
-- Expected Output:
--   List of orphaned order_item_id values and their dangling order_id. A clean
--   database (with CASCADE DELETE) returns 0 rows.
-- ---------------------------------------------------------------------------

SELECT
    oi.order_item_id,
    oi.order_id          AS dangling_order_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    oi.line_total
FROM order_items oi
LEFT JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_id IS NULL
ORDER BY oi.order_id;


-- ---------------------------------------------------------------------------
-- 5b. Order Items Referencing Non-Existent Products
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are any order_items linked to a product_id that does not exist in the
--   products table? This violates the foreign key and means historical
--   purchase records cannot be traced to a product.
--
-- Technique : LEFT JOIN + IS NULL (anti-join)
--
-- Expected Output:
--   Orphaned order_item_id, the invalid product_id, and contextual order info.
--   Returns 0 rows in a fully referentially-intact database.
-- ---------------------------------------------------------------------------

SELECT
    oi.order_item_id,
    oi.order_id,
    oi.product_id        AS dangling_product_id,
    oi.quantity,
    oi.unit_price,
    oi.line_total,
    o.order_date,
    o.customer_id
FROM order_items oi
LEFT JOIN products p ON p.product_id = oi.product_id
LEFT JOIN orders   o ON o.order_id   = oi.order_id
WHERE p.product_id IS NULL
ORDER BY oi.order_id;


-- ---------------------------------------------------------------------------
-- 5c. Orders Referencing Non-Existent Customers
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are there orders whose customer_id does not match any row in the customers
--   table? Such orders cannot be associated with an account — a severe data
--   quality problem for CRM and billing.
--
-- Technique : LEFT JOIN + IS NULL
--
-- Expected Output:
--   Orphaned order rows with their dangling customer_id. A database with FK
--   ON DELETE RESTRICT will prevent this, so 0 rows expected normally.
-- ---------------------------------------------------------------------------

SELECT
    o.order_id,
    o.customer_id        AS dangling_customer_id,
    o.order_date,
    o.status,
    o.total_amount
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL
ORDER BY o.order_id;


-- ---------------------------------------------------------------------------
-- 5d. Products Referencing Non-Existent Categories
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are there products whose category_id does not map to any category in the
--   categories table? Such products would be invisible in category-filtered
--   views and analytics.
--
-- Technique : LEFT JOIN + IS NULL
--
-- Expected Output:
--   Products with a dangling category_id. The FK constraint prevents this;
--   returns 0 rows in a healthy schema.
-- ---------------------------------------------------------------------------

SELECT
    p.product_id,
    p.product_name,
    p.sku,
    p.category_id        AS dangling_category_id,
    p.unit_price,
    p.is_active
FROM products p
LEFT JOIN categories cat ON cat.category_id = p.category_id
WHERE cat.category_id IS NULL
ORDER BY p.product_id;


-- ---------------------------------------------------------------------------
-- 5e. Payments Referencing Non-Existent Orders
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are any payment records linked to an order_id that does not exist? Orphan
--   payments represent money collected with no corresponding order — a critical
--   financial discrepancy.
--
-- Technique : LEFT JOIN + IS NULL
--
-- Expected Output:
--   Orphaned payment rows with dangling order_id, amount, and method.
--   Returns 0 rows in a clean database.
-- ---------------------------------------------------------------------------

SELECT
    pay.payment_id,
    pay.order_id         AS dangling_order_id,
    pay.payment_date,
    pay.method,
    pay.amount,
    pay.status,
    pay.transaction_ref
FROM payments pay
LEFT JOIN orders o ON o.order_id = pay.order_id
WHERE o.order_id IS NULL
ORDER BY pay.order_id;


-- ---------------------------------------------------------------------------
-- 5f. Customers Who Have Never Placed an Order
-- ---------------------------------------------------------------------------
-- Business Question:
--   Which registered customers have zero associated orders? These may be
--   inactive accounts, abandoned sign-ups, or new customers yet to purchase.
--   Not an error per se, but important for re-engagement campaigns.
--
-- Technique : LEFT JOIN + IS NULL (anti-join to find non-matching customers)
--
-- Expected Output:
--   customer_id, name, segment, registration_date, and days since registration
--   for every customer with no orders. Useful for churned / dormant detection.
-- ---------------------------------------------------------------------------

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)   AS customer_name,
    c.email,
    c.segment,
    c.city,
    c.registration_date,
    DATEDIFF(CURDATE(), c.registration_date) AS days_since_registration
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY days_since_registration DESC;


-- =============================================================================
-- SECTION 6 — AMOUNT & PRICE VALIDATION
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 6a. Orders Where total_amount ≠ Derived Financial Formula
-- ---------------------------------------------------------------------------
-- Business Question:
--   For every order, does the stored total_amount equal the expected value
--   computed as: subtotal - discount_amount + tax_amount + shipping_charge?
--   Mismatches indicate calculation bugs, manual overrides, or data corruption.
--
-- Technique : Calculated column comparison + HAVING / WHERE on computed delta
--
-- Expected Output:
--   order_id, customer, stored vs expected total, and the discrepancy amount.
--   Returns 0 rows if all totals are arithmetically consistent (allowing ±0.01
--   rounding tolerance).
-- ---------------------------------------------------------------------------

SELECT
    o.order_id,
    o.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)   AS customer_name,
    o.subtotal,
    o.discount_amount,
    o.tax_amount,
    o.shipping_charge,
    o.total_amount                           AS stored_total,
    ROUND(
        o.subtotal - o.discount_amount + o.tax_amount + o.shipping_charge,
        2
    )                                        AS expected_total,
    ROUND(
        o.total_amount
        - (o.subtotal - o.discount_amount + o.tax_amount + o.shipping_charge),
        2
    )                                        AS discrepancy,
    CASE
        WHEN ABS(
            o.total_amount
            - (o.subtotal - o.discount_amount + o.tax_amount + o.shipping_charge)
        ) <= 0.01 THEN 'OK'
        WHEN o.total_amount >
            (o.subtotal - o.discount_amount + o.tax_amount + o.shipping_charge)
        THEN 'OVERCHARGED'
        ELSE 'UNDERCHARGED'
    END                                      AS validation_status
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE ABS(
    o.total_amount
    - (o.subtotal - o.discount_amount + o.tax_amount + o.shipping_charge)
) > 0.01
ORDER BY ABS(
    o.total_amount
    - (o.subtotal - o.discount_amount + o.tax_amount + o.shipping_charge)
) DESC;


-- ---------------------------------------------------------------------------
-- 6b. Order Items Where line_total ≠ Expected Calculation
-- ---------------------------------------------------------------------------
-- Business Question:
--   Does each order item's line_total match the formula:
--   ROUND(quantity × unit_price × (1 − discount_pct / 100), 2)?
--   Mismatches suggest pricing engine bugs or manual data entry errors.
--
-- Technique : CTE + ROUND comparison with tolerance
--
-- Expected Output:
--   Rows where the stored line_total differs from the formula by more than
--   ₹0.01, with both values and the gap shown. Returns 0 rows if all
--   line-item calculations are correct.
-- ---------------------------------------------------------------------------

WITH item_validation AS (
    SELECT
        oi.order_item_id,
        oi.order_id,
        oi.product_id,
        p.product_name,
        oi.quantity,
        oi.unit_price,
        oi.discount_pct,
        oi.line_total                                    AS stored_line_total,
        ROUND(
            oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100),
            2
        )                                                AS expected_line_total,
        ROUND(
            oi.line_total
            - oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100),
            2
        )                                                AS discrepancy
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
)
SELECT
    iv.order_item_id,
    iv.order_id,
    iv.product_id,
    iv.product_name,
    iv.quantity,
    iv.unit_price,
    iv.discount_pct,
    iv.stored_line_total,
    iv.expected_line_total,
    iv.discrepancy,
    CASE
        WHEN iv.discrepancy > 0  THEN 'LINE TOTAL TOO HIGH'
        WHEN iv.discrepancy < 0  THEN 'LINE TOTAL TOO LOW'
        ELSE 'OK'
    END                                                  AS validation_status
FROM item_validation iv
WHERE ABS(iv.discrepancy) > 0.01
ORDER BY ABS(iv.discrepancy) DESC;


-- ---------------------------------------------------------------------------
-- 6c. Products with Negative or Zero unit_price / cost_price
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are any products listed with a zero or negative price? A zero unit_price
--   means the product is effectively free, which is usually a data error.
--   Negative values violate basic business rules and CHECK constraints.
--
-- Technique : Simple WHERE with CASE for classification
--
-- Expected Output:
--   product_id, name, SKU, unit_price, cost_price, and the specific issue.
--   The schema's CHECK constraint prevents true negatives; this guards against
--   constraint being bypassed (e.g., via import tools).
-- ---------------------------------------------------------------------------

SELECT
    product_id,
    product_name,
    sku,
    unit_price,
    cost_price,
    CASE
        WHEN unit_price  <  0 THEN 'NEGATIVE unit_price'
        WHEN unit_price  = 0  THEN 'ZERO unit_price (free product?)'
        WHEN cost_price  <  0 THEN 'NEGATIVE cost_price'
        ELSE 'OK'
    END                      AS price_issue
FROM products
WHERE unit_price <= 0
   OR cost_price  < 0
ORDER BY product_id;


-- ---------------------------------------------------------------------------
-- 6d. Orders Where Total Payment Collected ≠ Order's total_amount
-- ---------------------------------------------------------------------------
-- Business Question:
--   For each order, does the sum of all associated payment amounts equal the
--   order's total_amount? A shortfall means the customer owes money; an excess
--   means an overpayment or refund has not been recorded correctly.
--
-- Technique : CTE + LEFT JOIN + SUM aggregation + CASE status check
--
-- Expected Output:
--   order_id, stored total_amount, sum of payments, the gap, and a verdict.
--   Orders with no payment at all are also flagged (NULL sum).
--   Only "captured" / successful payment statuses count toward revenue.
-- ---------------------------------------------------------------------------

WITH order_payment_totals AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.total_amount,
        o.status                                   AS order_status,
        COALESCE(SUM(
            CASE WHEN pay.status IN ('Captured', 'Authorized')
                 THEN pay.amount ELSE 0 END
        ), 0)                                      AS total_paid,
        COUNT(pay.payment_id)                      AS payment_count
    FROM orders o
    LEFT JOIN payments pay ON pay.order_id = o.order_id
    GROUP BY o.order_id, o.customer_id, o.total_amount, o.status
)
SELECT
    opt.order_id,
    CONCAT(c.first_name, ' ', c.last_name)        AS customer_name,
    opt.order_status,
    opt.total_amount,
    opt.total_paid,
    ROUND(opt.total_amount - opt.total_paid, 2)   AS payment_gap,
    opt.payment_count,
    CASE
        WHEN opt.order_status IN ('Cancelled', 'Returned')
            THEN 'SKIP — Cancelled/Returned'
        WHEN opt.payment_count = 0
            THEN 'NO PAYMENT RECORD'
        WHEN ABS(opt.total_amount - opt.total_paid) <= 0.01
            THEN 'FULLY PAID'
        WHEN opt.total_paid < opt.total_amount
            THEN 'UNDERPAID'
        ELSE 'OVERPAID'
    END                                           AS payment_status
FROM order_payment_totals opt
JOIN customers c ON c.customer_id = opt.customer_id
WHERE opt.order_status NOT IN ('Cancelled', 'Returned')
  AND ABS(opt.total_amount - opt.total_paid) > 0.01
ORDER BY ABS(opt.total_amount - opt.total_paid) DESC;


-- ---------------------------------------------------------------------------
-- 6e. Products Where cost_price > unit_price (Negative Margin)
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are there products being sold below their cost price? Selling at a loss
--   is sometimes intentional (loss-leader), but each case should be explicitly
--   justified. Unintentional negative-margin products erode profitability.
--
-- Technique : Simple WHERE comparison + ROUND for margin calculation
--
-- Expected Output:
--   product_id, name, brand, unit_price, cost_price, the calculated loss per
--   unit, and the margin percentage. Sorted by worst margin first.
-- ---------------------------------------------------------------------------

SELECT
    p.product_id,
    p.product_name,
    p.sku,
    p.brand,
    cat.category_name,
    p.unit_price,
    p.cost_price,
    ROUND(p.unit_price  - p.cost_price, 2)                          AS margin_per_unit,
    ROUND((p.unit_price - p.cost_price) / p.cost_price * 100, 2)   AS margin_pct,
    CASE
        WHEN p.cost_price IS NULL
            THEN 'NO COST DATA'
        WHEN p.unit_price < p.cost_price
            THEN 'SELLING AT A LOSS'
        WHEN p.unit_price = p.cost_price
            THEN 'ZERO MARGIN'
        ELSE 'OK'
    END                                                             AS margin_status
FROM products p
JOIN categories cat ON cat.category_id = p.category_id
WHERE p.cost_price IS NOT NULL
  AND p.unit_price <= p.cost_price
ORDER BY margin_pct ASC;


-- =============================================================================
-- SECTION 7 — INVALID DATE CHECKS
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 7a. Orders with order_date in the Future
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are any orders dated beyond today's date? Future-dated orders indicate
--   system clock errors, pre-scheduled order imports gone wrong, or manual
--   data entry mistakes.
--
-- Technique : WHERE order_date > NOW()
--
-- Expected Output:
--   Future-dated orders with their order_id, customer, stored order_date, and
--   how many days into the future they are. Returns 0 rows in a clean database.
-- ---------------------------------------------------------------------------

SELECT
    o.order_id,
    o.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)      AS customer_name,
    o.order_date,
    o.status,
    o.total_amount,
    DATEDIFF(o.order_date, NOW())               AS days_in_future
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_date > NOW()
ORDER BY o.order_date DESC;


-- ---------------------------------------------------------------------------
-- 7b. Orders Delivered Before They Were Placed
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are there orders where actual_delivery < DATE(order_date)? This is
--   logistically impossible and signals a data entry error or timezone
--   mishandling.
--
-- Technique : WHERE actual_delivery < DATE(order_date)
--
-- Expected Output:
--   order_id, order_date, actual_delivery, and the negative delivery lag.
--   Returns 0 rows if all delivery dates are logically consistent.
-- ---------------------------------------------------------------------------

SELECT
    o.order_id,
    o.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)          AS customer_name,
    o.order_date,
    o.actual_delivery,
    DATEDIFF(o.actual_delivery, DATE(o.order_date)) AS delivery_lag_days,
    CASE
        WHEN o.actual_delivery < DATE(o.order_date)
            THEN 'ERROR — Delivered before order placed'
        WHEN o.actual_delivery = DATE(o.order_date)
            THEN 'SUSPICIOUS — Delivered on same day as order'
        ELSE 'OK'
    END                                             AS date_issue
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.actual_delivery IS NOT NULL
  AND o.actual_delivery < DATE(o.order_date)
ORDER BY delivery_lag_days ASC;


-- ---------------------------------------------------------------------------
-- 7c. Customers with a Future date_of_birth
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are there customers whose recorded date_of_birth is after today? A person
--   cannot be born in the future; this indicates a data entry or import error.
--
-- Technique : WHERE date_of_birth > CURDATE()
--
-- Expected Output:
--   customer_id, full name, the erroneous date_of_birth. Returns 0 rows
--   in a valid dataset.
-- ---------------------------------------------------------------------------

SELECT
    customer_id,
    CONCAT(first_name, ' ', last_name)  AS full_name,
    email,
    date_of_birth,
    DATEDIFF(date_of_birth, CURDATE())  AS days_in_future,
    registration_date
FROM customers
WHERE date_of_birth > CURDATE()
ORDER BY date_of_birth DESC;


-- ---------------------------------------------------------------------------
-- 7d. Customers with Unrealistic date_of_birth (Before 1900 or Age > 120)
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are any customers recorded as being born before 1900, implying an
--   impossibly old person? This catches centuries-off data entry errors
--   (e.g., 1924 entered instead of 2024).
--
-- Technique : WHERE YEAR(date_of_birth) < 1900 OR age calculation
--
-- Expected Output:
--   customer_id, name, date_of_birth, calculated age, and issue description.
-- ---------------------------------------------------------------------------

SELECT
    customer_id,
    CONCAT(first_name, ' ', last_name)                                AS full_name,
    email,
    date_of_birth,
    TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE())                     AS calculated_age,
    CASE
        WHEN YEAR(date_of_birth) < 1900
            THEN 'BORN BEFORE 1900 — likely century error'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) > 120
            THEN 'AGE > 120 — implausible'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 0
            THEN 'FUTURE DOB — impossible'
        ELSE 'OK'
    END                                                               AS dob_issue
FROM customers
WHERE date_of_birth IS NOT NULL
  AND (
      YEAR(date_of_birth) < 1900
      OR TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) > 120
  )
ORDER BY date_of_birth ASC;


-- ---------------------------------------------------------------------------
-- 7e. Orders Where actual_delivery Is More Than 30 Days Before estimated_delivery
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are there cases where the actual delivery date is more than 30 days
--   earlier than the estimated delivery date? While early delivery is good,
--   a 30+ day gap almost certainly indicates a data entry error (e.g., wrong
--   year entered for actual_delivery).
--
-- Technique : DATEDIFF comparison + HAVING / WHERE
--
-- Expected Output:
--   order_id, estimated vs actual delivery, and the gap in days. Returns 0
--   rows if all delivery dates are realistic.
-- ---------------------------------------------------------------------------

SELECT
    o.order_id,
    o.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)                          AS customer_name,
    o.order_date,
    o.estimated_delivery,
    o.actual_delivery,
    DATEDIFF(o.estimated_delivery, o.actual_delivery)               AS days_earlier_than_estimated,
    CASE
        WHEN DATEDIFF(o.estimated_delivery, o.actual_delivery) > 30
            THEN 'SUSPICIOUS — arrived 30+ days early'
        WHEN DATEDIFF(o.estimated_delivery, o.actual_delivery) > 0
            THEN 'EARLY DELIVERY'
        WHEN DATEDIFF(o.estimated_delivery, o.actual_delivery) = 0
            THEN 'ON TIME'
        ELSE 'LATE DELIVERY'
    END                                                             AS delivery_verdict
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.estimated_delivery IS NOT NULL
  AND o.actual_delivery    IS NOT NULL
  AND DATEDIFF(o.estimated_delivery, o.actual_delivery) > 30
ORDER BY days_earlier_than_estimated DESC;


-- ---------------------------------------------------------------------------
-- 7f. Payments Made Before the Associated Order Was Placed
-- ---------------------------------------------------------------------------
-- Business Question:
--   Are there payment records whose payment_date precedes the order_date of
--   the linked order? A payment cannot logically be made before an order
--   exists — this signals a system clock error or data import issue.
--
-- Technique : JOIN + WHERE payment_date < order_date
--
-- Expected Output:
--   payment_id, order_id, both dates, and the gap in hours. Returns 0 rows
--   in a temporally-consistent database.
-- ---------------------------------------------------------------------------

SELECT
    pay.payment_id,
    pay.order_id,
    o.order_date,
    pay.payment_date,
    pay.method,
    pay.amount,
    pay.status                                                      AS payment_status,
    TIMESTAMPDIFF(HOUR, pay.payment_date, o.order_date)            AS hours_before_order
FROM payments pay
JOIN orders o ON o.order_id = pay.order_id
WHERE pay.payment_date < o.order_date
ORDER BY hours_before_order DESC;


-- =============================================================================
-- SECTION 8 — DATABASE QUALITY SUMMARY REPORT
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 8. Consolidated Database Quality Dashboard
-- ---------------------------------------------------------------------------
-- Business Question:
--   What is the overall data quality score of the customer_analytics database?
--   This master summary aggregates all individual check results into one
--   easy-to-read scorecard, giving stakeholders a single-pane-of-glass view
--   of data health across all six tables.
--
-- Technique :
--   Multiple CTEs, each encapsulating one quality dimension, combined with
--   UNION ALL into a final formatted report table with:
--     • check_category   — the quality dimension
--     • check_name       — specific check
--     • issue_count      — number of records failing this check
--     • total_records    — universe size for context
--     • issue_pct        — percentage of records affected
--     • severity         — HIGH / MEDIUM / LOW / INFO
--     • recommendation   — suggested corrective action
--
-- Expected Output:
--   One row per quality check; rows ordered by severity (HIGH first) and
--   then by issue_count descending. A fully clean database shows 0 for every
--   issue_count; the remaining rows describe the data volumes only.
-- ---------------------------------------------------------------------------

WITH
-- ── Raw counts used by multiple checks ───────────────────────────────────────
base_counts AS (
    SELECT
        (SELECT COUNT(*) FROM customers)   AS total_customers,
        (SELECT COUNT(*) FROM products)    AS total_products,
        (SELECT COUNT(*) FROM orders)      AS total_orders,
        (SELECT COUNT(*) FROM order_items) AS total_order_items,
        (SELECT COUNT(*) FROM payments)    AS total_payments,
        (SELECT COUNT(*) FROM categories)  AS total_categories
),

-- ── 1. Duplicate customers by email ──────────────────────────────────────────
chk_dup_email AS (
    SELECT COUNT(*) AS issue_count
    FROM (
        SELECT email
        FROM customers
        GROUP BY email
        HAVING COUNT(*) > 1
    ) AS d
),

-- ── 2. Duplicate customer full names ─────────────────────────────────────────
chk_dup_name AS (
    SELECT COUNT(*) AS issue_count
    FROM (
        SELECT CONCAT(first_name, ' ', last_name)
        FROM customers
        GROUP BY CONCAT(first_name, ' ', last_name)
        HAVING COUNT(*) > 1
    ) AS d
),

-- ── 3. Duplicate phone numbers ────────────────────────────────────────────────
chk_dup_phone AS (
    SELECT COUNT(*) AS issue_count
    FROM (
        SELECT phone
        FROM customers
        WHERE phone IS NOT NULL
        GROUP BY phone
        HAVING COUNT(*) > 1
    ) AS d
),

-- ── 4. Customers missing phone ────────────────────────────────────────────────
chk_null_phone AS (
    SELECT SUM(CASE WHEN phone IS NULL OR phone = '' THEN 1 ELSE 0 END) AS issue_count
    FROM customers
),

-- ── 5. Customers missing date_of_birth ───────────────────────────────────────
chk_null_dob AS (
    SELECT SUM(CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END) AS issue_count
    FROM customers
),

-- ── 6. Products missing cost_price ───────────────────────────────────────────
chk_null_cost AS (
    SELECT SUM(CASE WHEN cost_price IS NULL THEN 1 ELSE 0 END) AS issue_count
    FROM products
),

-- ── 7. Delivered orders missing actual_delivery date ─────────────────────────
chk_del_no_date AS (
    SELECT SUM(CASE WHEN status = 'Delivered' AND actual_delivery IS NULL THEN 1 ELSE 0 END) AS issue_count
    FROM orders
),

-- ── 8. Invalid email format ───────────────────────────────────────────────────
chk_bad_email AS (
    SELECT COUNT(*) AS issue_count
    FROM customers
    WHERE email NOT REGEXP '^[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,10}$'
       OR email IS NULL OR email = ''
),

-- ── 9. Same-day duplicate orders per customer ─────────────────────────────────
chk_dup_orders AS (
    SELECT COUNT(*) AS issue_count
    FROM (
        SELECT customer_id, DATE(order_date)
        FROM orders
        GROUP BY customer_id, DATE(order_date)
        HAVING COUNT(*) > 1
    ) AS d
),

-- ── 10. Orphan order_items (no parent order) ─────────────────────────────────
chk_orphan_items AS (
    SELECT COUNT(*) AS issue_count
    FROM order_items oi
    LEFT JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_id IS NULL
),

-- ── 11. Orphan payments (no parent order) ────────────────────────────────────
chk_orphan_pay AS (
    SELECT COUNT(*) AS issue_count
    FROM payments pay
    LEFT JOIN orders o ON o.order_id = pay.order_id
    WHERE o.order_id IS NULL
),

-- ── 12. Customers with no orders ─────────────────────────────────────────────
chk_no_orders AS (
    SELECT COUNT(*) AS issue_count
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_id IS NULL
),

-- ── 13. Orders with wrong total_amount ───────────────────────────────────────
chk_bad_total AS (
    SELECT COUNT(*) AS issue_count
    FROM orders
    WHERE ABS(
        total_amount - (subtotal - discount_amount + tax_amount + shipping_charge)
    ) > 0.01
),

-- ── 14. Order items with wrong line_total ────────────────────────────────────
chk_bad_line AS (
    SELECT COUNT(*) AS issue_count
    FROM order_items
    WHERE ABS(
        line_total - ROUND(quantity * unit_price * (1 - discount_pct / 100), 2)
    ) > 0.01
),

-- ── 15. Products with zero or negative unit_price ────────────────────────────
chk_zero_price AS (
    SELECT COUNT(*) AS issue_count
    FROM products
    WHERE unit_price <= 0
),

-- ── 16. Products sold at a loss (cost > price) ───────────────────────────────
chk_neg_margin AS (
    SELECT COUNT(*) AS issue_count
    FROM products
    WHERE cost_price IS NOT NULL AND unit_price < cost_price
),

-- ── 17. Future-dated orders ───────────────────────────────────────────────────
chk_future_orders AS (
    SELECT COUNT(*) AS issue_count
    FROM orders
    WHERE order_date > NOW()
),

-- ── 18. Orders delivered before placement ─────────────────────────────────────
chk_bad_delivery AS (
    SELECT COUNT(*) AS issue_count
    FROM orders
    WHERE actual_delivery IS NOT NULL
      AND actual_delivery < DATE(order_date)
),

-- ── 19. Payments before order date ────────────────────────────────────────────
chk_early_payment AS (
    SELECT COUNT(*) AS issue_count
    FROM payments pay
    JOIN orders o ON o.order_id = pay.order_id
    WHERE pay.payment_date < o.order_date
),

-- ── 20. Future date_of_birth ──────────────────────────────────────────────────
chk_future_dob AS (
    SELECT COUNT(*) AS issue_count
    FROM customers
    WHERE date_of_birth > CURDATE()
),

-- ── 21. Underpaid / unpaid delivered orders ───────────────────────────────────
chk_underpaid AS (
    SELECT COUNT(*) AS issue_count
    FROM (
        SELECT o.order_id
        FROM orders o
        LEFT JOIN payments pay
            ON pay.order_id = o.order_id
           AND pay.status IN ('Captured','Authorized')
        WHERE o.status NOT IN ('Cancelled','Returned')
        GROUP BY o.order_id, o.total_amount
        HAVING ABS(o.total_amount - COALESCE(SUM(pay.amount), 0)) > 0.01
    ) AS u
)

-- ── Final UNION report ────────────────────────────────────────────────────────
SELECT
    check_category,
    check_name,
    issue_count,
    total_records,
    ROUND(issue_count / NULLIF(total_records, 0) * 100, 2) AS issue_pct,
    severity,
    recommendation
FROM (

    -- Table metadata (INFO rows)
    SELECT 'Table Sizes' AS check_category, 'Total Customers'    AS check_name, bc.total_customers    AS issue_count, bc.total_customers    AS total_records, 'INFO' AS severity, 'Reference count only'               AS recommendation FROM base_counts bc
    UNION ALL
    SELECT 'Table Sizes', 'Total Products',    bc.total_products,    bc.total_products,    'INFO', 'Reference count only'               FROM base_counts bc
    UNION ALL
    SELECT 'Table Sizes', 'Total Orders',      bc.total_orders,      bc.total_orders,      'INFO', 'Reference count only'               FROM base_counts bc
    UNION ALL
    SELECT 'Table Sizes', 'Total Order Items', bc.total_order_items, bc.total_order_items, 'INFO', 'Reference count only'               FROM base_counts bc
    UNION ALL
    SELECT 'Table Sizes', 'Total Payments',    bc.total_payments,    bc.total_payments,    'INFO', 'Reference count only'               FROM base_counts bc
    UNION ALL
    SELECT 'Table Sizes', 'Total Categories',  bc.total_categories,  bc.total_categories,  'INFO', 'Reference count only'               FROM base_counts bc

    -- Duplicate checks
    UNION ALL
    SELECT 'Duplicates', 'Duplicate Emails',
        c.issue_count, bc.total_customers, 'HIGH',
        'Merge duplicate accounts; enforce UNIQUE constraint on email'
    FROM chk_dup_email c, base_counts bc
    UNION ALL
    SELECT 'Duplicates', 'Duplicate Full Names',
        c.issue_count, bc.total_customers, 'MEDIUM',
        'Review manually — may be coincidental; merge if same person'
    FROM chk_dup_name c, base_counts bc
    UNION ALL
    SELECT 'Duplicates', 'Duplicate Phone Numbers',
        c.issue_count, bc.total_customers, 'MEDIUM',
        'Verify shared phones are not the same person with two accounts'
    FROM chk_dup_phone c, base_counts bc
    UNION ALL
    SELECT 'Duplicates', 'Same-Day Orders per Customer',
        c.issue_count, bc.total_orders, 'LOW',
        'Review for accidental double-submissions; cancel true duplicates'
    FROM chk_dup_orders c, base_counts bc

    -- NULL / Missing value checks
    UNION ALL
    SELECT 'Missing Values', 'Customers Missing Phone',
        c.issue_count, bc.total_customers, 'MEDIUM',
        'Send email prompts asking customers to add a phone number'
    FROM chk_null_phone c, base_counts bc
    UNION ALL
    SELECT 'Missing Values', 'Customers Missing Date of Birth',
        c.issue_count, bc.total_customers, 'LOW',
        'Collect DOB during next login or profile update'
    FROM chk_null_dob c, base_counts bc
    UNION ALL
    SELECT 'Missing Values', 'Products Missing Cost Price',
        c.issue_count, bc.total_products, 'MEDIUM',
        'Request cost data from procurement; needed for margin analysis'
    FROM chk_null_cost c, base_counts bc
    UNION ALL
    SELECT 'Missing Values', 'Delivered Orders Without Actual Delivery Date',
        c.issue_count, bc.total_orders, 'HIGH',
        'Backfill from courier API or logistics system'
    FROM chk_del_no_date c, base_counts bc

    -- Email format checks
    UNION ALL
    SELECT 'Email Validation', 'Invalid Email Format',
        c.issue_count, bc.total_customers, 'HIGH',
        'Contact affected customers via phone; correct email at next login'
    FROM chk_bad_email c, base_counts bc

    -- Orphan record checks
    UNION ALL
    SELECT 'Referential Integrity', 'Orphan Order Items (no parent order)',
        c.issue_count, bc.total_order_items, 'HIGH',
        'Delete orphan items or restore missing orders from backup'
    FROM chk_orphan_items c, base_counts bc
    UNION ALL
    SELECT 'Referential Integrity', 'Orphan Payments (no parent order)',
        c.issue_count, bc.total_payments, 'HIGH',
        'Reconcile with payment gateway; refund or link to correct order'
    FROM chk_orphan_pay c, base_counts bc
    UNION ALL
    SELECT 'Referential Integrity', 'Customers With No Orders',
        c.issue_count, bc.total_customers, 'INFO',
        'Target with re-engagement campaigns; not necessarily an error'
    FROM chk_no_orders c, base_counts bc

    -- Amount / Price checks
    UNION ALL
    SELECT 'Financial Integrity', 'Orders With Incorrect total_amount',
        c.issue_count, bc.total_orders, 'HIGH',
        'Recalculate totals; audit pricing engine for bugs'
    FROM chk_bad_total c, base_counts bc
    UNION ALL
    SELECT 'Financial Integrity', 'Order Items With Incorrect line_total',
        c.issue_count, bc.total_order_items, 'HIGH',
        'Recalculate line totals; check discount application logic'
    FROM chk_bad_line c, base_counts bc
    UNION ALL
    SELECT 'Financial Integrity', 'Products With Zero/Negative unit_price',
        c.issue_count, bc.total_products, 'HIGH',
        'Update pricing immediately; check import pipeline'
    FROM chk_zero_price c, base_counts bc
    UNION ALL
    SELECT 'Financial Integrity', 'Products Sold Below Cost Price',
        c.issue_count, bc.total_products, 'MEDIUM',
        'Confirm intentional loss-leaders; correct if accidental'
    FROM chk_neg_margin c, base_counts bc
    UNION ALL
    SELECT 'Financial Integrity', 'Orders Underpaid or Unpaid',
        c.issue_count, bc.total_orders, 'HIGH',
        'Chase outstanding payments; check payment gateway status'
    FROM chk_underpaid c, base_counts bc

    -- Date / temporal checks
    UNION ALL
    SELECT 'Date Validity', 'Future-Dated Orders',
        c.issue_count, bc.total_orders, 'HIGH',
        'Correct order dates; audit data import scripts for clock errors'
    FROM chk_future_orders c, base_counts bc
    UNION ALL
    SELECT 'Date Validity', 'Orders Delivered Before Placement',
        c.issue_count, bc.total_orders, 'HIGH',
        'Correct delivery dates; verify logistics feed timestamps'
    FROM chk_bad_delivery c, base_counts bc
    UNION ALL
    SELECT 'Date Validity', 'Payments Before Order Date',
        c.issue_count, bc.total_payments, 'HIGH',
        'Correct payment timestamps; check timezone handling in gateway'
    FROM chk_early_payment c, base_counts bc
    UNION ALL
    SELECT 'Date Validity', 'Customers With Future Date of Birth',
        c.issue_count, bc.total_customers, 'HIGH',
        'Correct DOB; validate DOB < today at registration'
    FROM chk_future_dob c, base_counts bc

) AS quality_report
ORDER BY
    CASE severity
        WHEN 'HIGH'   THEN 1
        WHEN 'MEDIUM' THEN 2
        WHEN 'LOW'    THEN 3
        ELSE               4
    END,
    issue_count DESC,
    check_category,
    check_name;

-- =============================================================================
-- END OF data_quality_checks.sql
-- =============================================================================
