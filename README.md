# Customer Segmentation & Purchase Behavior Analytics Using SQL

> **Step 1 — Database Design & Sample Data**  
> Engine: MySQL 8.0+ · Character Set: utf8mb4

---

## 📁 Project Structure

```
customer_analytics/
└── database/
    ├── schema.sql       ← DDL: CREATE TABLE, constraints, indexes
    └── sample_data.sql  ← DML: INSERT seed data for all tables
```

---

## 🗄️ Database: `customer_analytics`

### Entity-Relationship Overview

```
categories ──< products ──< order_items >── orders >── customers
                                                 └──< payments
```

| Relationship | Cardinality | Description |
|---|---|---|
| categories → products | 1 : Many | A category contains many products |
| customers → orders | 1 : Many | A customer can place many orders |
| orders → order_items | 1 : Many | An order contains multiple line items |
| products → order_items | 1 : Many | A product can appear in many orders |
| orders → payments | 1 : Many | An order can have split / EMI payments |

---

## 📋 Tables

### 1. `categories`
Stores product category master data.

| Column | Type | Notes |
|---|---|---|
| `category_id` | INT UNSIGNED PK | Auto-increment |
| `category_name` | VARCHAR(100) | Unique |
| `description` | TEXT | Optional |
| `is_active` | TINYINT(1) | Soft delete flag |
| `created_at / updated_at` | DATETIME | Audit timestamps |

---

### 2. `customers`
Core customer master — the backbone of all analytics.

| Column | Type | Notes |
|---|---|---|
| `customer_id` | INT UNSIGNED PK | Auto-increment |
| `first_name / last_name` | VARCHAR(60) | Required |
| `email` | VARCHAR(150) | Unique, NOT NULL |
| `phone` | VARCHAR(20) | Optional |
| `gender` | ENUM | Male / Female / Other |
| `date_of_birth` | DATE | Used for age-based segmentation |
| `segment` | ENUM | New / Bronze / Silver / Gold / Platinum |
| `address_*` | VARCHAR | Full address snapshot |
| `registration_date` | DATE | Customer acquisition date |
| `is_active` | TINYINT(1) | Soft delete |

**Indexes:** `segment`, `(city, state)`, `registration_date`

---

### 3. `products`
Individual SKUs linked to a category.

| Column | Type | Notes |
|---|---|---|
| `product_id` | INT UNSIGNED PK | Auto-increment |
| `category_id` | INT UNSIGNED FK | → categories |
| `sku` | VARCHAR(50) | Unique |
| `unit_price / cost_price` | DECIMAL(10,2) | CHECK ≥ 0 |
| `stock_quantity` | INT | CHECK ≥ 0 |
| `reorder_level` | INT | Low-stock threshold |
| `brand` | VARCHAR(100) | Optional |

---

### 4. `orders`
Order header — one row per customer order.

| Column | Type | Notes |
|---|---|---|
| `order_id` | INT UNSIGNED PK | Auto-increment |
| `customer_id` | INT UNSIGNED FK | → customers |
| `order_date` | DATETIME | When order was placed |
| `status` | ENUM | Pending → Delivered / Returned |
| `shipping_*` | VARCHAR | Address snapshot at order time |
| `subtotal / discount_amount / tax_amount / shipping_charge / total_amount` | DECIMAL | Full financial breakdown |
| `estimated_delivery / actual_delivery` | DATE | Delivery tracking |

---

### 5. `order_items`
Line items within an order (order ↔ product bridge table).

| Column | Type | Notes |
|---|---|---|
| `order_item_id` | INT UNSIGNED PK | Auto-increment |
| `order_id` | INT UNSIGNED FK | → orders (CASCADE DELETE) |
| `product_id` | INT UNSIGNED FK | → products |
| `quantity` | INT UNSIGNED | CHECK > 0 |
| `unit_price` | DECIMAL(10,2) | Price at time of purchase |
| `discount_pct` | DECIMAL(5,2) | 0–100% |
| `line_total` | DECIMAL(12,2) | qty × price × (1 − discount%) |

**Unique:** `(order_id, product_id)` — prevents duplicate SKUs per order

---

### 6. `payments`
Payment records linked to orders (supports EMI / split payments).

| Column | Type | Notes |
|---|---|---|
| `payment_id` | INT UNSIGNED PK | Auto-increment |
| `order_id` | INT UNSIGNED FK | → orders |
| `method` | ENUM | Credit Card, UPI, EMI, COD, etc. |
| `amount` | DECIMAL(12,2) | CHECK > 0 |
| `status` | ENUM | Pending / Authorized / Captured / Refunded |
| `transaction_ref` | VARCHAR(100) | Gateway UTR / TXN ID (Unique) |
| `gateway` | VARCHAR(60) | Razorpay, Paytm, etc. |

---

## 📊 Sample Data Summary

| Table | Rows | Details |
|---|---|---|
| `categories` | 10 | Electronics, Clothing, Home & Kitchen, Books, Sports, Beauty, Toys, Grocery, Jewellery, Automotive |
| `products` | 50 | ~5 per category — real brand names, realistic Indian pricing |
| `customers` | 30 | Diverse cities (Mumbai, Bengaluru, Delhi, Chennai…), all segments, mixed genders |
| `orders` | 60 | Jan 2025 – Nov 2026, statuses from Pending to Returned |
| `order_items` | 110 | Multi-item orders included; price-at-purchase preserved |
| `payments` | 65 | 6 payment methods, EMI instalment rows, refund rows |

---

## 🚀 Setup Instructions

```sql
-- Step 1: Run schema first
SOURCE database/schema.sql;

-- Step 2: Seed sample data
SOURCE database/sample_data.sql;

-- Step 3: Verify row counts
SELECT 'categories'  AS tbl, COUNT(*) AS rows FROM categories
UNION ALL SELECT 'customers',   COUNT(*) FROM customers
UNION ALL SELECT 'products',    COUNT(*) FROM products
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'payments',    COUNT(*) FROM payments;
```

---

## 🔑 Key Design Decisions

| Decision | Rationale |
|---|---|
| `utf8mb4` charset | Full Unicode + emoji support |
| `DECIMAL` for money | Avoids floating-point rounding errors |
| Price snapshot in `order_items.unit_price` | Preserves historical accuracy if product price changes |
| Address snapshot in `orders` | Shipping address is immutable after order is placed |
| Soft deletes (`is_active`) | Retain historical customer/product data for analytics |
| `order_items` unique `(order_id, product_id)` | Prevents duplicate SKU rows in one order |
| Multiple payments per order | Supports EMI, split payments, and partial refunds |
| `segment` ENUM on customers | Enables fast filter/aggregation for segmentation queries |
