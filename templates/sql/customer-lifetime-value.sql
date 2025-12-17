/**
 * Customer Lifetime Value (CLV) Analysis
 * Calculates per-user revenue, purchase frequency, and lifespan
 * Use for customer segmentation and retention strategies
 */

WITH user_purchases AS (
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_purchase_date,
    MAX(PARSE_DATE('%Y%m%d', event_date)) AS last_purchase_date,
    DATE_DIFF(
      MAX(PARSE_DATE('%Y%m%d', event_date)), 
      MIN(PARSE_DATE('%Y%m%d', event_date)), 
      DAY
    ) AS customer_lifespan_days,
    COUNT(DISTINCT ecommerce.transaction_id) AS total_purchases,
    SUM(ecommerce.purchase_revenue) AS lifetime_value,
    AVG(ecommerce.purchase_revenue) AS avg_order_value,
    
    -- Calculate purchase frequency (purchases per month active)
    SAFE_DIVIDE(
      COUNT(DISTINCT ecommerce.transaction_id),
      DATE_DIFF(
        MAX(PARSE_DATE('%Y%m%d', event_date)), 
        MIN(PARSE_DATE('%Y%m%d', event_date)), 
        DAY
      ) / 30.0
    ) AS purchases_per_month,
    
    -- Days since last purchase (recency)
    DATE_DIFF(CURRENT_DATE(), MAX(PARSE_DATE('%Y%m%d', event_date)), DAY) AS days_since_last_purchase
    
  FROM `YOUR_PROJECT.analytics_XXXXX.events_*`
  WHERE event_name = 'purchase'
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY))
                          AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
    AND user_pseudo_id IS NOT NULL
  GROUP BY user_pseudo_id
)

SELECT
  user_pseudo_id,
  first_purchase_date,
  last_purchase_date,
  customer_lifespan_days,
  total_purchases,
  
  ROUND(lifetime_value, 2) AS lifetime_value,
  ROUND(avg_order_value, 2) AS avg_order_value,
  ROUND(purchases_per_month, 2) AS purchases_per_month,
  days_since_last_purchase,
  
  -- Customer Segmentation (RFM-inspired)
  CASE
    WHEN total_purchases >= 5 AND days_since_last_purchase <= 30 THEN 'VIP - Active'
    WHEN total_purchases >= 5 AND days_since_last_purchase > 30 THEN 'VIP - At Risk'
    WHEN total_purchases BETWEEN 2 AND 4 AND days_since_last_purchase <= 60 THEN 'Regular - Active'
    WHEN total_purchases BETWEEN 2 AND 4 AND days_since_last_purchase > 60 THEN 'Regular - Lapsed'
    WHEN total_purchases = 1 AND days_since_last_purchase <= 90 THEN 'One-time - Recent'
    WHEN total_purchases = 1 AND days_since_last_purchase > 90 THEN 'One-time - Churned'
    ELSE 'Uncategorized'
  END AS customer_segment,
  
  -- Predicted next purchase date (simple linear extrapolation)
  DATE_ADD(
    last_purchase_date, 
    INTERVAL CAST(customer_lifespan_days / NULLIF(total_purchases - 1, 0) AS INT64) DAY
  ) AS predicted_next_purchase

FROM user_purchases
WHERE total_purchases >= 1 -- Include single-purchase customers for full view

ORDER BY lifetime_value DESC
LIMIT 1000;
