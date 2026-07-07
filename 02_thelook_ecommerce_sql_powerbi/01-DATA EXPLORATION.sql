-- THELOOK ECOMMERCE | DATA EXPLORATION

-- first look at 4 tables we need
SELECT * FROM `bigquery-public-data.thelook_ecommerce.orders` LIMIT 100;
SELECT * FROM `bigquery-public-data.thelook_ecommerce.order_items` LIMIT 100;
SELECT * FROM `bigquery-public-data.thelook_ecommerce.products` LIMIT 100;
SELECT * FROM `bigquery-public-data.thelook_ecommerce.users` LIMIT 100;

-- ROW COUNTS
-- orders: 125,665 | order_items: 181,839
-- products: 29,120 | users: 100,000
SELECT COUNT(*) FROM `bigquery-public-data.thelook_ecommerce.orders`;
SELECT COUNT(*) FROM `bigquery-public-data.thelook_ecommerce.order_items`;
SELECT COUNT(*) FROM `bigquery-public-data.thelook_ecommerce.products`;
SELECT COUNT(*) FROM `bigquery-public-data.thelook_ecommerce.users`;

-- checking status values in orders and order_items
-- both have 5 values: Complete, Processing, Shipped, Cancelled, Returned
-- nulls in shipped_at, delivered_at, returned_at are expected — not a data issue
SELECT DISTINCT(status) FROM `bigquery-public-data.thelook_ecommerce.orders`;
SELECT DISTINCT(status) FROM `bigquery-public-data.thelook_ecommerce.order_items`;

-- 26 product categories exist
SELECT DISTINCT(category) FROM `bigquery-public-data.thelook_ecommerce.products`;

-- customers come from multiple countries
SELECT DISTINCT(country) FROM `bigquery-public-data.thelook_ecommerce.users`;

-- 5 traffic sources: Facebook, Organic, Search, Email, Display
SELECT DISTINCT(traffic_source) FROM `bigquery-public-data.thelook_ecommerce.users`;

-- date range: 2019-01-06 to present (live dataset, continuously updated by Google)
SELECT MIN(created_at), MAX(created_at)
FROM `bigquery-public-data.thelook_ecommerce.orders`;

-- No Duplicates found in orders order_id
SELECT order_id,
      COUNT(*)
FROM `bigquery-public-data.thelook_ecommerce.orders`
GROUP BY order_id
HAVING COUNT(*) > 1;

-- No Duplicates found in order_items id
SELECT id,
      COUNT(*)
FROM `bigquery-public-data.thelook_ecommerce.order_items`
GROUP BY id
HAVING COUNT(*) > 1;

-- No Duplicates found in products id
SELECT id,
      COUNT(*)
FROM `bigquery-public-data.thelook_ecommerce.products`
GROUP BY id
HAVING COUNT(*) > 1;

-- No Duplicates found in users id
SELECT id,
      COUNT(*)
FROM `bigquery-public-data.thelook_ecommerce.users`
GROUP BY id
HAVING COUNT(*) > 1;

-- checking all city values to confirm null distribution
-- Shanghai, Beijing, Seoul are top cities showing healthy city data for most countries
-- city = 'null' (stored as text) affects multiple countries
SELECT city, COUNT(*) as count
FROM `bigquery-public-data.thelook_ecommerce.users`
GROUP BY city
ORDER BY count DESC;

-- checking countries affected by null values
-- Brasil has the most, followed by US, South Korea, Spain
-- less than 1% of total users affected — not critical for analysis
-- not critical for analysis, we will use country level for geographic insights
SELECT country,
      COUNT(*) as count
FROM `bigquery-public-data.thelook_ecommerce.users`
WHERE city = 'null' 
GROUP BY country
ORDER BY count DESC;




