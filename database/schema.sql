-- =============================================================================
-- PROJECT  : Customer Segmentation & Purchase Behavior Analytics Using SQL
-- FILE     : schema.sql
-- PURPOSE  : Database schema definition — tables, keys, constraints, indexes
-- ENGINE   : MySQL 8.0+
-- AUTHOR   : Analytics Team
-- CREATED  : 2026-11-10
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 0. Database Setup
-- ---------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS customer_analytics
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE customer_analytics;

-- Disable FK checks during table creation for safety
SET FOREIGN_KEY_CHECKS = 0;


-- =============================================================================
-- TABLE 1: categories
-- Stores product category information.
-- =============================================================================
CREATE TABLE IF NOT EXISTS categories (
    category_id   INT            UNSIGNED NOT NULL AUTO_INCREMENT,
    category_name VARCHAR(100)   NOT NULL,
    description   TEXT,
    is_active     TINYINT(1)     NOT NULL DEFAULT 1,
    created_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
                                          ON UPDATE CURRENT_TIMESTAMP,

    -- Primary Key
    CONSTRAINT pk_categories PRIMARY KEY (category_id),

    -- Unique Constraints
    CONSTRAINT uq_categories_name UNIQUE (category_name)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Product categories — Electronics, Clothing, etc.';


-- =============================================================================
-- TABLE 2: customers
-- Core customer master table used as the backbone for all analytics.
-- =============================================================================
CREATE TABLE IF NOT EXISTS customers (
    customer_id        INT            UNSIGNED NOT NULL AUTO_INCREMENT,
    first_name         VARCHAR(60)    NOT NULL,
    last_name          VARCHAR(60)    NOT NULL,
    email              VARCHAR(150)   NOT NULL,
    phone              VARCHAR(20),
    gender             ENUM('Male','Female','Other','Prefer not to say')
                                      NOT NULL DEFAULT 'Prefer not to say',
    date_of_birth      DATE,
    -- Derived segment label (updated via analytics jobs / triggers)
    segment            ENUM('New','Bronze','Silver','Gold','Platinum')
                                      NOT NULL DEFAULT 'New',
    -- Address
    address_line1      VARCHAR(200),
    address_line2      VARCHAR(200),
    city               VARCHAR(100),
    state              VARCHAR(100),
    country            VARCHAR(100)   NOT NULL DEFAULT 'India',
    postal_code        VARCHAR(20),
    -- Account meta
    is_active          TINYINT(1)     NOT NULL DEFAULT 1,
    registration_date  DATE           NOT NULL DEFAULT (CURRENT_DATE),
    last_login         DATETIME,
    created_at         DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
                                               ON UPDATE CURRENT_TIMESTAMP,

    -- Primary Key
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),

    -- Unique Constraints
    CONSTRAINT uq_customers_email UNIQUE (email)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Customer master table — demographics, segment, contact info';

-- Index for common filter / join columns
CREATE INDEX idx_customers_segment     ON customers (segment);
CREATE INDEX idx_customers_city_state  ON customers (city, state);
CREATE INDEX idx_customers_reg_date    ON customers (registration_date);


-- =============================================================================
-- TABLE 3: products
-- Individual product SKUs linked to a category.
-- =============================================================================
CREATE TABLE IF NOT EXISTS products (
    product_id      INT            UNSIGNED NOT NULL AUTO_INCREMENT,
    category_id     INT            UNSIGNED NOT NULL,
    product_name    VARCHAR(200)   NOT NULL,
    sku             VARCHAR(50)    NOT NULL,
    description     TEXT,
    unit_price      DECIMAL(10,2)  NOT NULL CHECK (unit_price >= 0),
    cost_price      DECIMAL(10,2)           CHECK (cost_price >= 0),
    stock_quantity  INT            NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    reorder_level   INT            NOT NULL DEFAULT 10,
    brand           VARCHAR(100),
    is_active       TINYINT(1)     NOT NULL DEFAULT 1,
    created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
                                            ON UPDATE CURRENT_TIMESTAMP,

    -- Primary Key
    CONSTRAINT pk_products PRIMARY KEY (product_id),

    -- Unique Constraints
    CONSTRAINT uq_products_sku UNIQUE (sku),

    -- Foreign Keys
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES categories (category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Product catalog — SKUs, pricing, stock levels';

CREATE INDEX idx_products_category  ON products (category_id);
CREATE INDEX idx_products_brand     ON products (brand);
CREATE INDEX idx_products_price     ON products (unit_price);


-- =============================================================================
-- TABLE 4: orders
-- Order header — one row per customer order.
-- =============================================================================
CREATE TABLE IF NOT EXISTS orders (
    order_id            INT            UNSIGNED NOT NULL AUTO_INCREMENT,
    customer_id         INT            UNSIGNED NOT NULL,
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
    -- Shipping address (snapshot at order time)
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
    -- Delivery
    estimated_delivery  DATE,
    actual_delivery     DATE,
    notes               TEXT,
    created_at          DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
                                                ON UPDATE CURRENT_TIMESTAMP,

    -- Primary Key
    CONSTRAINT pk_orders PRIMARY KEY (order_id),

    -- Foreign Keys
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Order headers — one row per order placed by a customer';

CREATE INDEX idx_orders_customer   ON orders (customer_id);
CREATE INDEX idx_orders_date       ON orders (order_date);
CREATE INDEX idx_orders_status     ON orders (status);


-- =============================================================================
-- TABLE 5: order_items
-- Line items within an order (order ↔ product many-to-many bridge).
-- =============================================================================
CREATE TABLE IF NOT EXISTS order_items (
    order_item_id   INT            UNSIGNED NOT NULL AUTO_INCREMENT,
    order_id        INT            UNSIGNED NOT NULL,
    product_id      INT            UNSIGNED NOT NULL,
    quantity        INT            UNSIGNED NOT NULL DEFAULT 1
                                   CHECK (quantity > 0),
    unit_price      DECIMAL(10,2)  NOT NULL CHECK (unit_price >= 0),
    discount_pct    DECIMAL(5,2)   NOT NULL DEFAULT 0.00
                                   CHECK (discount_pct BETWEEN 0 AND 100),
    line_total      DECIMAL(12,2)  NOT NULL
                                   COMMENT 'quantity * unit_price * (1 - discount_pct/100)',
    created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Primary Key
    CONSTRAINT pk_order_items PRIMARY KEY (order_item_id),

    -- Prevent duplicate product entries in the same order
    CONSTRAINT uq_order_items_order_product UNIQUE (order_id, product_id),

    -- Foreign Keys
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Order line items — links orders to products with quantity & price';

CREATE INDEX idx_order_items_order    ON order_items (order_id);
CREATE INDEX idx_order_items_product  ON order_items (product_id);


-- =============================================================================
-- TABLE 6: payments
-- Payment records linked to orders (supports partial / split payments).
-- =============================================================================
CREATE TABLE IF NOT EXISTS payments (
    payment_id      INT            UNSIGNED NOT NULL AUTO_INCREMENT,
    order_id        INT            UNSIGNED NOT NULL,
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
    amount          DECIMAL(12,2)  NOT NULL CHECK (amount > 0),
    currency        CHAR(3)        NOT NULL DEFAULT 'INR',
    status          ENUM(
                        'Pending',
                        'Authorized',
                        'Captured',
                        'Failed',
                        'Refunded',
                        'Partially Refunded'
                    )              NOT NULL DEFAULT 'Pending',
    transaction_ref VARCHAR(100)   COMMENT 'Gateway transaction / UTR reference',
    gateway         VARCHAR(60)    COMMENT 'Razorpay, Paytm, etc.',
    notes           VARCHAR(300),
    created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
                                            ON UPDATE CURRENT_TIMESTAMP,

    -- Primary Key
    CONSTRAINT pk_payments PRIMARY KEY (payment_id),

    -- Unique transaction reference (nullable — only enforce when filled)
    CONSTRAINT uq_payments_txn_ref UNIQUE (transaction_ref),

    -- Foreign Keys
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Payment records — method, status, gateway reference per order';

CREATE INDEX idx_payments_order   ON payments (order_id);
CREATE INDEX idx_payments_date    ON payments (payment_date);
CREATE INDEX idx_payments_status  ON payments (status);
CREATE INDEX idx_payments_method  ON payments (method);


-- ---------------------------------------------------------------------------
-- Re-enable FK checks
-- ---------------------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 1;


-- =============================================================================
-- SCHEMA SUMMARY
-- =============================================================================
-- Table Relationships (ERD Summary):
--
--   categories ──< products ──< order_items >── orders >── customers
--                                                    └──< payments
--
--   categories  1──* products        (a category has many products)
--   customers   1──* orders          (a customer can place many orders)
--   orders      1──* order_items     (an order contains many line items)
--   products    1──* order_items     (a product appears in many orders)
--   orders      1──* payments        (an order can have multiple payments)
-- =============================================================================
