# NimbusPay Transaction Analysis

## Overview
NimbusPay is a B2B payments/services company (payment processing, payroll, invoicing,
fraud protection, and related services for other businesses). This project cleans a
year of raw transaction exports, builds a reliable analysis-ready dataset, and
surfaces key revenue and risk insights through PivotTables and a summary dashboard.

## Business questions
- How is revenue trending by region and quarter, and how does it compare to target?
- How much revenue is tied up in failed, pending, or refunded transactions?
- Which customer segments and services drive the most revenue?
- Who are the top customers, and who owns those relationships?

## Tools used
Excel (Power Query, PivotTables/PivotCharts, XLOOKUP, IF, IFERROR, COUNTIFS, slicers)

## Data
Four raw exports (`Transactions_RAW`, `Customers`, `Services`, `Quarterly_Targets`),
~2,650 transactions across 2024, joined against a 130-row customer table and an
8-row service catalog.

## Data quality issues found and how they were handled
| Issue | Decision |
|---|---|
| Dates in 4+ inconsistent text formats | Standardized to a proper date type in Power Query |
| `Status` values with typos, mixed casing, stray spaces | Cleaned to 4 fixed categories: Completed, Failed, Pending, Refunded |
| `Amount` stored as mixed text (`$1,200.50`) and numbers | Converted to a single numeric type |
| Blank `PaymentMethod` | Labeled `"Unknown"` rather than removed — the transaction itself is still valid |
| Blank `CustomerID` / `ServiceID` | Kept, not deleted — the revenue is real even when it can't be attributed to a customer or service. Appears as "Unattributed" in pivots. |
| Transactions referencing a `CustomerID` not in the Customers table | Kept via a left-outer merge; unmatched rows return blank/`"Unassigned"` via `IFERROR` rather than breaking formulas |
| ~40 exact duplicate rows | Removed |
| Inconsistent country labels (`US`/`USA`/`United States`) | Standardized to a single value |
| Missing `SignupDate` / `AccountManager` on a couple of customer records | Customer kept; missing manager labeled `"Unassigned"` |

**Guiding principle:** never delete a row just because one field is missing. A
transaction with an unknown payment method or an unmatched customer is still real
revenue — the gap gets labeled, not hidden.

## Key insights
- Revenue is concentrated in Payment Processing, with meaningful volume also in
  Invoicing and Analytics.
- A measurable share of revenue sits in Failed/Pending/Refunded status — visible
  directly in the stacked revenue-by-service chart, useful for flagging at-risk
  revenue to leadership.
- SMB is the largest segment by revenue, ahead of Enterprise and Startup.
- A small but non-trivial slice of revenue (~$2K in service-level, ~$12K in
  segment-level analysis) can't be attributed due to missing customer/service
  references in the source data — worth raising with the systems team generating
  these exports.

