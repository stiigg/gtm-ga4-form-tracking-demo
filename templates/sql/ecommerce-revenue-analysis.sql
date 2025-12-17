/**
 * E-COMMERCE REVENUE - PRODUCT PERFORMANCE ANALYSIS
 * 
 * Purpose: Analyze revenue contribution by product
 * Data source: items array in purchase events
 * 
 * Project: demo-tracking-project (179616959118)
 * Property: G-9P3KQ2WZM7
 * 
 * Metrics calculated:
 * - Total revenue per product (in USD)
 * - Units sold
 * - Average price
 * - Revenue percentage contribution
 * - Number of unique purchasers
 * 
 * Note: Uses UNNEST to flatten items array
 * Each purchase event can have multiple items
 * 
 * Cost: ~15-30MB for 30 days (FREE)
 */

SELECT
  item.item_id,
  item.item_name,
  item.item_category,
  COUNT(DISTINCT user_pseudo_id) as unique_purchasers,
  SUM(item.quantity) as total_quantity_sold,
  ROUND(SUM(item.item_revenue_in_usd), 2) as total_revenue_usd,
  ROUND(AVG(item.price_in_usd), 2) as avg_price_usd,
  ROUND(SUM(item.item_revenue_in_usd) * 100.0 / SUM(SUM(item.item_revenue_in_usd)) OVER(), 2) as revenue_percentage
FROM `demo-tracking-project.analytics_398765432.events_*`,
  UNNEST(items) as item
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name = 'purchase'
GROUP BY item.item_id, item.item_name, item.item_category
ORDER BY total_revenue_usd DESC;

/**
 * EXPECTED OUTPUT (based on demo products):
 * 
 * item_id | item_name         | item_category | unique_purchasers | total_quantity_sold | total_revenue_usd | avg_price_usd | revenue_percentage
 * --------|-------------------|---------------|-------------------|---------------------|-------------------|---------------|-------------------
 * SKU002  | Tag Manager Plus  | software      | 45                | 48                  | 7,152.00          | 149.00        | 51.7%
 * SKU001  | Analytics Pro     | software      | 38                | 42                  | 4,158.00          | 99.00         | 30.1%
 * SKU003  | Data Studio Kit   | software      | 32                | 35                  | 2,515.00          | 79.00         | 18.2%
 * 
 * INSIGHTS TO LOOK FOR:
 * 1. Which product generates most revenue? (not always the most sold)
 * 2. Are high-priced items converting? (avg_price vs quantity)
 * 3. Revenue concentration: Is 80% from 20% of products? (Pareto principle)
 * 4. Repeat purchases: total_quantity_sold vs unique_purchasers ratio
 */