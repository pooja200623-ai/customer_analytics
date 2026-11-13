# Comprehensive Project Audit & Technical Evaluation Report

**Project**: Customer Segmentation & Purchase Behavior Analytics (SQL-Only)  
**Target Engine**: MySQL 8.0+  
**Audit Date**: November 13, 2026  
**Auditor**: Senior Data Engineering & SQL Specialist (Antigravity Analytics Review)  
**Audit Scope**: Every SQL file across the repository and `README.md`  
**Overall Readiness Verdict**: **Conditionally Portfolio-Ready (Near-Ready with High Potential — Requires Critical Fixes Before Public Showcasing)**

---

## Executive Summary

An exhaustive technical, architectural, and data-integrity audit of the **Customer Segmentation & Purchase Behavior Analytics** repository was conducted. The project demonstrates substantial domain knowledge in e-commerce business intelligence, featuring advanced SQL patterns including Common Table Expressions (CTEs), statistical window functions (`NTILE`, `PERCENT_RANK`, `DENSE_RANK`, `ROW_NUMBER`, `LAG`), cohort retention matrices, and churn prevention modeling.

However, the audit identified **one critical SQL join fan-out bug** that artificially doubles customer expenditure, **data integrity synchronization gaps** between `orders` and `order_items` in the seed data, **discrepancies between documented README findings and true database query results**, and **architectural duality** between legacy `sql_scripts/` files and root modules. Addressing these specific issues will elevate this repository into an exemplary, tier-one portfolio project.

---

## 1. Inventory of All Files Reviewed

The repository contains **15 files in total** (14 SQL scripts and 1 Markdown documentation file), organized across three directories:

| # | File Path | Lines | File Size | Primary Purpose & Contents |
|---|---|---|---|---|
| 1 | `README.md` | 313 | 18,470 B | Central project documentation, architecture diagram, methodology, and portfolio showcase. |
| 2 | `database/schema.sql` | 351 | 16,294 B | DDL schema defining 6 relational tables (`categories`, `customers`, `products`, `orders`, `order_items`, `payments`) with PKs, FKs, CHECK constraints, and 18 indexes. |
| 3 | `database/sample_data.sql` | 574 | 55,649 B | DML seed script populating 10 categories, 55 products, 30 customers, 60 orders, 110 order items, and 65 payment records. |
| 4 | `customer_segmentation.sql` | 477 | 20,514 B | **Module 1 (Root)**: 8 analytical queries covering purchase history, new vs. returning vs. loyal cohorts, HVCs, LVCs, inactive accounts, and master RFM segmentation. |
| 5 | `purchase_behavior.sql` | 472 | 20,721 B | **Module 2 (Root)**: 9 analytical queries analyzing basket depth, SKU frequency, power buyers, revenue concentration, AOV tiers, category affinities, seasonality, and churn risk. |
| 6 | `sales_analysis.sql` | 507 | 22,097 B | **Module 3 (Root)**: 10 analytical queries covering gross/net financial audits, daily moving averages, MoM/YoY growth, category margins, top SKUs, and QoQ variances. |
| 7 | `customer_retention.sql` | 446 | 20,180 B | **Module 4 (Root)**: 8 analytical queries tracking repeat vs. one-time buyers, macro retention rates, sequential order intervals, churn thresholds, monthly cohort grids, and reactivations. |
| 8 | `business_insights.sql` | 443 | 20,652 B | **Module 5 (Root)**: 8 executive reporting queries: Top 10 spenders, best-selling SKUs, category GMV, loyalty tier evaluation, day-of-week demand, VIP churn alerts, and C-level KPI scorecard. |
| 9 | `data_quality_checks.sql` | 1,457 | 61,159 B | **Data Quality Module (Root)**: 30 diagnostic validation queries auditing duplicates, NULLs, email formats, duplicate transactions, orphan records, financial reconciliations, and date logic. |
| 10 | `final_business_summary.sql` | 1,340 | 57,923 B | **Executive Summary Module (Root)**: 32 structured KPI queries across 10 business modules culminating in a consolidated single-screen Master Executive KPI Dashboard. |
| 11 | `sql_scripts/01_customer_segmentation.sql` | 218 | 9,422 B | **Legacy Module 1**: 4 business queries focusing on RFM quartiles, Pareto revenue contribution, demographic cohorts, and geographic market penetration. |
| 12 | `sql_scripts/02_purchase_behavior_analysis.sql` | 169 | 7,647 B | **Legacy Module 2**: 4 business queries analyzing re-order intervals, market basket co-purchases (self-join), basket size brackets, and payment gateway success rates. |
| 13 | `sql_scripts/03_sales_analysis.sql` | 163 | 7,308 B | **Legacy Module 3**: 4 business queries evaluating monthly MoM sales, category gross margins, top revenue SKUs, and delivery SLA on-time fulfillment rates. |
| 14 | `sql_scripts/04_customer_retention.sql` | 177 | 7,690 B | **Legacy Module 4**: 4 business queries tracking monthly acquisition cohort matrices, churn severity tiers, one-time vs. repeat buyer ARPU, and reactivation intervals. |
| 15 | `sql_scripts/05_business_reports.sql` | 186 | 8,351 B | **Legacy Module 5**: 3 business queries generating an Executive KPI scorecard, a Quarterly Business Review (QBR) matrix, and a Customer 360 profile. |

---

## 2. SQL Syntax & Logic Issues Found

### 2.1 Critical Logic Bugs

#### Bug 1: 1-to-N Join Fan-Out Cartesian Multiplication (Spend Doubled)
* **Location**: `purchase_behavior.sql`, Section 1 (lines 48–67)
* **Query**: Business Question 1 ("Customer Purchasing History Deep-Dive")
* **Code Snippet**:
  ```sql
  SELECT 
      c.customer_id,
      CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
      ...
      COUNT(DISTINCT o.order_id) AS total_orders,
      COALESCE(SUM(oi.quantity), 0) AS total_items_purchased,
      COALESCE(SUM(o.total_amount), 0.00) AS total_spend_numeric,
      CONCAT('₹', FORMAT(COALESCE(SUM(o.total_amount), 0.00), 2)) AS total_spend_formatted,
      CONCAT('₹', FORMAT(COALESCE(AVG(o.total_amount), 0.00), 2)) AS average_order_value,
      ...
  FROM customers c
  LEFT JOIN orders o ON c.customer_id = o.customer_id
  LEFT JOIN order_items oi ON o.order_id = oi.order_id
  GROUP BY c.customer_id, ...
  ORDER BY total_spend_numeric DESC;
  ```
* **Mechanism & Impact**:
  - In a relational schema, an order contains 1 to $N$ items (`orders` 1:N `order_items`). In this dataset, 48 out of 60 orders have multiple line items.
  - When `orders` is joined to `order_items`, the order row is replicated for each line item.
  - Executing `SUM(o.total_amount)` sums the order total once for every item in that order.
  - **Verified Impact**: For Customer 1 (Aarav Sharma), who placed 4 orders across 8 items, his actual spend is **₹1,96,565.00**. This query returns **₹3,93,130.00** (exactly $2\times$ overstatement).
  - Platform-wide GMV sums to **₹35,33,368.00** instead of the actual **₹18,81,872.00** (+87.8% artificial inflation).
  - `AVG(o.total_amount)` is also distorted because the denominator becomes total order items rather than total distinct orders.

#### Bug 2: `NTILE` Ranking Over Unhandled NULLs Distorts RFM Recency
* **Location**: `sql_scripts/01_customer_segmentation.sql`, lines 46–53
* **Query**: Business Question 1 ("RFM Segmentation")
* **Code Snippet**:
  ```sql
  WITH customer_rfm_raw AS (
      SELECT 
          c.customer_id,
          ...
          DATEDIFF('2026-11-10', MAX(o.order_date)) AS days_since_last_order
      FROM customers c
      LEFT JOIN orders o ON c.customer_id = o.customer_id 
                        AND o.status = 'Delivered'
      GROUP BY c.customer_id, ...
  ),
  customer_rfm_scores AS (
      SELECT 
          ...
          NTILE(4) OVER (ORDER BY days_since_last_order DESC) AS r_score
      FROM customer_rfm_raw
  )
  ```
* **Mechanism & Impact**:
  - Customer 21 (Saurav Ghosh) has 0 delivered orders. Consequently, `MAX(o.order_date)` is `NULL`, resulting in `days_since_last_order = NULL`.
  - In MySQL ANSI standards, `ORDER BY column DESC` places `NULL` values **at the very end (last)**.
  - In `NTILE(4) OVER (ORDER BY days_since_last_order DESC)`, the top bucket (NTILE = 1) receives the highest days (least recent), and the bottom bucket (NTILE = 4) receives the lowest days (most recent).
  - Because `NULL` sorts last, Saurav Ghosh is placed into quartile 4 (`r_score = 4`), assigning him the **highest possible recency rating (top 25% most active)** despite having never made a single purchase.
  - *Note*: The root script `customer_segmentation.sql` mitigated this by wrapping with `COALESCE(DATEDIFF(...), 9999)`, but `sql_scripts/01_customer_segmentation.sql` remains unpatched.

---

### 2.2 Seed Data Reconciliation & Data Integrity Issues

#### Bug 3: `orders.subtotal` Mismatches `SUM(order_items.line_total)` in 55 of 60 Orders
* **Location**: `database/sample_data.sql` (lines 145–280 vs. lines 285–470)
* **Mechanism & Impact**:
  - In `sample_data.sql`, `orders.subtotal` was populated with only the unit price of the **first product** listed in that order. When secondary products were appended to `order_items` for that same `order_id`, the parent `orders.subtotal` and `orders.total_amount` were not recalculated.
  - For example, in Order 1:
    - Line item 1: Samsung Galaxy S23 Ultra (Unit Price: ₹1,09,999.00, Line Total: ₹1,04,999.00)
    - Line item 2: Apple AirPods Pro (Unit Price: ₹24,999.00, Line Total: ₹24,999.00)
    - Sum of line totals: ₹1,29,998.00
    - Value stored in `orders.subtotal`: **₹1,09,999.00** (AirPods Pro omitted).
  - **Macro Discrepancy**:
    - Sum of `orders.subtotal`: **₹16,68,614.00**
    - Sum of `order_items.line_total`: **₹17,86,260.00** (Discrepancy: -₹1,17,646.00)
    - Sum of `order_items` gross (`quantity * unit_price`): **₹18,63,060.00**
  - Consequently, queries analyzing revenue from `orders` (e.g. `sales_analysis.sql` Section 1) report ₹18.82L GMV, while queries analyzing line items (e.g. `sales_analysis.sql` Section 7) report ₹17.86L GMV.

#### Bug 4: Order Items Calculated Line Total vs. Discount Formula Discrepancy
* **Location**: `database/sample_data.sql` (lines 285–470)
* **Mechanism & Impact**:
  - File header states: `line_total = ROUND(quantity * unit_price * (1 - discount_pct/100), 2)`.
  - In reality, **42 of 110 rows in `order_items`** deviate from this formula by up to ₹5.00.
  - For Item 1: `quantity=1`, `unit_price=109999.00`, `discount_pct=4.55`. The mathematical result is $109999 \times (1 - 0.0455) = 104994.045 \approx 104994.05$. However, `line_total` is hardcoded as `104999.00`.
  - While small in isolation, this causes diagnostic query `6b` in `data_quality_checks.sql` to flag 42 violations instead of the expected 0 rows.

#### Bug 5: Overpayment Recording & Duplicate Refund Entries in Payments
* **Location**: `database/sample_data.sql` (lines 475–570)
* **Mechanism & Impact**:
  - Orders 8, 15, 29, and 49 have payments that exceed the order's `total_amount`. The initial payment was already logged for the full order amount, and subsequent EMI instalment records (payments 61, 62, 63, 65) were added on top without reducing the initial payment.
    - Example: Order 8 (`total_amount = ₹1,45,319.00`) has Payment 8 for ₹1,45,319.00 PLUS Payment 61 for ₹12,109.92 = ₹1,57,428.92 total recorded.
  - Order 24 (a returned order of ₹2,222.00) has two duplicate refund payment records: Payment 24 (COD refund ₹2,222.00) and Payment 64 (Credit Card refund ₹2,222.00), resulting in ₹4,444.00 recorded refunded for a ₹2,222.00 order.
  - Query `6d` in `data_quality_checks.sql` detects and flags these 5 orders.

#### Bug 6: Inconsistent Product Count Header in `sample_data.sql`
* **Location**: `database/sample_data.sql`, lines 7 and 43
* **Mechanism & Impact**:
  - The comment block on line 7 asserts: `-- • 50 Products (5 per category)`.
  - Line 43 asserts: `-- 2. PRODUCTS (50 rows — 5 per category)`.
  - However, the script actually inserts **55 products** (Electronics has 10 products: IDs 1–10; categories 2–10 have 5 each: IDs 11–55).
  - The `README.md` correctly states 55 products, but the internal comment within `sample_data.sql` is contradictory.

---

### 2.3 Medium & Methodological Nuances

#### Bug 7: 7-Row vs. 7-Calendar-Day Moving Average in `sales_analysis.sql`
* **Location**: `sales_analysis.sql`, Section 2 (lines 81–85)
* **Query**: Business Question 2 ("Daily Sales Trends")
* **Code Snippet**:
  ```sql
  CONCAT('₹', FORMAT(AVG(daily_revenue) OVER (
      ORDER BY sales_date 
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ), 2)) AS rolling_7day_avg_revenue
  ```
* **Issue**:
  - The window specification uses physical rows: `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW`.
  - Because orders were not placed on consecutive calendar days (there are 51 distinct order days across 23 months), 6 preceding rows represent an average across 6 irregular transaction dates (often spanning 2 to 4 weeks), rather than a genuine 7-calendar-day rolling average.
  - In MySQL 8.0+, this should be formulated as `RANGE BETWEEN INTERVAL 6 DAY PRECEDING AND CURRENT ROW` over a date-spine series.

#### Bug 8: Missing Summary Row in `final_business_summary.sql` Section 9d
* **Location**: `final_business_summary.sql`, Section 9d (lines 1045–1085)
* **Issue**:
  - The query comment states: `-- Expected Output: Per-customer average inter-order gap in days. Summary row at end shows platform-wide average gap across all repeat buyers.`
  - The actual SQL query contains only `GROUP BY ig.customer_id, c.first_name, c.last_name, c.segment` and does not include a `UNION ALL` or `WITH ROLLUP` clause. As a result, no platform-wide summary row is returned.

#### Bug 9: Temporal Reference Inconsistency (`'2026-11-10'` vs. `CURDATE()`)
* **Location**: Multiple files
* **Issue**:
  - In `customer_segmentation.sql`, `purchase_behavior.sql`, `customer_retention.sql`, and `business_insights.sql`, the date `'2026-11-10'` is hardcoded as the anchor for recency and churn calculations (e.g., `DATEDIFF('2026-11-10', MAX(o.order_date))`).
  - In contrast, `data_quality_checks.sql` and `final_business_summary.sql` use dynamic system functions `CURDATE()` and `NOW()`.
  - When `data_quality_checks.sql` is run, `WHERE o.order_date > NOW()` dynamically evaluates against the server's local clock. If run prior to November 2026, valid seed orders from late 2026 are flagged as "future-dated orders".

---

## 3. Missing or Incomplete Project Requirements

### 3.1 Unresolved Repository Duality & Redundant Scripts
- **The Issue**: There are two parallel implementations of the analytics modules:
  1. The `sql_scripts/` directory containing files `01_customer_segmentation.sql` through `05_business_reports.sql` (commit `a5c93e2`).
  2. The root-level files `customer_segmentation.sql` through `business_insights.sql` (commits `4d52d99` to `e038ffe`).
- **Impact**: The root scripts are an expanded, 8-to-10 question rewrite of the 3-to-4 question scripts in `sql_scripts/`. Having both directories in the root without explanation creates confusion for hiring managers and recruiters inspecting the repository.

### 3.2 Undocumented Modules in `README.md`
- **The Issue**: Two of the most sophisticated scripts in the repository—`data_quality_checks.sql` (1,457 lines, 30 validation checks) and `final_business_summary.sql` (1,340 lines, 32 executive queries)—are **completely omitted from `README.md`**.
- **Impact**: Commits `722d6db` and `8ec69cd` added these files after `README.md` was authored. Neither the Table of Contents, Project Modules, Execution Instructions, nor the Repository File Tree in `README.md` mention them. Anyone browsing the GitHub landing page will not know these files exist.

### 3.3 Discrepancies Between `README.md` Findings and Database Truth
Several statistics highlighted in `README.md` Section 10 contradict the actual query outputs:

| Claimed Finding in `README.md` Section 10 | Actual SQL Query Result from Seed Data | Root Cause of Discrepancy |
|---|---|---|
| **Top 10 Spenders GMV**: ₹15,28,499.00 out of ₹18,81,872.00 (81.22%) | **₹16,26,965.00** out of ₹18,81,872.00 (**86.45%**) | README omitted Customer 19 (Deepak Kumar: ₹63,164.00) from the top 10 sum. |
| **Repeat Buyer Value Multiplier**: Repeat buyers have spend that is **5.4x higher** than one-time buyers | **31.95x higher** (Repeat Avg: ₹97,440.74 vs. One-Time Avg: ₹3,049.80) | The 5.4x figure was an unverified estimation in documentation. |
| **Purchase Interval Cadence**: Order 1 $\rightarrow$ 2 is **~238 days**; Order 3 $\rightarrow$ 4 drops to **~80 days** | Order 1 $\rightarrow$ 2 is **342.7 days**; Order 3 $\rightarrow$ 4 is **116.0 days** | The documented figures did not reflect the true date intervals in `sample_data.sql`. |

### 3.4 Missing Views / DDL Materialization Layer
- The schema includes a `segment` ENUM column in `customers` with the comment: `-- Segment label — updated by analytics jobs / triggers`.
- However, all segmentation logic across the project is implemented as standalone `SELECT` queries. The repository lacks stored procedures, update statements, or database views (`CREATE VIEW view_customer_rfm_segments AS ...`) that write the calculated tiers back to `customers.segment` or provide reusable reporting views for downstream BI tools (Power BI, Tableau).

---

## 4. Portfolio Readiness Assessment

### Overall Verdict: **Conditionally Portfolio-Ready (Score: 78/100)**

```
┌─────────────────────────────────────────────────────────────┐
│  Portfolio Readiness Scorecard                              │
├────────────────────────────────┬──────────┬─────────────────┤
│ Evaluation Dimension           │ Score    │ Status          │
├────────────────────────────────┼──────────┼─────────────────┤
│ SQL Complexity & Technique     │  96/100  │ Exceptional     │
│ Relational Schema Design (3NF) │  94/100  │ Excellent       │
│ Business Relevance & Analytics │  92/100  │ High Commercial │
│ Code Formatting & Cleanliness  │  95/100  │ Production-tier │
│ Documentation Completeness     │  65/100  │ Needs Updating  │
│ Data Integrity & Cross-Module  │  60/100  │ Needs Patching  │
│ Repository Cleanliness         │  68/100  │ Needs Cleanup   │
├────────────────────────────────┼──────────┼─────────────────┤
│ Weighted Overall Score         │  78/100  │ Near-Ready      │
└────────────────────────────────┴──────────┴─────────────────┘
```

### Why it Impresses:
1. **Industry-Grade Analytical Depth**: The analytical queries simulate real-world e-commerce KPIs: RFM segmentation, customer lifetime value (CLV/LTV), cohort retention grids, SLA compliance, and cross-category affinity matrices.
2. **Mastery of Advanced SQL**: The project avoids basic tutorials and makes extensive use of window functions (`NTILE(4)`, `PERCENT_RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `LAG()`, running sums with `OVER()`), complex multi-level CTEs, and defensive conditional grouping.
3. **Data Quality Module**: `data_quality_checks.sql` is a standout asset rarely seen in entry-to-mid-level SQL portfolios. It demonstrates data engineering maturity and awareness of ETL validation.

### Why it Should Not Be Shared With Hiring Managers Without Fixes:
1. If a senior data engineer or interviewer runs Query 1 in `purchase_behavior.sql`, they will immediately spot the join fan-out bug doubling customer spend and question the candidate's understanding of SQL aggregation mechanics.
2. The mismatch between the README findings and actual database output suggests the documentation was written from assumptions rather than verified query runs.
3. The existence of competing duplicate files in `sql_scripts/` makes the repository appear unorganized or midway through a migration.

---

## 5. Specific Corrections Needed

### 5.1 Fix for Join Fan-Out in `purchase_behavior.sql` (Section 1)

#### Current Erroneous Query:
```sql
-- purchase_behavior.sql lines 50-52
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, ...
```

#### Corrected Production Query:
Aggregate `order_items` in a pre-aggregated CTE or join an order-level summary to prevent duplicating order totals:

```sql
WITH customer_order_metrics AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders,
        COALESCE(SUM(total_amount), 0.00) AS total_spend,
        COALESCE(AVG(total_amount), 0.00) AS avg_order_value,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS most_recent_order_date,
        COALESCE(DATEDIFF(MAX(order_date), MIN(order_date)), 0) AS active_purchasing_span_days
    FROM orders
    GROUP BY customer_id
),
customer_item_metrics AS (
    SELECT 
        o.customer_id,
        COALESCE(SUM(oi.quantity), 0) AS total_items_purchased
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    c.city,
    c.state,
    c.registration_date,
    COALESCE(com.total_orders, 0) AS total_orders,
    COALESCE(cim.total_items_purchased, 0) AS total_items_purchased,
    COALESCE(com.total_spend, 0.00) AS total_spend_numeric,
    CONCAT('₹', FORMAT(COALESCE(com.total_spend, 0.00), 2)) AS total_spend_formatted,
    CONCAT('₹', FORMAT(COALESCE(com.avg_order_value, 0.00), 2)) AS average_order_value,
    com.first_order_date,
    com.most_recent_order_date,
    COALESCE(com.active_purchasing_span_days, 0) AS active_purchasing_span_days
FROM customers c
LEFT JOIN customer_order_metrics com ON c.customer_id = com.customer_id
LEFT JOIN customer_item_metrics  cim ON c.customer_id = cim.customer_id
ORDER BY total_spend_numeric DESC;
```

---

### 5.2 Fix for `NTILE` NULL Recency in `sql_scripts/01_customer_segmentation.sql`

#### Current Erroneous Expression:
```sql
DATEDIFF('2026-11-10', MAX(o.order_date)) AS days_since_last_order
...
NTILE(4) OVER (ORDER BY days_since_last_order DESC) AS r_score
```

#### Corrected Expression:
Use `COALESCE` with a high sentinel value (e.g. 9999 days) so non-purchasers sort at the top of the `DESC` ordering, ensuring they receive the lowest recency score (`r_score = 1`):

```sql
COALESCE(DATEDIFF('2026-11-10', MAX(o.order_date)), 9999) AS days_since_last_order
```

---

### 5.3 Fix for `sample_data.sql` Financial Reconciliations

1. **Recalculate `orders.subtotal`**: Update each order's `subtotal` to equal the sum of its associated `order_items.line_total` (or gross line values), and derive `total_amount = subtotal - discount_amount + tax_amount + shipping_charge`.
2. **Harmonize EMI Payments**:
   - For orders with split instalments (Orders 8, 15, 29, 49), adjust the initial payment record to represent Instalment 1 (so that Instalment 1 + Instalment 2 = `total_amount`).
   - For Order 24, remove the duplicate Credit Card refund (Payment 64) and retain only the COD refund (Payment 24).
3. **Correct Comment Header**: Change line 7 in `sample_data.sql` to read:
   `-- • 55 Products (10 in Electronics, 5 each in 9 other categories)`.

---

### 5.4 Repository Cleanup & Consolidation Strategy

To eliminate redundancy and present a clean repository structure:

1. **Option A (Recommended: Clean Consolidation)**:
   - Deprecate or delete the legacy `sql_scripts/` directory, as all five modules have been expanded and superseded by the root-level SQL files.
2. **Option B (Alternative: Structured Directory Organization)**:
   - If subdirectories are preferred, move the root SQL modules into `sql_scripts/` (replacing the older files) and update `README.md` to reference the organized folder:
     ```
     customer_analytics/
     ├── database/
     │   ├── schema.sql
     │   └── sample_data.sql
     ├── sql_scripts/
     │   ├── 01_customer_segmentation.sql
     │   ├── 02_purchase_behavior.sql
     │   ├── 03_sales_analysis.sql
     │   ├── 04_customer_retention.sql
     │   ├── 05_business_insights.sql
     │   ├── 06_data_quality_checks.sql
     │   └── 07_final_business_summary.sql
     ├── README.md
     └── FINAL_AUDIT_REPORT.md
     ```

---

### 5.5 Updates Needed in `README.md`

1. **Add Missing Modules**: Add `data_quality_checks.sql` and `final_business_summary.sql` to Section 5 ("Project Modules") and Section 8 ("How to Execute the SQL Files").
2. **Correct Finding Statistics in Section 10**:
   - Update Top 10 customer revenue: Change `₹15,28,499.00 (81.22%)` to **`₹16,26,965.00 (86.45%)`**.
   - Update Repeat vs. One-Time ratio: Change `5.4x higher` to **`31.95x higher`** (or clarify that repeat buyers generate **98.4% of total GMV**).
   - Update Re-order intervals: Change `~238 days` to **`342.7 days`** (Order 1 $\rightarrow$ 2) and `~80 days` to **`116.0 days`** (Order 3 $\rightarrow$ 4).
3. **Update Repository File Tree**: Reflect all active files in the project root.

---

## 6. Audit Conclusion & Sign-Off

The **Customer Segmentation & Purchase Behavior Analytics** project contains outstanding, high-caliber SQL analytics that demonstrate advanced SQL proficiency. The database design is robust, normalized, and well-indexed.

Once the **cartesian join fan-out in `purchase_behavior.sql`** is corrected, the **seed data financial totals are harmonized**, and **`README.md` is updated to accurately report query outcomes and document the newer modules**, this project will stand out as an **exceptional, production-grade portfolio showcase** for Data Analyst, Analytics Engineer, and Business Intelligence Engineer roles.

---
*Report generated and saved to project root as `FINAL_AUDIT_REPORT.md`.*
