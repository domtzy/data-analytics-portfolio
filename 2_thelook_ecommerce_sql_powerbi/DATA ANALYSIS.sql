-- THELOOK ECOMMERCE | DATA ANALYSIS

-- BUSINESS QUESTION 1: Monthly Revenue Trend
-- is the business growing month over month?
SELECT ROUND(SUM(sale_price),2) as revenue,
      FORMAT_TIMESTAMP('%Y-%m', created_at) AS year_month
FROM `bigquery-public-data.thelook_ecommerce.order_items`
WHERE status = 'Complete'
GROUP BY year_month
ORDER BY year_month;
-- FINDING: Revenue shows consistent growth from early 2019 to present
-- the business has grown significantly over 7 years
-- growth accelerates noticeably from 2023 onwards
-- RECOMMENDATION: continue investing in marketing and inventory to sustain growth momentum
------------------------------------------------------------

-- BUSINESS QUESTION 2: Top 10 Products by Revenue
-- which products generate the most revenue?
SELECT p.name,
      ROUND(SUM(oi.sale_price),2) as revenue,
FROM `bigquery-public-data.thelook_ecommerce.products` AS p
JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  ON p.id = oi.product_id
WHERE status = 'Complete'
GROUP BY name
ORDER BY revenue DESC
LIMIT 10;
-- FINDING: Premium outdoor and fashion brands dominate top revenue
-- The North Face and Canada Goose appear multiple times in top 10
-- suggests customers are willing to spend on high-end brands
-- RECOMMENDATION: prioritize stock availability for premium brands
-- consider featuring these products prominently on the homepage
---------------------------------------------------------------

-- BUSINESS QUESTION 3: Revenue by Product Category
-- which clothing categories generate the most revenue?
SELECT p.category,
      ROUND(SUM(oi.sale_price),2) as revenue,
FROM `bigquery-public-data.thelook_ecommerce.products` AS p
JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  ON p.id = oi.product_id
WHERE status = 'Complete'
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;
-- FINDING: Outerwear & Coats leads revenue followed by Jeans and Sweaters
-- top 3 categories are all cold weather clothing
-- suggests the customer base skews towards colder climate regions
-- RECOMMENDATION: increase inventory investment in Outerwear, Jeans and Sweaters
-- consider seasonal promotions for these categories during winter months
-------------------------------------------------------------------

-- BUSINESS QUESTION 4: Profit Margin by Category
-- which categories are the most profitable after costs?
WITH profit_cte AS (
SELECT p.category,
      ROUND(SUM(oi.sale_price),2 )AS revenue,
      ROUND(SUM(p.cost),2 ) AS cost,
      ROUND(SUM(oi.sale_price) - SUM(p.cost),2 ) AS profit
FROM `bigquery-public-data.thelook_ecommerce.products` AS p
JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi
 ON p.id = oi.product_id
WHERE status = 'Complete'
GROUP BY p.category
)

SELECT *,
      ROUND(profit / revenue * 100, 2) AS profit_margin
FROM profit_cte
ORDER BY profit_margin DESC;
-- FINDING: Blazers & Jackets has the highest profit margin at 62%
-- followed by Accessories (59.92%) and Suits & Sport Coats (59.87%)
-- Outerwear & Coats leads in total revenue but ranks 8th in profit margin
-- high revenue does not always mean high profitability
-- RECOMMENDATION: prioritize Blazers & Jackets and Accessories in marketing
-- these categories generate the most profit per dollar of revenue
---------------------------------------------------------------

-- BUSINESS QUESTION 5: Order Status Breakdown
-- what percentage of orders are cancelled or returned?
SELECT status,
      ROUND(COUNT(order_id) * 100.0 / SUM(COUNT(order_id)) OVER(), 2)  AS percentage
FROM `bigquery-public-data.thelook_ecommerce.orders`  
GROUP BY status
ORDER BY percentage DESC;
-- FINDING: Shipped (30%) and Complete (25%) make up the majority of orders
-- Cancelled orders account for ~15% of all orders -- significant loss of potential revenue
-- Returned orders account for ~10% -- worth investigating return reasons
-- combined cancellation and return rate is ~25% of all orders
-- RECOMMENDATION: investigate reasons for high cancellation rate
-- consider improving product descriptions to reduce return rates
-----------------------------------------------------------------

-- BUSINESS QUESTION 6: Top 10 Countries by Revenue
-- which countries generate the most revenue?
SELECT u.country,
      ROUND(SUM(oi.sale_price), 2) AS revenue
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi
 ON u.id = oi.user_id
WHERE status = 'Complete'
GROUP BY country
ORDER BY revenue DESC
LIMIT 10;
-- FINDING: China is the top revenue generating country
-- followed by United States and Brasil
-- Asia Pacific markets (China, South Korea, Japan, Australia) make up significant portion
-- RECOMMENDATION: prioritize marketing spend and localization in China and US
-- consider expanding presence in South Korea and Brasil as emerging high value markets
-------------------------------------------------------------------------

-- BUSINESS QUESTION 7: Revenue by Traffic Source
-- which marketing channel brings in the most revenue?
SELECT u.traffic_source,
      ROUND(SUM(oi.sale_price), 2) AS revenue
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi
 ON u.id = oi.user_id
WHERE status = 'Complete'
GROUP BY traffic_source
ORDER BY revenue DESC;
-- FINDING: Search is the dominant traffic source generating $1.89M in revenue
-- far ahead of Organic ($415k), Facebook ($159k), Email ($131k) and Display ($113k)
-- Search alone accounts for majority of total revenue
-- RECOMMENDATION: continue investing in Search/SEO as the primary acquisition channel
-- Email and Display are underperforming -- review campaigns for these channels
-- consider increasing Facebook ad spend as it outperforms Email and Display
-------------------------------------------------------------------

-- BUSINESS QUESTION 8: Customer Age Group Analysis
-- which age group spends the most?
SELECT 
      CASE
       WHEN age BETWEEN 0 AND 17 THEN  '0-17'
       WHEN age BETWEEN 18 AND 28 THEN '18-28'
       WHEN age BETWEEN 29 AND 38 THEN '29-38'
       WHEN age BETWEEN 39 AND 48 THEN '39-48'
       WHEN age BETWEEN 49 AND 58 THEN '49-58'
       WHEN age >= 59 THEN '59+'
      END AS age_group,
      ROUND(SUM(oi.sale_price), 2) AS revenue

FROM `bigquery-public-data.thelook_ecommerce.users` AS u
JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi
 ON u.id = oi.user_id
WHERE status = 'Complete'
GROUP BY age_group
ORDER BY revenue DESC;
-- FINDING: 59+ is the highest spending age group followed closely by 18-28
-- suggests two distinct high value customer segments: older wealthy customers and young fashion enthusiasts
-- 0-17 group exists due to synthetic data generation -- not a real concern
-- middle age groups (29-48) spend relatively evenly
-- RECOMMENDATION: tailor marketing campaigns for 59+ with premium product focus
-- target 18-28 with trendy and social media driven campaigns
-- consider loyalty programs for the 59+ segment to retain high value customers
---------------------------------------------------------------------



 















