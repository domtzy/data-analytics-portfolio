# Sales Data Analysis — Excel & Power Query

A data cleaning and analysis project using a raw retail sales export (500+ orders across 12 products, 5 regions, and 3 sales channels). Built entirely in Excel with Power Query for ETL and PivotTables for analysis.

## Objective

Clean a messy, real-world-style sales dataset and answer key business questions: which products/categories drive revenue, how channels and regions compare, and how order status (Completed/Refunded/Cancelled/Pending) affects reported revenue.

## Tools

- **Power Query** — data cleaning, transformation, deduplication, table merging
- **Excel Formulas** — calculated columns (`product_revenue`, `year_month`)
- **PivotTables** — revenue and order analysis by month, product, region, and channel
- **Conditional Formatting** — visual flagging of order status

## Data Cleaning Steps

The raw export had several intentional data quality issues, handled as follows:

| Issue | Fix |
|---|---|
| 3 fully blank rows | Removed |
| 12 duplicate order records | Removed via Power Query dedup on `order_id` |
| Inconsistent date formats (mixed `YYYY-MM-DD` / `MM/DD/YYYY`) | Standardized during load |
| Inconsistent text casing/whitespace in `product_name`, `category` | Trimmed and standardized |
| 31 missing `unit_price` values | Filled via a lookup table built from each product's known price, merged back on `product_name` |

Result: 500 clean, deduplicated rows with zero missing values.

## Key Calculated Fields

- **`unit_price_final`** — coalesced price (original price, or looked-up price where missing)
- **`product_revenue`** — `quantity × unit_price_final × (1 − discount_pct)`
- **`year_month`** — extracted from `order_date` for monthly trend analysis

Revenue reporting is filtered to `order_status = "Completed"` throughout, since Refunded, Cancelled, and Pending orders don't represent realized revenue. Rows are kept (not deleted) and flagged with conditional formatting so the full order history stays visible.

## Key Findings

- **Furniture drives the business.** Despite being 1 of 4 categories, Furniture accounts for **~68% of total revenue** ($20,860 of $30,671) — far ahead of Electronics, Lifestyle, and Stationery combined.
- **Partner and In-Store channels outperform Online.** Partner ($11,979) and In-Store ($10,911) both generate meaningfully more revenue than the Online channel ($7,781), suggesting an opportunity to investigate what's limiting online conversion.
- **East leads in revenue, Central leads in order volume, South is the most consistent performer** across both — no single region dominates both metrics.
- **Monthly revenue is stable**, ranging $3,600–$5,800 across 7 months with no strong upward or downward trend; May was a mild peak.
- **Total completed revenue: $30,671.49** across 270 completed orders (Average Order Value ≈ $113.60).

## Files

- `sales_data_raw.xlsx` — original uncleaned export
- Cleaned workbook with `sales_data_raw`, `price_lookup`, `sales_data-cleaned`, and `pivot` sheets

## Notes

This project was built as a hands-on exercise in real-world data cleaning — the raw file intentionally includes the kinds of issues (blanks, dupes, mixed formats, missing values) that show up in actual exports, rather than a pre-cleaned dataset.