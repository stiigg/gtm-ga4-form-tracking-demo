-- Revenue Reconciliation: GA4 vs Source System
-- Purpose: Validate server-side implementation accuracy
-- Expected variance: <2% is excellent, <5% is acceptable

WITH ga4_revenue AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS date,
    COUNT(DISTINCT ecommerce.transaction_id) AS ga4_transaction_count,
    SUM(ecommerce.purchase_revenue) AS ga4_revenue,
    SUM(ecommerce.tax_value) AS ga4_tax,
    SUM(ecommerce.shipping_value) AS ga4_shipping
  FROM `your-project.analytics_XXXXX.events_*`
  WHERE event_name = 'purchase'
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
                          AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY date
),

shopify_orders AS (
  -- Replace with your actual order system export
  -- This example assumes Shopify data in BigQuery
  SELECT
    DATE(created_at) AS date,
    COUNT(DISTINCT order_id) AS shopify_order_count,
    SUM(total_price) AS shopify_revenue,
    SUM(total_tax) AS shopify_tax,
    SUM(total_shipping) AS shopify_shipping
  FROM `your-project.shopify_export.orders`
  WHERE created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
    AND financial_status = 'paid' -- Only count completed orders
    AND cancelled_at IS NULL -- Exclude cancellations
  GROUP BY date
)

SELECT
  COALESCE(ga4.date, shopify.date) AS date,
  
  -- GA4 Metrics
  ga4.ga4_transaction_count,
  ga4.ga4_revenue,
  
  -- Source System Metrics
  shopify.shopify_order_count,
  shopify.shopify_revenue,
  
  -- Variance Calculations
  shopify.shopify_order_count - ga4.ga4_transaction_count AS transaction_diff,
  ROUND((ga4.ga4_transaction_count / shopify.shopify_order_count) * 100, 2) AS transaction_accuracy_pct,
  
  shopify.shopify_revenue - ga4.ga4_revenue AS revenue_diff,
  ROUND((ga4.ga4_revenue / shopify.shopify_revenue) * 100, 2) AS revenue_accuracy_pct,
  
  -- Quality Assessment
  CASE
    WHEN ABS(shopify.shopify_revenue - ga4.ga4_revenue) / shopify.shopify_revenue < 0.02 THEN '✅ Excellent (<2%)'
    WHEN ABS(shopify.shopify_revenue - ga4.ga4_revenue) / shopify.shopify_revenue < 0.05 THEN '✔️ Good (<5%)'
    WHEN ABS(shopify.shopify_revenue - ga4.ga4_revenue) / shopify.shopify_revenue < 0.10 THEN '⚠️ Investigate (5-10%)'
    ELSE '❌ Critical (>10%)'
  END AS data_quality_status

FROM ga4_revenue ga4
FULL OUTER JOIN shopify_orders shopify USING (date)
ORDER BY date DESC;

-- Expected Output:
-- transaction_accuracy_pct: 95-100% (some test orders may not have GA4 tracking)
-- revenue_accuracy_pct: 98-102% (minor timing differences acceptable)
-- data_quality_status: Mostly "Excellent" or "Good"

-- If seeing "Investigate" or "Critical":
-- 1. Check for duplicate purchases (run duplicate detection query)
-- 2. Verify webhook delivery success rate (check hosting platform logs)
-- 3. Confirm transaction_id format matches between systems
-- 4. Look for timezone mismatches (GA4 uses UTC, orders may use store timezone)
