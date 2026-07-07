# E-Commerce Data Cleaning & Analysis
A data cleaning and exploratory data analysis (EDA) project using Python and Pandas.

## Tools Used
- Python
- Pandas
- Matplotlib
- NumPy
- Jupyter Notebook

## Dataset
1,030 rows of intentionally messy e-commerce orders data with the following issues:
- Inconsistent text formatting (mixed casing)
- Missing values
- Duplicate rows
- Outliers in quantity and unit price

## What I Did

### Data Cleaning
- Fixed inconsistent values in `payment_method`, `order_status`, and `region` columns
- Standardized `email` and `customer_name` formatting
- Filled missing `unit_price` values using median price per product
- Filled missing `discount` values with 0 (no discount)
- Removed 30 duplicate rows
- Removed outliers in `quantity` (>5) and `unit_price` (>8500)
- Created `total_price` column: `quantity × unit_price × (1 - discount)`

### Analysis
- Which region has the most delivered orders?
- Which product category generates the most revenue?
- What is the most used payment method?
- What is the order status breakdown?

## Key Findings
- **Mindanao** has the most delivered orders (227)
- **Home & Living** generates the highest revenue
- Payment methods are evenly distributed across all 4 options
- **66%** of orders were successfully delivered

