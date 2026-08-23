# Olist E-Commerce Analytics Dashboard

A Power BI project built on the real Olist Brazilian e-commerce dataset — from nine raw CSVs to a working data model and a four-page interactive dashboard.

![Dashboard Overview](./images/overview.png)

📁 [Download the .pbix file](#) — 

## Project Overview

Olist, a Brazilian multi-category e-commerce marketplace.

**KPIs covered:** Revenue and order volume, delivery performance (on-time vs. late), review scores, seller performance, payment behavior, freight cost, repeat purchase rate.

**Known limitations of the dataset:**
- No "Returns" concept — Olist doesn't track product returns.
- No product cost/COGS — only revenue and freight can be calculated, not true profit.

## 1. Source Data

Nine CSVs, loaded individually via Get Data → Text/CSV, organized into Power Query folders (Facts / Dimensions):

| Table | Type | Grain |
|---|---|---|
| Orders | Fact | 1 row per order |
| OrderItems | Fact | 1 row per item/unit sold |
| OrderPayments | Fact | 1 row per payment installment |
| OrderReviews | Fact | 1 row per review |
| Customers | Dimension | 1 row per customer_id (per-order, not per-person) |
| Products | Dimension | 1 row per product_id |
| Sellers | Dimension | 1 row per seller |
| Geolocation | Dimension | Aggregated to 1 row per zip prefix |
| ProductCategory | Lookup | Portuguese → English category translation |

## 2. Data Cleaning

- **Orders:** null delivery dates left intentionally blank — they indicate the order was never delivered, which is signal, not dirty data.
- **Products:** ~610 rows had null category/description fields. Confirmed no duplicate `product_id`s via Group By, so nulls were unrecoverable. Replaced category nulls with `"unknown"`, numeric nulls with `0`. Rows kept, not deleted, since they're referenced in real sales.
- **Customers:** `customer_id` is unique per order, not per person — `customer_unique_id` is the true person-level key. Used for all repeat-purchase logic.
- **Geolocation:** original table had many rows per zip prefix. Grouped by zip, averaging lat/lng and taking Min for city/state, to prevent fan-out when related to Customers/Sellers.
- **OrderReviews:** duplicate `review_id`s found and removed.
- **OrderPayments:** verified no null/zero installment values.

## 3. Data Model

Star schema: 4 fact tables, 5 dimension tables, 1 Calendar table.

![Data Model Diagram](./images/data-modeling.png)

**Notable relationship decisions:**
- Customers → Geolocation kept active; Sellers → Geolocation set inactive (ambiguous path otherwise), activated via `USERELATIONSHIP()` when needed.
- OrderItems → Orders relationship set to bidirectional filtering, required for category-level filters to reach Orders and OrderReviews correctly.
- Calendar table: built by anchoring to a clean `DATEVALUE()` column in Orders (`order_purchase_timestamp` was a full datetime, which didn't match a date-only Calendar table on relationship). Marked as the official Date Table.

## 4. DAX Measures

25+ measures organized into three display folders (Sales, Logistics, Customer), plus a nested **MoM Comparisons** sub-folder under each for month-over-month trend indicators.

### Customer
```dax
Avg Review Score = AVERAGE(OrderReviews[review_score])

Total Reviews = COUNTROWS(OrderReviews)

Repeat Customers = 
CALCULATE(
    DISTINCTCOUNT(Customers[customer_unique_id]),
    FILTER(
        VALUES(Customers[customer_unique_id]),
        CALCULATE(DISTINCTCOUNT(Orders[order_id])) > 1
    )
)

Repeat Purchase Rate = 
DIVIDE([Repeat Customers], DISTINCTCOUNT(Customers[customer_unique_id]))
```

### Logistics
```dax
Total Freight Cost = SUM(OrderItems[freight_value])

Freight as % of Order Value = DIVIDE([Total Freight Cost], [Total Revenue])

Avg Delivery Days = AVERAGEX(
    FILTER(Orders, NOT(ISBLANK(Orders[order_delivered_customer_date]))),
    DATEDIFF(Orders[order_purchase_timestamp], Orders[order_delivered_customer_date], DAY)
)

On Time Orders = CALCULATE(
    COUNTROWS(Orders),
    Orders[order_delivered_customer_date] <= Orders[order_estimated_delivery_date]
)

Late Orders = CALCULATE(
    COUNTROWS(Orders),
    Orders[order_delivered_customer_date] > Orders[order_estimated_delivery_date]
)

On-Time Delivery Rate = DIVIDE(
    CALCULATE(COUNTROWS(Orders), Orders[order_delivered_customer_date] <= Orders[order_estimated_delivery_date]),
    CALCULATE(COUNTROWS(Orders), Orders[order_status] = "Delivered")
)

Late Delivery Rate = 1 - [On-Time Delivery Rate]

Delivered Orders = CALCULATE(
    COUNTROWS(Orders),
    Orders[order_status] = "Delivered"
)

Cancelled Orders = CALCULATE(COUNTROWS(Orders), Orders[order_status] = "Canceled")

Cancelled Rate = DIVIDE([Cancelled Orders], [Total Orders])

Max Gauge = [Total Orders] * 0.05

Target Cancelled = [Total Orders] * 0.02
```

### Sales
```dax
Total Revenue = SUM(OrderItems[price])

Total Orders = DISTINCTCOUNT(OrderItems[order_id])

Total Items Sold = COUNTROWS(OrderItems)

Avg Order Value = DIVIDE(_Measures[Total Revenue], _Measures[Total Orders])

Product Rank by Revenue = 
IF(
    ISINSCOPE(Products[product_id]),
    RANKX(ALL(Products[product_id]), [Total Revenue], , DESC),
    BLANK()
)

% of Total Revenue = 
DIVIDE(
    [Total Revenue],
    CALCULATE([Total Revenue], ALL(Products))
)
```

**Verified values:**
- Total Revenue: 13.59M
- Total Orders: 99K
- On-Time Delivery Rate: 95%
- Avg Review Score: 4.09

## 5. Trend Indicators (Month-over-Month)

Every headline KPI card carries a color-coded MoM trend label (▲ green / ▼ red), computed and colored entirely in DAX — no visual-level conditional formatting rules. Each indicator follows a consistent 3-measure pattern: a prior-month reference measure, a label measure (arrow + formatted % or pts), and a color measure (hex string bound via Field Value formatting).

**Pattern:** every KPI gets 3 measures — a prior-month reference, a label (arrow + formatted value), and a color (hex string via Field Value formatting).

### Sales 
```dax
Total Revenue PM = 
CALCULATE([Total Revenue], PREVIOUSMONTH('Calendar'[Date]))

Revenue MoM Label = 
VAR Change = DIVIDE([Total Revenue] - [Total Revenue PM], [Total Revenue PM])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

Revenue MoM Color = 
IF([Total Revenue] >= [Total Revenue PM], "#2E7D32", "#C62828")


Total Orders PM = 
CALCULATE([Total Orders], PREVIOUSMONTH('Calendar'[Date]))

Orders MoM Label = 
VAR Change = DIVIDE([Total Orders] - [Total Orders PM], [Total Orders PM])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

Orders MoM Color = 
IF([Total Orders] >= [Total Orders PM], "#2E7D32", "#C62828")


Avg Order Value PM = 
CALCULATE([Avg Order Value], PREVIOUSMONTH('Calendar'[Date]))

AOV MoM Label = 
VAR Change = DIVIDE([Avg Order Value] - [Avg Order Value PM], [Avg Order Value PM])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

AOV MoM Color = 
IF([Avg Order Value] >= [Avg Order Value PM], "#2E7D32", "#C62828")


Total Items Sold PM = 
CALCULATE([Total Items Sold], PREVIOUSMONTH('Calendar'[Date]))

Items Sold MoM Label = 
VAR Change = DIVIDE([Total Items Sold] - [Total Items Sold PM], [Total Items Sold PM])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

Items Sold MoM Color = 
IF([Total Items Sold] >= [Total Items Sold PM], "#2E7D32", "#C62828")
```

### Logistics
```dax
On-Time Delivery Rate PM = 
CALCULATE([On-Time Delivery Rate], PREVIOUSMONTH('Calendar'[Date]))

On-Time Delivery Rate MoM Label = 
VAR Change = [On-Time Delivery Rate] - [On-Time Delivery Rate PM]
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%") & " pts", "▼ " & FORMAT(ABS(Change), "0.0%") & " pts")

On-Time Delivery Rate MoM Color = 
IF([On-Time Delivery Rate] >= [On-Time Delivery Rate PM], "#2E7D32", "#C62828")


Late Delivery Rate PM = 
CALCULATE([Late Delivery Rate], PREVIOUSMONTH('Calendar'[Date]))

Late Delivery Rate MoM Label = 
VAR Change = [Late Delivery Rate] - [Late Delivery Rate PM]
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%") & " pts", "▼ " & FORMAT(ABS(Change), "0.0%") & " pts")

Late Delivery Rate MoM Color = 
IF([Late Delivery Rate] <= [Late Delivery Rate PM], "#2E7D32", "#C62828")


Avg Delivery Days PM = 
CALCULATE([Avg Delivery Days], PREVIOUSMONTH('Calendar'[Date]))

Delivery Days MoM Label = 
VAR Change = DIVIDE([Avg Delivery Days] - [Avg Delivery Days PM], [Avg Delivery Days PM])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

Delivery Days MoM Color = 
IF([Avg Delivery Days] <= [Avg Delivery Days PM], "#2E7D32", "#C62828")


Total Freight Cost PM = 
CALCULATE([Total Freight Cost], PREVIOUSMONTH('Calendar'[Date]))

Freight MoM Label = 
VAR Change = DIVIDE([Total Freight Cost] - [Total Freight Cost PM], [Total Freight Cost PM])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

Freight MoM Color = 
IF([Total Freight Cost] >= [Total Freight Cost PM], "#2E7D32", "#C62828")


Cancelled Rate PM = 
CALCULATE([Cancelled Rate], PREVIOUSMONTH('Calendar'[Date]))

Cancelled Rate MoM Label = 
VAR Change = [Cancelled Rate] - [Cancelled Rate PM]
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%") & " pts", "▼ " & FORMAT(ABS(Change), "0.0%") & " pts")

Cancelled Rate MoM Color = 
IF([Cancelled Rate] <= [Cancelled Rate PM], "#2E7D32", "#C62828")
```

### Customer
```dax
Avg Review Score PM = 
CALCULATE([Avg Review Score], PREVIOUSMONTH('Calendar'[Date]))

Review Score MoM Label = 
VAR Change = DIVIDE([Avg Review Score] - [Avg Review Score PM], [Avg Review Score PM])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

Review Score MoM Color = 
IF([Avg Review Score] >= [Avg Review Score PM], "#2E7D32", "#C62828")


Total Reviews PM = 
CALCULATE([Total Reviews], PREVIOUSMONTH('Calendar'[Date]))

Reviews MoM Label = 
VAR Change = DIVIDE([Total Reviews] - [Total Reviews PM], [Total Reviews PM])
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%"), "▼ " & FORMAT(ABS(Change), "0.0%"))

Reviews MoM Color = 
IF([Total Reviews] >= [Total Reviews PM], "#2E7D32", "#C62828")


Repeat Purchase Rate PM = 
CALCULATE([Repeat Purchase Rate], PREVIOUSMONTH('Calendar'[Date]))

Repeat Rate MoM Label = 
VAR Change = [Repeat Purchase Rate] - [Repeat Purchase Rate PM]
RETURN IF(Change >= 0, "▲ " & FORMAT(Change, "0.0%") & " pts", "▼ " & FORMAT(ABS(Change), "0.0%") & " pts")

Repeat Rate MoM Color = 
IF([Repeat Purchase Rate] >= [Repeat Purchase Rate PM], "#2E7D32", "#C62828")
```

Applied across all pages:

| KPI | Comparison basis | "Up" direction |
|---|---|---|
| Total Revenue | % change | Good (green) |
| Total Orders | % change | Good (green) |
| Avg Order Value | % change | Good (green) |
| Total Items Sold | % change | Good (green) |
| Avg Review Score | % change | Good (green) |
| Total Reviews | % change | Good (green) |
| Repeat Purchase Rate | Percentage-point diff | Good (green) |
| On-Time Delivery Rate | Percentage-point diff | Good (green) |
| Late Delivery Rate | Percentage-point diff | **Bad (red)** — flipped |
| Cancelled Rate | Percentage-point diff | **Bad (red)** — flipped |
| Total Freight Cost | % change | Good (green) |
| Avg Delivery Days | % change | **Bad (red) when up** — flipped |

Rate-based KPIs (On-Time, Late, Cancelled, Repeat Purchase) compare as raw **percentage-point difference** rather than a percentage-of-a-percentage, since "rate of a rate" change is misleading. Metrics where a higher number is operationally worse (Late Delivery Rate, Cancelled Rate, Avg Delivery Days) have their color logic inverted so red still means "this got worse," not just "the number went up."

**MoM design decision:** month-over-month was chosen over year-over-year because the dataset's real order volume only spans ~Jan 2017–Oct 2018, leaving too few full-year overlaps for a reliable YoY comparison. MoM gives every month a valid prior-month baseline across the full date range.

## 6. Report Pages

Four pages, built with a shared sidebar navigation.

### Business Overview
KPI cards with MoM trend indicators, revenue trend (drillable Year → Quarter → Month → Date), order status breakdown, top categories.

![Overview page](./images/overview.png)

### Sales Analysis
Revenue by category, drill-down product leaderboard ranked by revenue, monthly trend, KPI cards with MoM indicators.

![Sales page](./images/sales.png)

### Delivery Logistics
On-time vs. late delivery by state, freight cost as % of order value, cancelled orders gauge benchmarked against a dynamic target, KPI cards with MoM indicators.

![Logistics page](./images/logistics.png)

### Customer & Reviews
Review score distribution, average score by product category, KPI cards with MoM indicators.

![Customers page](./images/customers.png)

## 7. Notable Issues Solved

| Issue | Root Cause | Fix |
|---|---|---|
| Chart showing identical values across every category | Inactive/one-way relationship blocking filter propagation | Set OrderItems → Orders relationship to bidirectional |
| Calendar chart showing near-zero matches | Date-only Calendar column vs. full datetime Orders column | Added `DATEVALUE()` column, related on that instead |
| RANKX showing "1" for every row in a matrix | Measure grain mismatch after adding a category grouping level | Wrapped in `ISINSCOPE()` to only rank at product-level |
| Donut chart order count didn't match KPI card | Field pulled from OrderItems (fewer rows) instead of Orders | Switched Value field to `Orders[order_id]` |
| Line chart collapsed to a single dot when filtered to one month | X-axis field matched the slicer's field (Month), leaving one category to plot | Rebuilt axis on `Calendar[Date]` (or full hierarchy) instead of `MonthName` |
| Line chart showed weekday buckets ("June Friday", "June Monday"...) instead of chronological days | Hierarchy's bottom level was `DayName` (text field) instead of `Date` | Swapped hierarchy's last level to `Calendar[Date]` |
| Revenue trend zigzagged wildly when Month filter was applied with Year set to "All" | Chart was plotting the same month across multiple unrelated years as one continuous line | Removed "All" as a default; scoped Year slicer to valid years only |
| Line chart showed a horizontal scrollbar at wide date ranges | Continuous axis type unavailable while a multi-level date hierarchy was on the X-axis | Dropped hierarchy in favor of a single `Calendar[Date]` field, enabling Continuous axis mode |

## 8. Open Items / Next Steps

- One-day revenue spike around March 4, 2017 (~12,658.51) — flagged for further investigation.
- Deprioritized for a future iteration: year-over-year comparisons (once more overlapping years exist in scope), dynamic KPI selector, Power Apps/Automate integration.

## 9. Tools Used

Power BI Desktop — Power Query, DAX, Data Modeling, Report Design.