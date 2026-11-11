-- =============================================================================
-- PROJECT  : Customer Segmentation & Purchase Behavior Analytics Using SQL
-- FILE     : schema.sql
-- PURPOSE  : Database schema — tables, relationships, constraints, indexes
-- ENGINE   : MySQL 8.0+
-- CHARSET  : utf8mb4 / utf8mb4_unicode_ci
-- CREATED  : 2026-11-10
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 0. Database Setup
-- ---------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS customer_analytics
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE customer_analytics;

-- Disable FK checks during (re)creation to allow any drop/create order
SET FOREIGN_KEY_CHECKS = 0;

-- Drop tables in reverse-dependency order so the script is idempotent
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;


-- =============================================================================
-- TABLE 1: categories
-- Lookup / master table for product categories.
-- =============================================================================
CREATE TABLE categories (
    category_id    INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    category_name  VARCHAR(100)   NOT NULL,
    description    TEXT,
    is_active      TINYINT(1)     NOT NULL DEFAULT 1,
    created_at     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
                                           ON UPDATE CURRENT_TIMESTAMP,

    -- ── Keys & Constraints ──────────────────────────────────────────────────
    CONSTRAINT pk_categories      PRIMARY KEY (category_id),
    CONSTRAINT uq_categories_name UNIQUE      (category_name)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Product categories — Electronics, Clothing, Home & Kitchen, etc.';


-- =============================================================================
-- TABLE 2: customers
-- Core customer master table — the backbone of all segmentation analytics.
-- =============================================================================
CREATE TABLE customers (
    customer_id        INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    first_name         VARCHAR(60)    NOT NULL,
    last_name          VARCHAR(60)    NOT NULL,
    email              VARCHAR(150)   NOT NULL,
    phone              VARCHAR(20),
    gender             ENUM('Male','Female','Other','Prefer not to say')
                                      NOT NULL DEFAULT 'Prefer not to say',
    date_of_birth      DATE,

    -- Segment label — updated by analytics jobs / triggers
    segment            ENUM('New','Bronze','Silver','Gold','Platinum')
                                      NOT NULL DEFAULT 'New',

    -- Address
    address_line1      VARCHAR(200),
    address_line2      VARCHAR(200),
    city               VARCHAR(100),
    state              VARCHAR(100),
    country            VARCHAR(100)   NOT NULL DEFAULT 'India',
    postal_code        VARCHAR(20),

    -- Account metadata
    is_active          TINYINT(1)     NOT NULL DEFAULT 1,
    registration_date  DATE           NOT NULL DEFAULT (CURRENT_DATE),
    last_login         DATETIME,
    created_at         DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
                                               ON UPDATE CURRENT_TIMESTAMP,

    -- ── Keys & Constraints ──────────────────────────────────────────────────
    CONSTRAINT pk_customers       PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_email UNIQUE      (email),
    CONSTRAINT chk_customers_dob  CHECK       (date_of_birth < CURRENT_DATE)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Customer master — demographics, segment, address, account status';

-- Indexes for common filter / join / GROUP BY columns
CREATE INDEX idx_customers_segment    ON customers (segment);
CREATE INDEX idx_customers_city_state ON customers (city, state);
CREATE INDEX idx_customers_reg_date   ON customers (registration_date);
CREATE INDEX idx_customers_gender     ON customers (gender);


-- =============================================================================
-- TABLE 3: products
-- Individual product SKUs linked to a parent category.
-- =============================================================================
CREATE TABLE products (
    product_id      INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    category_id     INT UNSIGNED   NOT NULL,
    product_name    VARCHAR(200)   NOT NULL,
    sku             VARCHAR(50)    NOT NULL,
    description     TEXT,
    unit_price      DECIMAL(10,2)  NOT NULL,
    cost_price      DECIMAL(10,2),
    stock_quantity  INT            NOT NULL DEFAULT 0,
    reorder_level   INT            NOT NULL DEFAULT 10,
    brand           VARCHAR(100),
    is_active       TINYINT(1)     NOT NULL DEFAULT 1,
    created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
                                            ON UPDATE CURRENT_TIMESTAMP,

    -- ── Keys & Constraints ──────────────────────────────────────────────────
    CONSTRAINT pk_products          PRIMARY KEY (product_id),
    CONSTRAINT uq_products_sku      UNIQUE      (sku),
    CONSTRAINT chk_products_price   CHECK       (unit_price  >= 0),
    CONSTRAINT chk_products_cost    CHECK       (cost_price  >= 0 OR cost_price IS NULL),
    CONSTRAINT chk_products_stock   CHECK       (stock_quantity >= 0),

    -- Foreign Key → categories
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES  categories (category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Product catalogue — SKUs, pricing, stock levels, brand';

CREATE INDEX idx_products_category ON products (category_id);
CREATE INDEX idx_products_brand    ON products (brand);
CREATE INDEX idx_products_price    ON products (unit_price);
CREATE INDEX idx_products_active   ON products (is_active);


-- =============================================================================
-- TABLE 4: orders
-- Order header — one row per customer order.
-- Shipping address is snapshotted at order time (denormalised intentionally).
-- =============================================================================
CREATE TABLE orders (
    order_id            INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    customer_id         INT UNSIGNED   NOT NULL,
    order_date          DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status              ENUM(
                            'Pending',
                            'Confirmed',
                            'Processing',
                            'Shipped',
                            'Delivered',
                            'Cancelled',
                            'Returned'
                        )              NOT NULL DEFAULT 'Pending',

    -- Shipping address (point-in-time snapshot)
    shipping_address    VARCHAR(300),
    shipping_city       VARCHAR(100),
    shipping_state      VARCHAR(100),
    shipping_country    VARCHAR(100)   NOT NULL DEFAULT 'India',
    shipping_postal     VARCHAR(20),

    -- Financials
    subtotal            DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    discount_amount     DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    tax_amount          DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
    shipping_charge     DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    total_amount        DECIMAL(12,2)  NOT NULL DEFAULT 0.00,

    -- Delivery tracking
    estimated_delivery  DATE,
    actual_delivery     DATE,
    notes               TEXT,
    created_at          DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
                                                ON UPDATE CURRENT_TIMESTAMP,

    -- ── Keys & Constraints ──────────────────────────────────────────────────
    CONSTRAINT pk_orders              PRIMARY KEY (order_id),
    CONSTRAINT chk_orders_subtotal    CHECK       (subtotal        >= 0),
    CONSTRAINT chk_orders_discount    CHECK       (discount_amount >= 0),
    CONSTRAINT chk_orders_tax         CHECK       (tax_amount      >= 0),
    CONSTRAINT chk_orders_shipping    CHECK       (shipping_charge >= 0),
    CONSTRAINT chk_orders_total       CHECK       (total_amount    >= 0),

    -- Foreign Key → customers
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES  customers (customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Order headers — one row per customer order with financial totals';

CREATE INDEX idx_orders_customer   ON orders (customer_id);
CREATE INDEX idx_orders_date       ON orders (order_date);
CREATE INDEX idx_orders_status     ON orders (status);
CREATE INDEX idx_orders_total      ON orders (total_amount);


-- =============================================================================
-- TABLE 5: order_items
-- Line items within an order — many-to-many bridge between orders & products.
-- unit_price is snapshotted at purchase time (product price may change later).
-- =============================================================================
CREATE TABLE order_items (
    order_item_id   INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    order_id        INT UNSIGNED   NOT NULL,
    product_id      INT UNSIGNED   NOT NULL,
    quantity        INT UNSIGNED   NOT NULL DEFAULT 1,
    unit_price      DECIMAL(10,2)  NOT NULL     COMMENT 'Price at time of purchase',
    discount_pct    DECIMAL(5,2)   NOT NULL DEFAULT 0.00
                                               COMMENT 'Line-level discount (0–100%)',
    line_total      DECIMAL(12,2)  NOT NULL     COMMENT 'quantity × unit_price × (1 − discount_pct/100)',
    created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- ── Keys & Constraints ──────────────────────────────────────────────────
    CONSTRAINT pk_order_items              PRIMARY KEY (order_item_id),

    -- A product can appear only once per order (consolidate quantities instead)
    CONSTRAINT uq_order_items_order_product UNIQUE (order_id, product_id),

    CONSTRAINT chk_order_items_qty         CHECK (quantity      > 0),
    CONSTRAINT chk_order_items_price       CHECK (unit_price    >= 0),
    CONSTRAINT chk_order_items_discount    CHECK (discount_pct  BETWEEN 0 AND 100),
    CONSTRAINT chk_order_items_total       CHECK (line_total    >= 0),

    -- Foreign Key → orders (cascade delete so removing an order removes its items)
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES  orders (order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Foreign Key → products (restrict — keep history even if product retired)
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES  products (product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Order line items — links orders ↔ products with quantity, price & discount';

CREATE INDEX idx_order_items_order   ON order_items (order_id);
CREATE INDEX idx_order_items_product ON order_items (product_id);


-- =============================================================================
-- TABLE 6: payments
-- Payment records linked to orders.
-- Supports split / instalment payments (multiple rows per order).
-- =============================================================================
CREATE TABLE payments (
    payment_id      INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    order_id        INT UNSIGNED   NOT NULL,
    payment_date    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    method          ENUM(
                        'Credit Card',
                        'Debit Card',
                        'Net Banking',
                        'UPI',
                        'Wallet',
                        'Cash on Delivery',
                        'EMI'
                    )              NOT NULL,
    amount          DECIMAL(12,2)  NOT NULL,
    currency        CHAR(3)        NOT NULL DEFAULT 'INR',
    status          ENUM(
                        'Pending',
                        'Authorized',
                        'Captured',
                        'Failed',
                        'Refunded',
                        'Partially Refunded'
                    )              NOT NULL DEFAULT 'Pending',
    transaction_ref VARCHAR(100)            COMMENT 'Gateway transaction / UTR reference',
    gateway         VARCHAR(60)             COMMENT 'e.g. Razorpay, Paytm, PhonePe',
    notes           VARCHAR(300),
    created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
                                            ON UPDATE CURRENT_TIMESTAMP,

    -- ── Keys & Constraints ──────────────────────────────────────────────────
    CONSTRAINT pk_payments         PRIMARY KEY (payment_id),

    -- Enforce unique transaction refs (NULL is allowed for COD)
    CONSTRAINT uq_payments_txn_ref UNIQUE (transaction_ref),

    CONSTRAINT chk_payments_amount CHECK (amount > 0),

    -- Foreign Key → orders
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES  orders (order_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Payment records — method, status, gateway reference per order';

CREATE INDEX idx_payments_order  ON payments (order_id);
CREATE INDEX idx_payments_date   ON payments (payment_date);
CREATE INDEX idx_payments_status ON payments (status);
CREATE INDEX idx_payments_method ON payments (method);


-- ---------------------------------------------------------------------------
-- Re-enable FK checks
-- ---------------------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 1;


-- =============================================================================
-- SCHEMA SUMMARY — Entity-Relationship Overview
-- =============================================================================
--
--  categories ──< products ──< order_items >── orders >── customers
--                                                   └──< payments
--
--  Relationship         Cardinality   FK Column(s)
--  ─────────────────────────────────────────────────────────────────────────
--  categories → products    1 : N     products.category_id
--  customers  → orders      1 : N     orders.customer_id
--  orders     → order_items 1 : N     order_items.order_id  (CASCADE DELETE)
--  products   → order_items 1 : N     order_items.product_id
--  orders     → payments    1 : N     payments.order_id
--
--  Tables      : 6
--  Indexes     : 18 (covering PKs, UQs, FKs, common analytics columns)
--  Constraints : PKs, UQs, FKs, CHECK constraints on all numeric columns
-- =============================================================================
