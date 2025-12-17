-- GA4 BigQuery Export Analysis Queries
-- Replace PROJECT_ID and DATASET with your values

-- 1. Revenue Reconciliation (GA4 vs Shopify/WooCommerce)
-- Identifies discrepancies > 5% requiring investigation
WITH ga4_revenue AS (
  SELECT
    DATE(TIMESTAMP_MICROS(event_timestamp)) AS date,
    event_name,
    ecommerce.transaction_id,
    ecommerce.purchase_revenue AS ga4_revenue
  FROM `PROJECT_ID.DATASET.events_*`
  WHERE event_name = 'purchase'
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
                          AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
),
shopify_revenue AS (
  SELECT
    DATE(created_at) AS date,
    order_number AS transaction_id,
    total_price AS shopify_revenue
  FROM `PROJECT_ID.shopify_export.orders`
  WHERE created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
)
SELECT
  g.date,
  g.transaction_id,
  g.ga4_revenue,
  s.shopify_revenue,
  ABS(g.ga4_revenue - s.shopify_revenue) AS variance,
  ROUND(ABS(g.ga4_revenue - s.shopify_revenue) / s.shopify_revenue * 100, 2) AS variance_pct
FROM ga4_revenue g
FULL OUTER JOIN shopify_revenue s
  ON g.transaction_id = s.transaction_id
WHERE ABS(g.ga4_revenue - s.shopify_revenue) / NULLIF(s.shopify_revenue, 0) > 0.05
ORDER BY variance_pct DESC;

-- 2. Product Performance Analysis
-- Top products by revenue, conversion rate, cart abandonment
SELECT
  items.item_id,
  items.item_name,
  items.item_category,
  COUNTIF(event_name = 'view_item') AS product_views,
  COUNTIF(event_name = 'add_to_cart') AS adds_to_cart,
  COUNTIF(event_name = 'purchase') AS purchases,
  SUM(IF(event_name = 'purchase', items.price * items.quantity, 0)) AS revenue,
  ROUND(COUNTIF(event_name = 'add_to_cart') / NULLIF(COUNTIF(event_name = 'view_item'), 0) * 100, 2) AS view_to_cart_rate,
  ROUND(COUNTIF(event_name = 'purchase') / NULLIF(COUNTIF(event_name = 'add_to_cart'), 0) * 100, 2) AS cart_to_purchase_rate
FROM `PROJECT_ID.DATASET.events_*`,
  UNNEST(items) AS items
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
                        AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name IN ('view_item', 'add_to_cart', 'purchase')
GROUP BY items.item_id, items.item_name, items.item_category
ORDER BY revenue DESC
LIMIT 50;

-- 3. Conversion Funnel Analysis
-- Identifies drop-off rates at each checkout stage
WITH funnel_events AS (
  SELECT
    user_pseudo_id,
    COUNTIF(event_name = 'view_item') > 0 AS viewed,
    COUNTIF(event_name = 'add_to_cart') > 0 AS added_cart,
    COUNTIF(event_name = 'begin_checkout') > 0 AS began_checkout,
    COUNTIF(event_name = 'add_payment_info') > 0 AS added_payment,
    COUNTIF(event_name = 'purchase') > 0 AS purchased
  FROM `PROJECT_ID.DATASET.events_*`
  WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY user_pseudo_id
)
SELECT
  'Step 1: Product Viewed' AS funnel_step,
  COUNT(*) AS users,
  100.0 AS conversion_rate
FROM funnel_events
WHERE viewed = TRUE

UNION ALL

SELECT
  'Step 2: Added to Cart',
  COUNT(*),
  ROUND(COUNT(*) / (SELECT COUNT(*) FROM funnel_events WHERE viewed = TRUE) * 100, 2)
FROM funnel_events
WHERE added_cart = TRUE

UNION ALL

SELECT
  'Step 3: Began Checkout',
  COUNT(*),
  ROUND(COUNT(*) / (SELECT COUNT(*) FROM funnel_events WHERE viewed = TRUE) * 100, 2)
FROM funnel_events
WHERE began_checkout = TRUE

UNION ALL

SELECT
  'Step 4: Added Payment Info',
  COUNT(*),
  ROUND(COUNT(*) / (SELECT COUNT(*) FROM funnel_events WHERE viewed = TRUE) * 100, 2)
FROM funnel_events
WHERE added_payment = TRUE

UNION ALL

SELECT
  'Step 5: Completed Purchase',
  COUNT(*),
  ROUND(COUNT(*) / (SELECT COUNT(*) FROM funnel_events WHERE viewed = TRUE) * 100, 2)
FROM funnel_events
WHERE purchased = TRUE;

-- 4. Cart Abandonment Segmentation
-- Users who added to cart but didn't purchase, segmented by traffic source
SELECT
  traffic_source.source,
  traffic_source.medium,
  COUNT(DISTINCT user_pseudo_id) AS abandoned_carts,
  SUM(ecommerce.value) AS abandoned_value,
  ROUND(AVG(ecommerce.value), 2) AS avg_cart_value
FROM `PROJECT_ID.DATASET.events_*`
WHERE event_name = 'add_to_cart'
  AND _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND user_pseudo_id NOT IN (
    SELECT DISTINCT user_pseudo_id
    FROM `PROJECT_ID.DATASET.events_*`
    WHERE event_name = 'purchase'
      AND _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  )
GROUP BY traffic_source.source, traffic_source.medium
ORDER BY abandoned_value DESC;

-- 5. Customer Lifetime Value (Simple 90-day)
-- Total revenue per user over 90 days
SELECT
  user_pseudo_id,
  COUNT(DISTINCT ecommerce.transaction_id) AS num_purchases,
  SUM(ecommerce.purchase_revenue) AS lifetime_value,
  ROUND(AVG(ecommerce.purchase_revenue), 2) AS avg_order_value,
  DATE_DIFF(MAX(DATE(TIMESTAMP_MICROS(event_timestamp))), 
            MIN(DATE(TIMESTAMP_MICROS(event_timestamp))), DAY) AS customer_lifespan_days
FROM `PROJECT_ID.DATASET.events_*`
WHERE event_name = 'purchase'
  AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
                        AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
GROUP BY user_pseudo_id
HAVING lifetime_value > 0
ORDER BY lifetime_value DESC
LIMIT 100;
