# TheLook Ecommerce — SQL & Power BI Dashboard

A four-page Power BI dashboard and SQL analysis built on Google BigQuery's public `thelook_ecommerce` dataset (125K+ orders, 100K+ users), answering key business questions on revenue, profitability, fulfillment, and customer behavior.

[View on Google Drive](https://drive.google.com/drive/folders/1uaCvZnnfB8ZIu-9xPcC3c7-zOqqk12zW?usp=sharing)

---

## Project Overview

TheLook Ecommerce is a synthetic but realistic e-commerce dataset maintained by Google, covering orders, order line items, products, and users across a global customer base. This project explores the dataset in two stages:

1. **SQL exploration & business-question analysis** directly in BigQuery
2. **A four-page Power BI dashboard** (Overview, Sales & Product Performance, Customer & Demographics, Fulfillment & Returns) built on top of the same data, with a star-schema model and 48 DAX measures — 12 core KPIs plus 36 supporting year-over-year trend measures (reference labels on every KPI card)

---

## Source Data

Dataset: [`bigquery-public-data.thelook_ecommerce`](https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce)

Tables used:

| Table | Row Count | Role |
|---|---|---|
| `orders` | 125,665 | Order-level status, dates |
| `order_items` | 181,839 | Line-item revenue, links order ↔ product |
| `products` | 29,120 | Product catalog, cost, category |
| `users` | 100,000 | Customer demographics, acquisition channel |

Date range: 2019-01-06 to present — this is a **live dataset**, continuously updated by Google, not a static snapshot.

---

## Data Exploration & Cleaning (SQL)

Before modeling, the four core tables were profiled directly in BigQuery:

- **Row counts** confirmed above via `COUNT(*)` on each table.
- **Status values** — both `orders.status` and `order_items.status` use the same 5 values: `Complete`, `Processing`, `Shipped`, `Cancelled`, `Returned`. Nulls in `shipped_at`, `delivered_at`, and `returned_at` are expected (order hasn't reached that stage yet) — not a data quality issue.
- **Category values** — 26 distinct product categories, no cleanup needed.
- **Traffic sources** — 5 channels: `Search`, `Organic`, `Facebook`, `Email`, `Display`.
- **Duplicate check** — ran `GROUP BY id/order_id HAVING COUNT(*) > 1` on all four tables' primary keys. No duplicates found in `orders`, `order_items`, `products`, or `users`.
- **City nulls** — `city` is stored as the literal text `'null'` for a subset of users, concentrated in Brasil, US, South Korea, and Spain. Affects less than 1% of total users — not material, so analysis was kept at the country level instead of city level.

```sql
-- Example: confirming no duplicate order_items
SELECT id, COUNT(*)
FROM `bigquery-public-data.thelook_ecommerce.order_items`
GROUP BY id
HAVING COUNT(*) > 1;
```

---

## Business Questions (SQL Analysis)

Eight business questions were answered directly in SQL using JOINs, CTEs, window functions, and CASE WHEN logic.

| # | Question | Key Finding |
|---|---|---|
| 1 | Is revenue growing month over month? | Consistent growth from 2019 to present, accelerating noticeably from 2023 onward |
| 2 | Which products generate the most revenue? | Premium outdoor/fashion brands (The North Face, Canada Goose) dominate the top 10 |
| 3 | Which categories generate the most revenue? | Outerwear & Coats leads, followed by Jeans and Sweaters — top 3 all cold-weather categories |
| 4 | Which categories are most profitable after cost? | Blazers & Jackets has the highest margin (62%), followed by Accessories (~60%) and Suits & Sport Coats (~60%) — high revenue ≠ high margin (Outerwear & Coats is #1 in revenue but only 8th in margin) |
| 5 | What % of orders are cancelled or returned? | Cancelled ~15%, Returned ~10% — a combined ~25% of all orders |
| 6 | Which countries generate the most revenue? | China leads, followed by United States and Brasil; Asia-Pacific markets make up a large share |
| 7 | Which channel drives the most revenue? | Search dominates at $1.89M, far ahead of Organic ($415K), Facebook ($159K), Email ($131K), Display ($113K) |
| 8 | Which age group spends the most? | 59+ spends the most, closely followed by 18–28 — two distinct high-value segments (older affluent customers, young frequent shoppers) |

Full annotated queries with findings and recommendations are in `sql/business_questions.sql`.

---

## Data Model

Star schema with `orders` as the fact table hub, single-direction relationships flowing from dimension tables into the fact tables:

```
users (1) ──< orders (1) ──< order_items (*) >── (1) products
```

- `users[id]` → `orders[user_id]`
- `orders[order_id]` → `order_items[order_id]`
- `products[id]` → `order_items[product_id]`

![Data Model](images/data-modeling.png)

---

## DAX Measures

48 measures organized into 4 display folders under `_Measures`: **Sales**, **Fulfillment**, **Customers**, and **Trend** (year-over-year comparison measures powering the reference labels on every KPI card).

All rate-based measures (`Cancelled Rate %`, `Return Rate %`, `Profit Margin %`, `Repeat Purchase Rate`) return raw 0–1 decimals and use Power BI's built-in **Percentage** number format rather than a manual `* 100` — kept consistent across the model so no measure mixes both conventions.

Year filtering throughout the Trend folder uses Power BI's built-in date hierarchy (`orders[created_at].[Year]`) rather than a separate calculated Year column, since the report's Year slicer is already built on that same hierarchy.

### 📁 Sales
```dax
Total Revenue = SUM(order_items[sale_price])

Total Orders = DISTINCTCOUNT(orders[order_id])

Total Items Sold = COUNTROWS(order_items)

Avg Order Value = DIVIDE([Total Revenue], [Total Orders])

Profit Margin % = 
DIVIDE(
    [Total Revenue] - SUMX(order_items, RELATED(products[cost])),
    [Total Revenue]
)
```

### 📁 Fulfillment
```dax
Cancelled Rate % = DIVIDE(COUNTROWS(FILTER(orders, orders[status] = "Cancelled")), [Total Orders])

Return Rate % = DIVIDE(COUNTROWS(FILTER(orders, orders[status] = "Returned")), [Total Orders])

Delivered Orders = CALCULATE([Total Orders], NOT ISBLANK(orders[delivered_at]))

Avg Delivery Days = 
AVERAGEX(
    FILTER(orders, NOT ISBLANK(orders[delivered_at])),
    DATEDIFF(orders[created_at], orders[delivered_at], DAY)
)
```

### 📁 Customers
```dax
Total Customers = DISTINCTCOUNT(users[id])

Repeat Customers = 
COUNTROWS(
    FILTER(
        VALUES(orders[user_id]),
        CALCULATE(DISTINCTCOUNT(orders[order_id])) > 1
    )
)

Repeat Purchase Rate = DIVIDE([Repeat Customers], [Total Customers])
```

### 📁 Trend
Each KPI has three supporting measures: a **prior-year value**, a **label** (arrow + change, shown via each card's Reference label), and a **color** (drives conditional font color on that label — green when the metric moved in a good direction, red when it didn't). Count/currency-based KPIs show relative % change; rate-based KPIs (already a %) show the change in percentage points instead.

```dax
-- Total Revenue
Total Revenue PY = 
VAR CurrentYear = MAX(orders[created_at].[Year])
RETURN CALCULATE([Total Revenue], REMOVEFILTERS(orders[created_at].[Year]), orders[created_at].[Year] = CurrentYear - 1)

Revenue YoY Label = 
VAR Change = DIVIDE([Total Revenue] - [Total Revenue PY], [Total Revenue PY])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

Revenue YoY Color = IF([Total Revenue] >= [Total Revenue PY], "#2E7D32", "#C62828")


-- Total Orders
Total Orders PY = 
VAR CurrentYear = MAX(orders[created_at].[Year])
RETURN CALCULATE([Total Orders], REMOVEFILTERS(orders[created_at].[Year]), orders[created_at].[Year] = CurrentYear - 1)

Orders YoY Label = 
VAR Change = DIVIDE([Total Orders] - [Total Orders PY], [Total Orders PY])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

Orders YoY Color = IF([Total Orders] >= [Total Orders PY], "#2E7D32", "#C62828")


-- Avg Order Value
Avg Order Value PY = 
VAR CurrentYear = MAX(orders[created_at].[Year])
RETURN CALCULATE([Avg Order Value], REMOVEFILTERS(orders[created_at].[Year]), orders[created_at].[Year] = CurrentYear - 1)

AOV YoY Label = 
VAR Change = DIVIDE([Avg Order Value] - [Avg Order Value PY], [Avg Order Value PY])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

AOV YoY Color = IF([Avg Order Value] >= [Avg Order Value PY], "#2E7D32", "#C62828")


-- Total Items Sold
Total Items Sold PY = 
VAR CurrentYear = MAX(orders[created_at].[Year])
RETURN CALCULATE([Total Items Sold], REMOVEFILTERS(orders[created_at].[Year]), orders[created_at].[Year] = CurrentYear - 1)

Items Sold YoY Label = 
VAR Change = DIVIDE([Total Items Sold] - [Total Items Sold PY], [Total Items Sold PY])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

Items Sold YoY Color = IF([Total Items Sold] >= [Total Items Sold PY], "#2E7D32", "#C62828")


-- Profit Margin %
Profit Margin PY = 
VAR CurrentYear = MAX(orders[created_at].[Year])
RETURN CALCULATE([Profit Margin %], REMOVEFILTERS(orders[created_at].[Year]), orders[created_at].[Year] = CurrentYear - 1)

Margin YoY Label = 
VAR Change = [Profit Margin %] - [Profit Margin PY]
RETURN IF(Change >= 0, "▲ " & FORMAT(Change * 100, "0.0") & " pts", "▼ " & FORMAT(ABS(Change) * 100, "0.0") & " pts")

Margin YoY Color = IF([Profit Margin %] >= [Profit Margin PY], "#2E7D32", "#C62828")


-- Cancelled Rate %  (lower is better)
Cancelled Rate PY = 
VAR CurrentYear = MAX(orders[created_at].[Year])
RETURN CALCULATE([Cancelled Rate %], REMOVEFILTERS(orders[created_at].[Year]), orders[created_at].[Year] = CurrentYear - 1)

Cancelled YoY Label = 
VAR Change = [Cancelled Rate %] - [Cancelled Rate PY]
RETURN IF(Change <= 0, "▼ " & FORMAT(ABS(Change) * 100, "0.0") & " pts", "▲ " & FORMAT(Change * 100, "0.0") & " pts")

Cancelled YoY Color = IF([Cancelled Rate %] <= [Cancelled Rate PY], "#2E7D32", "#C62828")


-- Return Rate %  (lower is better)
Return Rate PY = 
VAR CurrentYear = MAX(orders[created_at].[Year])
RETURN CALCULATE([Return Rate %], REMOVEFILTERS(orders[created_at].[Year]), orders[created_at].[Year] = CurrentYear - 1)

Return YoY Label = 
VAR Change = [Return Rate %] - [Return Rate PY]
RETURN IF(Change <= 0, "▼ " & FORMAT(ABS(Change) * 100, "0.0") & " pts", "▲ " & FORMAT(Change * 100, "0.0") & " pts")

Return YoY Color = IF([Return Rate %] <= [Return Rate PY], "#2E7D32", "#C62828")


-- Delivered Orders
Delivered Orders PY = 
VAR CurrentYear = MAX(orders[created_at].[Year])
RETURN CALCULATE([Delivered Orders], REMOVEFILTERS(orders[created_at].[Year]), orders[created_at].[Year] = CurrentYear - 1)

Delivered YoY Label = 
VAR Change = DIVIDE([Delivered Orders] - [Delivered Orders PY], [Delivered Orders PY])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

Delivered YoY Color = IF([Delivered Orders] >= [Delivered Orders PY], "#2E7D32", "#C62828")


-- Avg Delivery Days  (lower is better)
Avg Delivery Days PY = 
VAR CurrentYear = MAX(orders[created_at].[Year])
RETURN CALCULATE([Avg Delivery Days], REMOVEFILTERS(orders[created_at].[Year]), orders[created_at].[Year] = CurrentYear - 1)

Delivery Days YoY Label = 
VAR Change = [Avg Delivery Days] - [Avg Delivery Days PY]
RETURN IF(Change <= 0, "▼ " & FORMAT(ABS(Change), "0.0") & " days", "▲ " & FORMAT(Change, "0.0") & " days")

Delivery Days YoY Color = IF([Avg Delivery Days] <= [Avg Delivery Days PY], "#2E7D32", "#C62828")


-- Total Customers
Total Customers PY = 
VAR CurrentYear = MAX(orders[created_at].[Year])
RETURN CALCULATE([Total Customers], REMOVEFILTERS(orders[created_at].[Year]), orders[created_at].[Year] = CurrentYear - 1)

Customers YoY Label = 
VAR Change = DIVIDE([Total Customers] - [Total Customers PY], [Total Customers PY])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

Customers YoY Color = IF([Total Customers] >= [Total Customers PY], "#2E7D32", "#C62828")


-- Repeat Customers
Repeat Customers PY = 
VAR CurrentYear = MAX(orders[created_at].[Year])
RETURN CALCULATE([Repeat Customers], REMOVEFILTERS(orders[created_at].[Year]), orders[created_at].[Year] = CurrentYear - 1)

Repeat Cust YoY Label = 
VAR Change = DIVIDE([Repeat Customers] - [Repeat Customers PY], [Repeat Customers PY])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

Repeat Cust YoY Color = IF([Repeat Customers] >= [Repeat Customers PY], "#2E7D32", "#C62828")


-- Repeat Purchase Rate
Repeat Purchase Rate PY = 
VAR CurrentYear = MAX(orders[created_at].[Year])
RETURN CALCULATE([Repeat Purchase Rate], REMOVEFILTERS(orders[created_at].[Year]), orders[created_at].[Year] = CurrentYear - 1)

Repeat Rate YoY Label = 
VAR Change = [Repeat Purchase Rate] - [Repeat Purchase Rate PY]
RETURN IF(Change >= 0, "▲ " & FORMAT(Change * 100, "0.0") & " pts", "▼ " & FORMAT(ABS(Change) * 100, "0.0") & " pts")

Repeat Rate YoY Color = IF([Repeat Purchase Rate] >= [Repeat Purchase Rate PY], "#2E7D32", "#C62828")
```

**Applying a reference label to a card:** select the card → Format visual → Reference label → On → drag the `...YoY Label` measure into the field well → click the Fx next to the label's font color → Format by: Field value → select the matching `...YoY Color` measure. The "vs last year" caption text is added separately via the card's **Show blank as** field (with a leading space) rather than inside the DAX, so the label measures stay reusable as pure number + arrow.

---

## Report Pages

### 1. Overview
*Business performance across sales, fulfillment, and customers.*
- **KPIs:** Total Revenue, Total Orders, Profit Margin %, Cancelled Rate %, Return Rate % — each with a YoY reference label
- **Charts:** Monthly Revenue Trend (line), Revenue by Channel (bar), Revenue by Category (treemap)
- **Slicers:** Year, Gender

### 2. Sales & Product Performance
*Revenue performance and top-selling products and categories.*
- **KPIs:** Total Revenue, Total Orders, Total Items Sold, Average Order Value — each with a YoY reference label
- **Charts:** Monthly Revenue Trend (line), Revenue by Category (bar), Most Profitable Categories (treemap)
- **Slicers:** Year, Gender

### 3. Customer & Demographics
*Understand who's buying and where revenue is coming from.*
- **KPIs:** Total Customers, Total Revenue, Avg Order Value, Repeat Purchase Rate — each with a YoY reference label
- **Charts:** Top 5 Countries by Revenue (bar), Revenue by Age Group (bar), Revenue by Channel (bar), Revenue by Gender (donut)
- **Slicers:** Year, Gender

### 4. Fulfillment & Returns
*Order status, cancellations, and returns.*
- **KPIs:** Cancelled Rate %, Return Rate %, Total Orders, Avg Delivery Days — each with a YoY reference label
- **Charts:** Orders by Status (donut), Completed vs. Cancelled vs. Returned (bar)
- **Slicers:** Year, Gender

![Overview Page](images/overview.png)
![Sales Page](images/sales.png)
![Customer Page](images/customers.png)
![Fulfillment Page](images/fulfillment.png)

---

## Notable Issues Solved

| Issue | Cause | Fix |
|---|---|---|
| `Total Orders` slightly overstated cancellation/return rates | Originally written as `DISTINCTCOUNT(order_items[order_id])`, a different grain than `orders[status]`, which the rate measures filter on | Rewrote as `DISTINCTCOUNT(orders[order_id])` to match the grain of the status field |
| Year filtering needed a consistent field across 48 measures | No separate calculated Year column existed on `orders` — only the raw `created_at` datetime | Standardized every Trend measure and the report's Year slicer on Power BI's built-in date hierarchy (`orders[created_at].[Year]`) instead of mixing a manual column with the hierarchy |
| `city = 'null'` values in `users` | Stored as literal text `'null'` rather than a true null, for <1% of users concentrated in a few countries | Kept analysis at country level instead of city level — not material enough to warrant a Power Query fix |
| Reference labels showed "0.0 pts" even when the color correctly flipped red/green | Rate measures (`Cancelled Rate %`, `Return Rate %`, `Profit Margin %`, `Repeat Purchase Rate`) were changed from a baked-in `* 100` to raw 0–1 decimals with Percentage formatting, but their `...YoY Label` measures still formatted the raw point-difference at one decimal place, rounding tiny decimal swings to zero | Multiplied the point difference by 100 inside each affected label's `FORMAT()` call, so the label scales correctly independent of how the base measure is formatted |
| Reference label text showed "vs last year vs last year" duplicated | The card's "Show blank as" field and the DAX label measure both independently included the caption text | Removed the caption from the DAX (label measures now return only the arrow + number) and kept it solely in the card's Show blank as field |
| Card text re-centered instead of staying left-aligned after enabling Reference label | The Reference label section has its own independent Alignment property, defaulting to Center rather than inheriting the card's existing layout | Manually set Alignment to Left on the Callout value, Category label, and Reference label sections individually |
| Format Painter left KPI cards visually "matching" but different sizes | Format Painter copies font/color/border styling but not visual Height/Width | Matched exact pixel Height/Width across cards manually via Format visual → General → Properties → Size, rather than relying on Format Painter or drag-resizing |

---

## Tools Used

- **Google BigQuery** — SQL exploration and business-question analysis
- **Power BI Desktop** — data modeling, DAX, dashboard design
- **Power Query** — data type fixes, load configuration
