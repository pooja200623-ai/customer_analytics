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
   - [Customer Segmentation (`customer_segmentation.sql`)](#module-1-customer-segmentation-customer_segmentationsql)
   - [Purchase Behavior Analysis (`purchase_behavior.sql`)](#module-2-purchase-behavior-analysis-purchase_behaviorsql)
   - [Sales Analysis (`sales_analysis.sql`)](#module-3-sales-analysis-sales_analysissql)
   - [Customer Retention Analysis (`customer_retention.sql`)](#module-4-customer-retention-analysis-customer_retentionsql)
   - [Business Insights & Reports (`business_insights.sql`)](#module-5-business-insights--reports-business_insightssql)
   - [Data Quality & Integrity Validation (`data_quality_checks.sql`)](#module-6-data-quality--integrity-validation-data_quality_checkssql)
   - [Executive Business Summary (`final_business_summary.sql`)](#module-7-executive-business-summary-final_business_summarysql)
6. [SQL Concepts & Techniques Demonstrated](#6-sql-concepts--techniques-demonstrated)
7. [Database Setup Instructions](#7-database-setup-instructions)
8. [How to Execute the SQL Files & Recommended Execution Order](#8-how-to-execute-the-sql-files--recommended-execution-order)
9. [Sample Business Questions Answered](#9-sample-business-questions-answered)
10. [Key Project Outcomes & Findings](#10-key-project-outcomes--findings)
11. [Repository Organization](#11-repository-organization)
12. [Project Audit & Quality Assurance](#12-project-audit--quality-assurance)

---

## 1. Project Overview

In today's competitive e-commerce landscape, understanding customer behavior is critical for maximizing customer lifetime value, preventing churn, optimizing inventory, and guiding marketing spend.

This project designs a normalized **MySQL relational database** and implements business intelligence queries covering:
- **RFM Customer Segmentation** (Recency, Frequency, Monetary value modeling)
- **Basket Size, Depth & Market Basket Affinity** (Co-purchase self-joins)
- **Period-over-Period (MoM, QoQ, YoY) Revenue Growth**
- **Customer Lifecycle & Cohort Retention Matrices**
- **Product Category Profitability & Top SKU Velocity**
- **Comprehensive Data Quality Validation Suite**
- **Single-Screen Executive KPI Dashboard & Customer 360 Profile**

---

## 2. Project Objectives

- **Database Architecture**: Design a normalized, relational database schema (3NF) with primary keys, foreign keys, cascades, and check constraints.
- **Customer Segmentation**: Segment customers into actionable cohorts (New, Returning, Loyal, High-Value, Low-Value, Inactive) using statistical quartiles, age demographics, and geographic market penetration.
- **Purchase Behavior Modeling**: Analyze basket composition, re-order time gaps, payment gateway success rates, and cross-category affinities using market basket self-joins.
- **Sales Performance Tracking**: Calculate Gross Merchandise Value (GMV), net revenue, discounts, shipping fees, taxes, delivery SLAs, and category profit margins.
- **Retention & Churn Tracking**: Build cohort matrices to evaluate customer attrition over rolling monthly intervals and identify reactivated win-backs.
- **Data Quality & Governance**: Execute a 30-check audit suite to detect duplicates, orphaned records, pricing anomalies, and date discrepancies.
- **Actionable Business Intelligence**: Formulate data-driven answers to real-world commercial questions for marketing, supply chain, and executive leadership.

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

The analytical queries are organized into distinct, production-ready modules:

### Module 1: Customer Segmentation (`customer_segmentation.sql`)
- **Purchasing History Summary**: Computes total orders, lifetime expenditure, AOV, and days since last purchase for every customer.
- **New Customers**: Identifies single-purchase buyers and recently acquired accounts.
- **Returning Customers**: Tracks customers who have placed $\ge 2$ orders across distinct dates.
- **Loyal Customers**: Isolates repeat brand advocates ($\ge 3$ orders) and measures brand loyalty.
- **High-Value Customers (HVCs)**: Surfaces top spenders whose expenditure places them above the platform average (~₹62,729) or in the top 25th percentile.
- **Low-Value Customers (LVCs)**: Evaluates the bottom quartile of spenders for basket expansion.
- **Inactive & At-Risk Customers**: Detects churn risks with $> 120$ days of dormancy.
- **Master Unified Segmentation Matrix**: Synthesizes recency, frequency, and spend into a unified executive tier.
- **Demographic Segmentation**: Analyzes AOV, order volume, and revenue across generational cohorts (Gen Z, Millennials, Young Gen X, Mature) and gender.
- **Geographic Segmentation & Market Penetration**: Ranks metro cities and states by customer concentration, sales, and Customer Lifetime Value (CLV).

### Module 2: Purchase Behavior Analysis (`purchase_behavior.sql`)
- **Customer Purchasing Profile**: Comprehensive audit of customer orders, spend, item depth, and active tenure using pre-aggregated CTEs (join fan-out safe).
- **Frequently Purchased Products**: Ranks top products by physical unit velocity, distinct orders, and revenue.
- **Purchase Frequency Distribution**: Classifies customer base into Single-Purchase, Occasional, Frequent, and Power Buyers.
- **Total Spending & Revenue Concentration**: Calculates individual revenue contribution and running cumulative GMV.
- **Average Order Value (AOV) Profiling**: Benchmarks customer basket size against the platform baseline (~₹31,364.53) into Premium, High, Moderate, and Economy tiers.
- **Category Affinity Analysis**: Determines each buyer's preferred product category based on items bought and spend.
- **Monthly Purchase Patterns**: Analyzes seasonal order volume fluctuations, active buyer counts, and MoM growth.
- **Highest Purchase Frequency**: Evaluates power shoppers ($\ge 3$ orders) and calculates average days between successive orders.
- **Recency & Churn Alerts**: Categorizes customers inactive for $> 90$, $> 150$, or $> 240$ days with targeted CRM re-engagement actions.
- **Cross-Category Product Affinity (Market Basket Analysis)**: Utilizes a self-join to reveal top product category pairs purchased together in the same transaction.
- **Basket Size & Multi-Item Order Distribution**: Classifies orders into Single Item, Double, Medium, and Large Bulk baskets.
- **Payment Method Preferences & Gateway Reliability**: Analyzes transaction share, average ticket size, and success/refund rates across UPI, Credit Card, EMI, COD, and Net Banking.

### Module 3: Sales Analysis (`sales_analysis.sql`)
- **Total Sales Revenue**: Complete audit of gross merchandise subtotal, net collected sales, discounts, taxes, and shipping fees.
- **Daily Sales Trends**: Analyzes daily sales velocity and calculates rolling moving averages.
- **Monthly Trajectory**: Evaluates month-by-month sales trajectory and Month-over-Month (MoM) growth rates.
- **Yearly Sales Performance**: Compares 2025 vs 2026 performance, computing Year-over-Year (YoY) revenue and order expansion.
- **Top-Selling Products by Volume**: Identifies fast-moving catalog SKUs by unit velocity.
- **Highest Revenue-Generating Products**: Highlights high-value SKUs contributing the largest monetary value.
- **Sales by Product Category**: Computes revenue contribution percentages and item counts across all 10 product categories.
- **AOV Dynamics**: Breaks down average order value across customer loyalty tiers and top geographic states.
- **Best-Performing Sales Months**: Ranks calendar months using statistical quartiles (`NTILE`) to identify peak demand seasons.
- **Period-over-Period Performance**: Measures quarterly business expansion (Q1 2025 &rarr; Q4 2026) with QoQ revenue changes.
- **Order Fulfillment & Delivery SLA Performance**: Tracks order status breakdown and evaluates on-time delivery SLA compliance rates.

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
- **Complete Customer 360 Lifetime Profile**: Single view of customer synthesizing demographics, loyalty tier, lifetime spend, preferred category, payment method, and recency.

### Module 6: Data Quality & Integrity Validation (`data_quality_checks.sql`)
- **Purpose**: A comprehensive, read-only diagnostic test suite executing 30 production-grade data quality checks to audit database consistency, referential integrity, and mathematical formula adherence before downstream analytical reporting.
- **Execution Order Role**: **Step 2 (Validation Phase)** — Run immediately after schema initialization and sample data seeding to ensure data hygiene prior to executing analytical modules.
- **Audits Included**:
  - **Duplicate Customer Records**: Detects duplicate emails, identical full names, and repeated phone numbers.
  - **NULL & Missing Value Audits**: Systematically checks mandatory attributes across `customers`, `products`, `orders`, and `payments`.
  - **Email Format Validation**: Flags non-conformant email syntax and analyzes email domain distributions.
  - **Duplicate Transactions**: Identifies same-customer same-day orders and exact financial duplicates.
  - **Referential Integrity & Orphan Records**: Validates foreign key relationships (orphaned order items, missing customers, non-existent products/categories).
  - **Financial Arithmetic Reconciliation**: Verifies formula calculations (`total_amount = subtotal - discount + tax + shipping` and `line_total = quantity * unit_price * (1 - discount%)`).
  - **Date & Timeline Consistency**: Flags future-dated orders, deliveries before order dates, and birth date anomalies.
  - **Consolidated Quality Dashboard**: Generates a single-view scorecard summarizing total anomalies per audit domain.

### Module 7: Executive Business Summary (`final_business_summary.sql`)
- **Purpose**: The capstone executive intelligence module providing board-ready reporting across 10 strategic KPI domains, synthesizing findings from across the database and concluding with a single-screen Master Executive KPI Dashboard.
- **Execution Order Role**: **Step 4 (Executive Synthesis Phase)** — Run as the final capstone module after reviewing domain-specific analyses to produce unified C-level metrics.
- **Reporting Sections**:
  - **Audience Metrics**: Total registered accounts, annual registration cohorts, and active/inactive user splits.
  - **Order Volume**: Orders per year, status breakdown, and fulfillment velocity.
  - **Revenue Overview**: Gross vs net revenue, order status revenue impact, and state contribution.
  - **AOV Dynamics**: Overall AOV, segment AOV, and ticket size by payment gateway.
  - **VIP Accounts**: Top 5 spenders with deep category purchase breakdowns.
  - **Product Champions**: Top 5 SKUs by volume and revenue, with full catalog sales rankings.
  - **Category Margins**: Departmental revenue, COGS, gross profit, and profit margin percentages.
  - **Segment Demographics**: Geographic concentration of top-tier accounts.
  - **Retention Milestones**: Single vs repeat purchase rates and inter-order gap distributions.
  - **Master Executive KPI Dashboard**: Cross-joins single-value subqueries to produce a comprehensive, single-screen KPI snapshot (total customers, active users, orders, revenue, AOV, top segment, top category, and repeat purchase rates).

---

## 6. SQL Concepts & Techniques Demonstrated

This project showcases production-level SQL patterns:

- **Complex JOINs**: Multi-table `INNER JOIN`, `LEFT JOIN`, self-joins for co-purchase basket analysis, and `CROSS JOIN` for summary totals.
- **Aggregation & Filtering**: Multi-column `GROUP BY`, `HAVING` filters, `COUNT(DISTINCT ...)`, and mathematical rounding (`ROUND`, `FORMAT`).
- **Common Table Expressions (CTEs)**: Multi-stage pipelines and pre-aggregated CTEs to eliminate join fan-outs.
- **Window Functions**:
  - `ROW_NUMBER()`: Ranking category preferences and sequential order intervals
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

## 8. How to Execute the SQL Files & Recommended Execution Order

To reproduce all analytics and validation checks, execute the SQL files in the following logical sequence:

### Recommended Execution Pipeline

1. **Phase 1: Database Initialization & Seeding**
   * **Purpose**: Creates the schema, tables, constraints, and indexes, followed by seeding the baseline dataset.
   ```sql
   USE customer_analytics;
   SOURCE database/schema.sql;
   SOURCE database/sample_data.sql;
   ```

2. **Phase 2: Data Quality & Integrity Validation (`data_quality_checks.sql`)**
   * **Purpose**: Run immediately after seeding. Performs 30 diagnostic tests auditing primary/foreign key integrity, checking for duplicate customer profiles, verifying email domains, validating formula calculations (`total_amount`, `line_total`), and detecting date anomalies before any analytical reporting.
   ```sql
   SOURCE data_quality_checks.sql;
   ```

3. **Phase 3: Domain-Specific Analytical Deep-Dives**
   * **Purpose**: Explores granular customer behavior, transaction telemetry, sales growth, retention cadences, and strategic accounts across five specialized analytical modules:
   ```sql
   -- Module 1: Customer Segmentation & Generational Demographics (10 sections)
   SOURCE customer_segmentation.sql;

   -- Module 2: Purchase Dynamics, Basket Size & Category Affinities (12 sections)
   SOURCE purchase_behavior.sql;

   -- Module 3: Sales Performance, Revenue Trends & Delivery SLAs (11 sections)
   SOURCE sales_analysis.sql;

   -- Module 4: Customer Retention, Cohort Matrix & Churn Risk (8 sections)
   SOURCE customer_retention.sql;

   -- Module 5: Strategic Business Reports & Customer 360 Profiles (9 sections)
   SOURCE business_insights.sql;
   ```

4. **Phase 4: Executive Business Summary & Master Scorecard (`final_business_summary.sql`)**
   * **Purpose**: The capstone executive synthesis. Consolidates findings across all business domains into 10 high-level KPI summaries and concludes with a single-screen Master Executive KPI Dashboard cross-joining all headline metrics for board-level reporting.
   ```sql
   SOURCE final_business_summary.sql;
   ```

*Alternatively, open any of the `.sql` files in MySQL Workbench, DBeaver, or VS Code SQLTools and execute individual queries section by section.*

---

## 9. Sample Business Questions Answered

| # | Business Question | Module | Key SQL Technique |
|---|---|---|---|
| **1** | *Who are our top 10 highest-spending customers and what share of company revenue do they generate?* | `business_insights.sql` | `CTE`, `DENSE_RANK()`, `SUM() OVER ()` |
| **2** | *What is our customer retention rate, and what percentage of buyers return for repeat purchases?* | `customer_retention.sql` | `CTE`, `SUM(CASE)`, `ROUND` |
| **3** | *How does Average Order Value (AOV) vary across customer loyalty tiers?* | `sales_analysis.sql` | `JOIN`, `GROUP BY`, `DENSE_RANK()` |
| **4** | *Which high-value customers have not purchased in over 90 days and require win-back action?* | `business_insights.sql` | `JOIN`, `DATEDIFF`, `CASE` |
| **5** | *What is the average time gap (in days) between a customer's 1st, 2nd, 3rd, and 4th orders?* | `customer_retention.sql` | `ROW_NUMBER()`, `LAG()`, `AVG()` |
| **6** | *Which product categories generate the highest gross revenue and profit margins?* | `final_business_summary.sql` | `JOIN`, `GROUP BY`, `DENSE_RANK()` |
| **7** | *How does Month-over-Month (MoM) revenue growth compare across operational months?* | `sales_analysis.sql` | `CTE`, `DATE_FORMAT()`, `LAG()` |
| **8** | *What are the most frequent cross-category product co-purchases in a single order?* | `purchase_behavior.sql` | `Self JOIN`, `COUNT(DISTINCT)` |
| **9** | *How does purchasing power and AOV break down across generational age brackets and gender?* | `customer_segmentation.sql` | `CASE`, `TIMESTAMPDIFF`, `GROUP BY` |
| **10** | *How do on-time delivery rates compare across carrier fulfillment SLAs?* | `sales_analysis.sql` | `CASE`, `SUM`, `ROUND` |

---

## 10. Key Project Outcomes & Findings

1. **Revenue Concentration (Pareto Principle)**:
   - The top **25% of customers** account for over **55% of total gross merchandise value (GMV)**.
   - The top 10 spenders generated **₹16,26,965.00 out of ₹18,81,872.00 total platform revenue (86.45%)**, led by Karan Malhotra (₹3,54,847.00) and Varun Kapoor (₹2,41,889.00).

2. **Customer Retention Health**:
   - Out of 29 converted buyers, **19 customers returned for repeat purchases**, yielding a **65.52% repeat buyer retention rate**.
   - Repeat buyers generate **98.4% of total company revenue**, with an average lifetime spend of **₹97,440.74** compared to ₹3,049.80 for one-time buyers (**31.95x higher**).

3. **Purchase Cadence & Habituation Dynamics**:
   - The average interval between Order 1 and Order 2 is **342.7 days**, but between Order 2 and Order 3 it contracts significantly to **152.4 days**, and between Order 3 and Order 4 it drops to **116.0 days**, illustrating that once a customer becomes a repeat purchaser, their re-order cycle accelerates.

4. **Category Revenue Dominance**:
   - **Electronics** represents the primary GMV driver (**₹12,20,871.00**, representing **68.35% of total catalog sales**), followed by **Home & Kitchen** (₹1,49,776.00 ~ 8.38%) and **Jewellery** (₹1,43,996.00 ~ 8.06%). Everyday consumables (**Grocery & Food**, **Beauty**) drive repeat frequency.

5. **Actionable Churn Mitigation**:
   - Identified 3 high-value accounts (Meera Iyer: ₹1.71L spend; Sneha Kulkarni: ₹90K spend; Deepak Kumar: ₹63K spend) entering moderate dormancy ($> 90$ days), enabling targeted win-back campaigns prior to complete churn.

---

## 11. Repository Organization

```
customer_analytics/
├── database/
│   ├── schema.sql                 # DDL: Table creation, constraints, foreign keys, indexes
│   └── sample_data.sql            # DML: Seed dataset with realistic e-commerce records
│
├── customer_segmentation.sql      # Module 1: RFM tiers, new/repeat/loyal cohorts, demographics & geo CLV
├── purchase_behavior.sql          # Module 2: AOV profiling, market basket self-joins, SKU velocity & gateways
├── sales_analysis.sql             # Module 3: Daily moving averages, MoM/YoY growth, category margins & SLA
├── customer_retention.sql         # Module 4: Retention rates, churn modeling, cadence & monthly cohort grid
├── business_insights.sql          # Module 5: VIP spenders, demand drivers, weekday trends & Customer 360
├── data_quality_checks.sql        # Module 6: 30 diagnostic tests auditing nulls, orphans, duplicates & math
├── final_business_summary.sql     # Module 7: 10 executive KPI modules & Master Executive Dashboard
│
├── FINAL_AUDIT_REPORT.md          # Comprehensive technical audit, data reconciliation & portfolio review
└── README.md                      # Project documentation & GitHub portfolio showcase
```

---

## 12. Project Audit & Quality Assurance

This repository includes a formal technical audit and code review documented in [`FINAL_AUDIT_REPORT.md`](FINAL_AUDIT_REPORT.md). The audit details:
- Complete file-by-file review across all SQL scripts.
- Analysis of SQL aggregation mechanics and pre-aggregated CTE patterns to prevent join fan-out.
- Financial reconciliation between order headers, line items, and payment transactions.
- Portfolio readiness evaluation and production best practices.

---

## 👤 Author & Portfolio Showcase

- **Project**: Customer Segmentation & Purchase Behavior Analytics Using SQL
- **Database Engine**: MySQL 8.0+
- **Domain**: E-Commerce & Retail Business Intelligence (BI)

*Designed and engineered for a clean, rigorous, and production-oriented SQL analytics portfolio.*
