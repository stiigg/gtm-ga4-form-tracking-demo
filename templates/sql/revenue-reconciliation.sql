/**
 * Revenue Reconciliation Query
 * Compares GA4 purchase revenue with source system (Shopify/WooCommerce)
 * Use this to identify tracking gaps and validate implementation accuracy
 */

-- GA4 Revenue by Date
WITH ga4_revenue AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS date,
    SUM(ecommerce.purchase_revenue) AS ga4_revenue,
    COUNT(DISTINCT ecommerce.transaction_id) AS ga4_transactions,
    COUNT(*) AS ga4_purchase_events,
    -- Detect potential duplicates
    COUNT(*) - COUNT(DISTINCT ecommerce.transaction_id) AS duplicate_events
  FROM `YOUR_PROJECT.analytics_XXXXX.events_*`
  WHERE event_name = 'purchase'
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
                          AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY date
),

-- Shopify/WooCommerce Order Data
-- Replace with your actual order table
source_orders AS (
  SELECT
    DATE(created_at) AS date,
    SUM(total_price) AS source_revenue,
    COUNT(DISTINCT order_id) AS source_orders
  FROM `YOUR_PROJECT.shopify_dataset.orders`
  WHERE created_at BETWEEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
                       AND CURRENT_TIMESTAMP()
    AND financial_status IN ('paid', 'partially_paid')
    AND fulfillment_status != 'cancelled'
  GROUP BY date
)

-- Compare GA4 vs Source
SELECT
  COALESCE(g.date, s.date) AS date,
  
  -- GA4 Metrics
  IFNULL(g.ga4_revenue, 0) AS ga4_revenue,
  IFNULL(g.ga4_transactions, 0) AS ga4_transactions,
  IFNULL(g.duplicate_events, 0) AS potential_duplicates,
  
  -- Source System Metrics
  IFNULL(s.source_revenue, 0) AS source_revenue,
  IFNULL(s.source_orders, 0) AS source_orders,
  
  -- Variance Analysis
  ROUND(IFNULL(g.ga4_revenue, 0) - IFNULL(s.source_revenue, 0), 2) AS revenue_variance,
  ROUND(SAFE_DIVIDE(IFNULL(g.ga4_revenue, 0), IFNULL(s.source_revenue, 0)) * 100, 2) AS tracking_accuracy_pct,
  
  -- Transaction Count Variance
  IFNULL(g.ga4_transactions, 0) - IFNULL(s.source_orders, 0) AS transaction_variance,
  
  -- Data Quality Flags
  CASE
    WHEN IFNULL(g.ga4_revenue, 0) = 0 AND IFNULL(s.source_revenue, 0) > 0 THEN '🚨 GA4 not tracking'
    WHEN IFNULL(g.duplicate_events, 0) > 0 THEN '⚠️ Possible duplicates'
    WHEN ABS(IFNULL(g.ga4_revenue, 0) - IFNULL(s.source_revenue, 0)) > (IFNULL(s.source_revenue, 0) * 0.05) THEN '⚠️ >5% variance'
    ELSE '✅ Within tolerance'
  END AS data_quality_status

FROM ga4_revenue g
FULL OUTER JOIN source_orders s USING(date)
ORDER BY date DESC;
