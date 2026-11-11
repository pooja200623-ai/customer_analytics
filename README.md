# Customer Segmentation & Purchase Behavior Analytics Using SQL

[![Database](https://img.shields.io/badge/Database-MySQL%208.0+-00758F?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![SQL Level](https://img.shields.io/badge/SQL-Advanced%20Queries%20%26%20Analytics-orange?style=for-the-badge)](https://en.wikipedia.org/wiki/SQL)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

An end-to-end, portfolio-ready data analytics project built entirely with **MySQL**. This project models, seeds, and analyzes e-commerce transactional data to uncover customer purchasing patterns, perform dynamic RFM segmentation, evaluate sales performance, measure cohort retention, and generate strategic executive business reports.

---

## 📑 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Project Objectives](#2-project-objectives)
3. [Technologies Used](#3-technologies-used)
4. [Database Structure & Schema](#4-database-structure--schema)
5. [Project Modules](#5-project-modules)
   - [Customer Segmentation](#module-1-customer-segmentation-customer_segmentationsql)
   - [Purchase Behavior Analysis](#module-2-purchase-behavior-analysis-purchase_behaviorsql)
   - [Sales Analysis](#module-3-sales-analysis-sales_analysissql)
   - [Customer Retention Analysis](#module-4-customer-retention-analysis-customer_retentionsql)
   - [Business Insights & Reports](#module-5-business-insights--reports-business_insightssql)
6. [SQL Concepts & Techniques Demonstrated](#6-sql-concepts--techniques-demonstrated)
7. [Database Setup Instructions](#7-database-setup-instructions)
8. [How to Execute the SQL Files](#8-how-to-execute-the-sql-files)
9. [Sample Business Questions Answered](#9-sample-business-questions-answered)
10. [Key Project Outcomes & Findings](#10-key-project-outcomes--findings)
11. [Repository Organization](#11-repository-organization)

---

## 1. Project Overview

In today's competitive e-commerce landscape, understanding customer behavior is critical for maximizing customer lifetime value, preventing churn, optimizing inventory, and guiding marketing spend.

This project designs a normalized **MySQL relational database** and implements business intelligence queries covering:
- **RFM Customer Segmentation** (Recency, Frequency, Monetary value modeling)
- **Basket Size & Order Depth Dynamics**
- **Period-over-Period (MoM, QoQ, YoY) Revenue Growth**
- **Customer Lifecycle & Cohort Retention Matrices**
- **Product Category Profitability & Top SKU Velocity**
- **Proactive Churn Prevention Alerts**

---

## 2. Project Objectives

- **Database Architecture**: Design a normalized, relational database schema (3NF) with primary keys, foreign keys, cascades, and check constraints.
- **Customer Segmentation**: Segment customers into actionable cohorts (New, Returning, Loyal, High-Value, Low-Value, Inactive) using statistical quartiles.
- **Purchase Behavior Modeling**: Analyze basket composition, re-order time gaps, payment preferences, and cross-category affinities.
- **Sales Performance Tracking**: Calculate Gross Merchandise Value (GMV), net revenue, discounts, shipping fees, taxes, and category margins.
- **Retention & Churn Tracking**: Build cohort matrices to evaluate customer attrition over rolling monthly intervals.
- **Actionable Business Intelligence**: Formulate data-driven answers to real-world commercial questions for marketing, supply chain, and executive teams.

---

## 3. Technologies Used

- **Database Management System**: MySQL 8.0+
- **Storage Engine**: InnoDB (ACID compliant with full foreign key constraints)
- **Character Set**: `utf8mb4` with `utf8mb4_unicode_ci` collation
- **Language**: Pure SQL (ANSI SQL compliant with MySQL 8.0 window functions and CTEs)
- **Strict Mode**: 100% compliant with MySQL strict mode (`ONLY_FULL_GROUP_BY`, `STRICT_TRANS_TABLES`)

---

## 4. Database Structure & Schema

The database consists of **6 normalized relational tables** tracking the entire e-commerce lifecycle:

```
categories (10 rows)
   │
   └──< products (55 rows)
           │
           └──< order_items (110 rows) >── orders (60 rows) >── customers (30 rows)
                                              │
                                              └──< payments (65 rows)
```

### Table Dictionary

| Table Name | Description | Primary Key | Foreign Keys & Constraints |
|---|---|---|---|
| **`categories`** | Master table for product departments | `category_id` | `category_name` (UNIQUE) |
| **`customers`** | Customer demographic and contact records | `customer_id` | `email` (UNIQUE), `segment` (ENUM), `date_of_birth` |
| **`products`** | Product catalog items, pricing, and stock | `product_id` | `category_id` &rarr; `categories.category_id` (RESTRICT)<br>`sku` (UNIQUE), `unit_price >= 0` |
| **`orders`** | Transaction headers and financial breakdowns | `order_id` | `customer_id` &rarr; `customers.customer_id` (RESTRICT)<br>`status` (ENUM), subtotal, discount, tax, shipping, total |
| **`order_items`** | Line items bridging orders and products | `order_item_id` | `order_id` &rarr; `orders.order_id` (CASCADE)<br>`product_id` &rarr; `products.product_id` (RESTRICT)<br>`(order_id, product_id)` (UNIQUE) |
| **`payments`** | Payment transaction logs and payment gateways | `payment_id` | `order_id` &rarr; `orders.order_id` (RESTRICT)<br>`method` (ENUM), `status` (ENUM), `transaction_ref` (UNIQUE) |

---

## 5. Project Modules

The analytical queries are organized into separate files:

### Module 1: Customer Segmentation (`customer_segmentation.sql`)
- **Purchasing History Summary**: Computes total orders, lifetime expenditure, AOV, and days since last purchase for every customer.
- **New Customers**: Identifies single-purchase buyers and recently acquired accounts.
- **Returning Customers**: Tracks customers who have placed $\ge 2$ orders across distinct dates.
- **Loyal Customers**: Isolates repeat brand advocates ($\ge 3$ orders) and measures brand loyalty.
- **High-Value Customers (HVCs)**: Surfaces top spenders whose expenditure places them above the platform average (~₹62,729) or in the top 25th percentile.
- **Low-Value Customers (LVCs)**: Evaluates the bottom quartile of spenders for basket expansion.
- **Inactive & At-Risk Customers**: Detects churn risks with $> 120$ days of dormancy.
- **Master Unified Segmentation Matrix**: Synthesizes recency, frequency, and spend into a unified executive tier.

### Module 2: Purchase Behavior Analysis (`purchase_behavior.sql`)
- **Customer Purchasing Profile**: Comprehensive audit of customer orders, spend, item depth, and active tenure.
- **Frequently Purchased Products**: Ranks top products by physical unit velocity, distinct orders, and revenue.
- **Purchase Frequency Distribution**: Classifies customer base into Single-Purchase, Occasional, Frequent, and Power Buyers.
- **Total Spending & Revenue Concentration**: Calculates individual revenue contribution and running cumulative GMV.
- **Average Order Value (AOV) Profiling**: Benchmarks customer basket size against the platform baseline (~₹31,364.53) into Premium, High, Moderate, and Economy tiers.
- **Category Affinity Analysis**: Determines each buyer's preferred product category based on items bought and spend.
- **Monthly Purchase Patterns**: Analyzes seasonal order volume fluctuations, active buyer counts, and MoM growth.
- **Highest Purchase Frequency**: Evaluates power shoppers ($\ge 3$ orders) and calculates average days between successive orders.
- **Recency & Churn Alerts**: Categorizes customers inactive for $> 90$, $> 150$, or $> 240$ days with targeted CRM re-engagement actions.

### Module 3: Sales Analysis (`sales_analysis.sql`)
- **Total Sales Revenue**: Complete audit of gross merchandise subtotal, net collected sales, discounts, taxes, and shipping fees.
- **Daily Sales Trends**: Analyzes daily sales velocity and calculates a 7-day rolling moving average of daily revenue.
- **Monthly Trajectory**: Evaluates month-by-month sales trajectory and Month-over-Month (MoM) growth rates.
- **Yearly Sales Performance**: Compares 2025 vs 2026 performance, computing Year-over-Year (YoY) revenue and order expansion.
- **Top-Selling Products by Volume**: Identifies fast-moving catalog SKUs by unit velocity.
- **Highest Revenue-Generating Products**: Highlights high-value SKUs contributing the largest monetary value.
- **Sales by Product Category**: Computes revenue contribution percentages and item counts across all 10 product categories.
- **AOV Dynamics**: Breaks down average order value across customer loyalty tiers and top geographic states.
- **Best-Performing Sales Months**: Ranks calendar months using statistical quartiles (`NTILE`) to identify peak demand seasons.
- **Period-over-Period Performance**: Measures quarterly business expansion (Q1 2025 &rarr; Q4 2026) with QoQ revenue changes.

### Module 4: Customer Retention Analysis (`customer_retention.sql`)
- **Repeat Customers**: Details multi-order customer lifespans, order counts, and total spend.
- **One-Time Customers**: Isolates single-order drop-offs and days elapsed since purchase.
- **Customer Retention Rate**: Calculates macro retention rates across converted buyers and total registered users.
- **Inactive Accounts**: Flags dormant accounts and classifies churn severity tiers with tailored marketing actions.
- **Repeat Purchase Cadence**: Measures how order values and re-order intervals evolve across sequential orders (Order 1 &rarr; 2 &rarr; 3 &rarr; 4+).
- **Customer Churn Rate**: Models customer attrition using a 180-day inactivity threshold and calculates revenue volume at risk.
- **Monthly Cohort Retention Matrix**: Builds an acquisition cohort matrix tracking repeat purchases over rolling monthly intervals (M0, M1-3, M4-6, M7-12, M13+).
- **Long-Gap Reactivations**: Discovers buyers reactivated after dormancy gaps of $\ge 180$ or $\ge 365$ days.

### Module 5: Business Insights & Reports (`business_insights.sql`)
- **Top 10 Highest-Spending Customers**: VIP accounts driving cumulative platform revenue.
- **Top 10 Best-Selling Products**: Physical volume champions and catalog market share.
- **Highest Revenue-Generating Categories**: Comprehensive breakdown of sales share across all 10 departments.
- **Most Valuable Customer Segments**: Commercial evaluation of Platinum, Gold, Silver, Bronze, and New tiers.
- **Monthly Sales Growth**: Absolute and percentage revenue changes with cumulative platform revenue.
- **Day-of-Week Purchasing Trends**: Identifies optimal days of the week for sales conversion and average basket sizes.
- **Inactive High-Value Customers**: Urgent churn alerts for VIP accounts ($> ₹50,000$ spend or Platinum/Gold) inactive for $> 90$ days.
- **Executive KPI Scorecard**: Single-row C-level summary capturing active buyer conversion, net revenue, discounts, AOV, and ARPU.

---

## 6. SQL Concepts & Techniques Demonstrated

This project showcases production-level SQL patterns:

- **Complex JOINs**: Multi-table `INNER JOIN`, `LEFT JOIN`, self-joins for co-purchase basket analysis, and `CROSS JOIN` for summary totals.
- **Aggregation & Filtering**: Multi-column `GROUP BY`, `HAVING` filters, `COUNT(DISTINCT ...)`, and mathematical rounding (`ROUND`, `FORMAT`).
- **Common Table Expressions (CTEs)**: Multi-stage pipelines for modular, readable query structures.
- **Window Functions**:
  - `ROW_NUMBER()`: Ranking category preferences per customer
  - `DENSE_RANK()`: Ranking top spenders, SKUs, and performance periods without skipping ranks
  - `NTILE(4)`: Dividing customers and sales months into statistical quartiles
  - `PERCENT_RANK()`: Calculating cumulative percentile distribution of customer spend
  - `LAG()` & `LEAD()`: Accessing prior row values for MoM growth, QoQ variances, and order interval gaps
  - `SUM() OVER ()` & `AVG() OVER ()`: Running cumulative totals and benchmark comparisons
- **Conditional Logic**: Multi-tier `CASE ... WHEN ... THEN ... ELSE ... END` statements for dynamic segmentation, churn scoring, and CRM recommendations.
- **Date & Time Functions**: `DATEDIFF()`, `TIMESTAMPDIFF()`, `DATE_FORMAT()`, `MONTHNAME()`, `DAYNAME()`, `DAYOFWEEK()`, and `QUARTER()`.

---

## 7. Database Setup Instructions

### Prerequisites
- MySQL Server 8.0 or higher installed and running locally or on a remote host.
- A MySQL client (MySQL Command Line Client, MySQL Workbench, DBeaver, or VS Code SQLTools).

### Step-by-Step Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/customer-analytics-sql.git
   cd customer-analytics-sql
   ```

2. **Log into MySQL**:
   ```bash
   mysql -u root -p
   ```

3. **Create Database & Build Schema**:
   Execute [`database/schema.sql`](database/schema.sql) to create the `customer_analytics` database and all 6 relational tables with primary keys, foreign keys, and indexes:
   ```sql
   SOURCE database/schema.sql;
   ```

4. **Seed Sample Data**:
   Execute [`database/sample_data.sql`](database/sample_data.sql) to populate realistic e-commerce data:
   ```sql
   SOURCE database/sample_data.sql;
   ```

5. **Verify Database Records**:
   ```sql
   USE customer_analytics;
   
   SELECT 'categories'  AS table_name, COUNT(*) AS total_rows FROM categories
   UNION ALL SELECT 'customers',   COUNT(*) FROM customers
   UNION ALL SELECT 'products',    COUNT(*) FROM products
   UNION ALL SELECT 'orders',      COUNT(*) FROM orders
   UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
   UNION ALL SELECT 'payments',    COUNT(*) FROM payments;
   ```

   **Expected Row Counts**:
   - `categories`: 10 rows
   - `customers`: 30 rows
   - `products`: 55 rows
   - `orders`: 60 rows
   - `order_items`: 110 rows
   - `payments`: 65 rows

---

## 8. How to Execute the SQL Files

Run any analytical module directly from the MySQL command line:

```sql
USE customer_analytics;

-- 1. Execute Customer Segmentation Analysis
SOURCE customer_segmentation.sql;

-- 2. Execute Purchase Behavior Analysis
SOURCE purchase_behavior.sql;

-- 3. Execute Sales & Revenue Analysis
SOURCE sales_analysis.sql;

-- 4. Execute Customer Retention & Churn Analysis
SOURCE customer_retention.sql;

-- 5. Execute Business Insights & Executive Reports
SOURCE business_insights.sql;
```

*Alternatively, open any of the `.sql` files in MySQL Workbench or DBeaver and run the individual queries section by section.*

---

## 9. Sample Business Questions Answered

| # | Business Question | Module | Key SQL Technique |
|---|---|---|---|
| **1** | *Who are our top 10 highest-spending customers and what share of company revenue do they generate?* | `business_insights.sql` | `CTE`, `DENSE_RANK()`, `SUM() OVER ()` |
| **2** | *What is our customer retention rate, and what percentage of buyers return for repeat purchases?* | `customer_retention.sql` | `CTE`, `SUM(CASE)`, `ROUND` |
| **3** | *How does Average Order Value (AOV) vary across customer loyalty tiers?* | `sales_analysis.sql` | `JOIN`, `GROUP BY`, `DENSE_RANK()` |
| **4** | *Which high-value customers have not purchased in over 90 days and require win-back action?* | `business_insights.sql` | `JOIN`, `DATEDIFF`, `CASE` |
| **5** | *What is the average time gap (in days) between a customer's 1st, 2nd, 3rd, and 4th orders?* | `customer_retention.sql` | `ROW_NUMBER()`, `LAG()`, `AVG()` |
| **6** | *Which product categories generate the highest gross revenue and profit margins?* | `sales_analysis.sql` | `JOIN`, `GROUP BY`, `DENSE_RANK()` |
| **7** | *How does Month-over-Month (MoM) revenue growth compare across operational months?* | `sales_analysis.sql` | `CTE`, `DATE_FORMAT()`, `LAG()` |
| **8** | *What are the most frequent cross-category product co-purchases in a single order?* | `purchase_behavior.sql` | `Self JOIN`, `COUNT(DISTINCT)` |

---

## 10. Key Project Outcomes & Findings

1. **80/20 Revenue Concentration**:
   - The top **25% of customers** account for over **55% of total gross merchandise value (GMV)**.
   - The top 10 spenders generated **₹15,28,499.00 out of ₹18,81,872.00 total revenue (81.22%)**.

2. **Customer Retention Health**:
   - Out of 29 converted buyers, **19 customers returned for repeat purchases**, yielding a **65.52% repeat buyer retention rate**.
   - Repeat buyers have an average lifetime spend that is **5.4x higher** than one-time buyers.

3. **Accelerating Purchase Cadence**:
   - The average interval between Order 1 and Order 2 is **~238 days**, but between Order 2 and Order 3 it shrinks to **~154 days**, and between Order 3 and Order 4 it drops to **~80 days**, indicating accelerating customer habituation.

4. **Category Revenue Dominance**:
   - **Electronics** represents the primary GMV driver (**> 63% of total revenue**), while **Jewellery** and **Home & Kitchen** generate steady high-ticket purchases. Everyday consumables (**Grocery & Food**, **Beauty**) drive repeat frequency.

5. **Actionable Churn Mitigation**:
   - Identified 3 high-value accounts (Meera Iyer: ₹1.71L spend; Sneha Kulkarni: ₹90K spend; Deepak Kumar: ₹63K spend) entering moderate dormancy ($> 90$ days), enabling targeted win-back campaigns prior to complete churn.

---

## 11. Repository Organization

```
customer_analytics/
├── database/
│   ├── schema.sql              # DDL: Table creation, constraints, foreign keys, indexes
│   └── sample_data.sql         # DML: Seed dataset with realistic e-commerce records
│
├── customer_segmentation.sql   # Module 1: Comprehensive customer segmentation queries
├── purchase_behavior.sql       # Module 2: Purchasing patterns, basket size & frequency queries
├── sales_analysis.sql          # Module 3: Revenue trends, top SKUs, category & period comparisons
├── customer_retention.sql      # Module 4: Retention rates, churn modeling & cohort matrices
├── business_insights.sql       # Module 5: Executive KPI scorecards & strategic commercial reports
│
└── README.md                   # Project documentation & GitHub portfolio showcase
```

---

## 👤 Author & Portfolio Showcase

- **Project**: Customer Segmentation & Purchase Behavior Analytics Using SQL
- **Database Engine**: MySQL 8.0+
- **Domain**: E-Commerce & Retail Business Intelligence (BI)

*Designed and engineered for a cleaner, fresher, and production-oriented SQL analytics portfolio.*
