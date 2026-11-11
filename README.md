# Customer Segmentation & Purchase Behavior Analytics (SQL Project)

A professional, portfolio-grade **pure MySQL analytics project** designed to perform exploratory data analysis, customer segmentation, cohort retention, basket affinity, and executive financial reporting on an e-commerce transactional database.

---

## 📌 Project Overview

This repository demonstrates production-level SQL proficiency by answering complex business questions using modern SQL techniques:
- **RFM Customer Segmentation** (Recency, Frequency, Monetary modeling via statistical quartiles)
- **Customer Lifetime Value (CLV & LTV)** and 80/20 Pareto revenue concentration
- **Market Basket Analysis** (cross-category co-purchase affinity & order depth)
- **Time-Series Sales Growth** (MoM & QoQ trajectory, moving revenue metrics)
- **Customer Cohort Retention & Churn Analysis** (retention decay matrices & proactive CRM alerts)
- **Executive Business Reports & 360-Degree Customer Summaries**

---

## 🛠️ Technology Stack

- **RDBMS**: MySQL 8.0+
- **Database Engine**: InnoDB
- **Character Encoding**: `utf8mb4` / `utf8mb4_unicode_ci`
- **Key SQL Concepts Used**:
  - **Common Table Expressions (CTEs)**: Recursive and multi-stage CTE pipelines
  - **Window Functions**: `NTILE()`, `ROW_NUMBER()`, `DENSE_RANK()`, `PERCENT_RANK()`, `LAG()`, `LEAD()`, `SUM() OVER ()`, `AVG() OVER ()`
  - **Complex JOINs**: Multi-table INNER/LEFT JOINs, self-joins for co-occurrence, and cross joins for summary totals
  - **Conditional Logic**: Multi-tier `CASE` expressions for tier scoring and cohort grouping
  - **Aggregations & Filtering**: `HAVING`, `GROUP BY`, date-part extraction (`DATE_FORMAT`, `TIMESTAMPDIFF`, `DATEDIFF`)
  - **Data Integrity**: Primary keys, foreign key constraints (`CASCADE` & `RESTRICT`), uniqueness constraints, and checks

---

## 📁 Repository & File Structure

```
customer_analytics/
├── database/
│   ├── schema.sql                         # Database setup, 6 tables, keys, constraints, and indexes
│   └── sample_data.sql                    # Seed dataset (10 categories, 55 products, 30 customers, 60 orders, 110 items, 65 payments)
│
├── sql_scripts/
│   ├── 01_customer_segmentation.sql       # RFM modeling, Pareto spend percentiles, demographic & geo clustering
│   ├── 02_purchase_behavior_analysis.sql  # Re-order velocity, market basket cross-selling, basket depth, payments
│   ├── 03_sales_analysis.sql              # MoM revenue growth, category gross margins, top SKUs, delivery SLAs
│   ├── 04_customer_retention.sql          # Monthly cohort retention matrices, churn risk alerts, repeat buyer analysis
│   └── 05_business_reports.sql            # C-level KPI scorecard, QBR matrix, and 360-degree customer profile
│
└── README.md                              # Project documentation & portfolio guide
```

---

## 🗄️ Relational Schema (ERD Overview)

```
categories (10 rows)
   │
   └──< products (55 rows)
           │
           └──< order_items (110 rows) >── orders (60 rows) >── customers (30 rows)
                                              │
                                              └──< payments (65 rows)
```

| Table Name | Description | Primary Key | Foreign Keys |
|---|---|---|---|
| `categories` | Product departments & classifications | `category_id` | — |
| `products` | SKUs, cost prices, unit prices, and stock inventory | `product_id` | `category_id` → `categories.category_id` |
| `customers` | Demographics, addresses, acquisition dates, segments | `customer_id` | — |
| `orders` | Transaction headers, point-in-time addresses, totals | `order_id` | `customer_id` → `customers.customer_id` |
| `order_items` | Individual line items (quantity, unit price, discounts) | `order_item_id` | `order_id` → `orders.order_id`<br>`product_id` → `products.product_id` |
| `payments` | Transaction references, methods, statuses, gateways | `payment_id` | `order_id` → `orders.order_id` |

---

## 🚀 Setup & Execution Guide

Open any MySQL CLI or GUI client (MySQL Workbench, DBeaver, DataGrip, VS Code SQLTools) and run:

```sql
-- Step 1: Initialize database schema & constraints
SOURCE database/schema.sql;

-- Step 2: Populate sample database records
SOURCE database/sample_data.sql;

-- Step 3: Run analytics modules
SOURCE sql_scripts/01_customer_segmentation.sql;
SOURCE sql_scripts/02_purchase_behavior_analysis.sql;
SOURCE sql_scripts/03_sales_analysis.sql;
SOURCE sql_scripts/04_customer_retention.sql;
SOURCE sql_scripts/05_business_reports.sql;
```

---

## 📊 Analytical Modules & Business Questions

### 1. Customer Segmentation (`01_customer_segmentation.sql`)
- **Q1: Dynamic RFM Segmentation**: Computes Recency, Frequency, and Monetary scores using `NTILE(4)` to classify accounts into *Champions (VIP)*, *Loyal Customers*, *Potential Loyalists*, and *At-Risk*.
- **Q2: Pareto 80/20 & Spend Percentiles**: Calculates `PERCENT_RANK()` and running cumulative revenue to identify the contribution of top 10% and top 25% spenders.
- **Q3: Demographic Cohorts**: Evaluates purchasing power and AOV across age brackets (<25 Gen Z, 25-34 Millennials, 35-44 Gen X, 45+ Boomers) and genders.
- **Q4: Geographic Clustering**: Ranks cities and states by total GMV and customer lifetime value.

### 2. Purchase Behavior Analysis (`02_purchase_behavior_analysis.sql`)
- **Q1: Repeat Purchase Velocity**: Employs `LAG()` window functions to measure days elapsed between 1st, 2nd, 3rd, and 4th+ orders.
- **Q2: Market Basket Co-Purchase Affinity**: Self-joins `order_items` across unique product categories to surface top cross-sell bundles.
- **Q3: Basket Size & Multi-Item Depth**: Groups orders into single-item, double, medium, and bulk baskets to analyze unit volume vs discount elasticity.
- **Q4: Payment Method Preferences**: Evaluates transaction volume, average ticket size, and payment gateway capture rates (Credit Card, UPI, EMI, COD, Net Banking).

### 3. Sales Analysis (`03_sales_analysis.sql`)
- **Q1: Monthly Trajectory & MoM Growth**: Uses `LAG()` and `SUM() OVER ()` for running cumulative revenue and month-over-month growth percentages.
- **Q2: Category Profitability**: Measures Gross Merchandise Value (GMV), Cost of Goods Sold (COGS), and Gross Margin % across categories.
- **Q3: Top 10 Best-Selling SKUs**: Ranks products by unit volume and revenue contribution.
- **Q4: Delivery SLA Performance**: Compares actual vs estimated delivery timestamps to evaluate fulfillment reliability.

### 4. Customer Retention (`04_customer_retention.sql`)
- **Q1: Monthly Cohort Retention Matrix**: Organizes customers into acquisition cohorts and measures retention activity in subsequent quarters.
- **Q2: Churn Risk & CRM Triggers**: Flags inactive accounts based on recency thresholds and generates targeted marketing actions (e.g., win-back vouchers).
- **Q3: One-Time Buyers vs Repeat Loyalists**: Compares customer volume and aggregate revenue generated by single-purchase vs multi-purchase accounts.

### 5. Business Reports (`05_business_reports.sql`)
- **Report 1: Executive KPI Scorecard**: Single-row C-level summary displaying active user rates, total revenue, discount rates, AOV, and ARPU.
- **Report 2: Quarterly Business Review (QBR)**: Compares performance across 8 calendar quarters (Q1 2025 to Q4 2026) with QoQ percentage growth.
- **Report 3: Customer 360 Lifetime Profile**: Generates an exhaustive customer view combining demographics, total spend, favorite category, preferred payment method, and overall rank.

---

## 🏆 Portfolio Highlights

- **Standard SQL Compliance**: 100% compliant with MySQL 8.0+ `ONLY_FULL_GROUP_BY` strict mode.
- **Production-Ready Formatting**: Explicit column aliases, currency formatting (`₹`), and clean commenting.
- **Real-World Business Impact**: Directly maps analytical outputs to marketing, inventory, and executive business decisions.
