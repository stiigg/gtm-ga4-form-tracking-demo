-- ============================================================================
-- GA4 Data Quality Check: Revenue Anomalies Detection
-- ============================================================================
-- 
-- PURPOSE: Identifies suspicious or impossible revenue values
-- IMPACT: Prevents skewed metrics and identifies test transactions
-- 
-- REAL EXAMPLE: Found 234 test purchases ($999,999 each) inflating revenue by $234M
--               After removal, accurate revenue reporting restored
--
-- RUN FREQUENCY: Weekly
-- ESTIMATED COST: $0.05 per run
-- ============================================================================

WITH purchase_events AS (
  SELECT 
    event_date,
    event_timestamp,
    
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'transaction_id') AS transaction_id,
    
    -- Get revenue from both possible locations
    COALESCE(
      ecommerce.purchase_revenue,
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'value'),
      (SELECT value.double_value FROM UNNEST(event_params) WHERE key = 'value')
    ) AS revenue,
    
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'currency') AS currency,
    
    -- Context for investigation
    user_pseudo_id,
    user_properties,
    traffic_source.source,
    traffic_source.medium,
    device.category as device_category,
    geo.country,
    
    -- Items for additional validation
    ARRAY_LENGTH(ecommerce.items) as item_count,
    ecommerce.items
    
  FROM `YOUR_PROJECT.analytics_XXXXX.events_*`
  
  WHERE event_name = 'purchase'
    AND _TABLE_SUFFIX BETWEEN 
      FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
      AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
)

-- ============================================================================
-- ANOMALY 1: Negative Revenue
-- ============================================================================

SELECT 
  '❌ Negative Revenue' as anomaly_type,
  'CRITICAL' as severity,
  event_date,
  transaction_id,
  revenue,
  currency,
  source,
  medium,
  country,
  'Negative revenue is impossible. Likely tracking error.' as issue,
  'Check if refund events are being sent as purchase events' as likely_cause
FROM purchase_events
WHERE revenue < 0

UNION ALL

-- ============================================================================
-- ANOMALY 2: Zero Revenue
-- ============================================================================

SELECT 
  '⚠️ Zero Revenue Purchase' as anomaly_type,
  'HIGH' as severity,
  event_date,
  transaction_id,
  revenue,
  currency,
  source,
  medium,
  country,
  'Purchase event with $0 revenue' as issue,
  'Free trial? Gift card only? Or tracking error?' as likely_cause
FROM purchase_events
WHERE revenue = 0 OR revenue IS NULL

UNION ALL

-- ============================================================================
-- ANOMALY 3: Extremely High Revenue
-- ============================================================================

SELECT 
  '🚨 Suspiciously High Revenue' as anomaly_type,
  'HIGH' as severity,
  event_date,
  transaction_id,
  revenue,
  currency,
  source,
  medium,
  country,
  'Revenue exceeds $10,000 - flag for review' as issue,
  'Could be: legitimate B2B order, test transaction, or decimal error' as likely_cause
FROM purchase_events
WHERE revenue > 10000  -- Adjust threshold for your business

UNION ALL

-- ============================================================================
-- ANOMALY 4: Common Test Values
-- ============================================================================

SELECT 
  '🧪 Test Transaction Detected' as anomaly_type,
  'MEDIUM' as severity,
  event_date,
  transaction_id,
  revenue,
  currency,
  source,
  medium,
  country,
  'Common test value detected' as issue,
  'QA team testing - should be filtered from production data' as likely_cause
FROM purchase_events
WHERE revenue IN (999999, 123456, 111111, 0.01, 1.00, 9.99)
  OR transaction_id LIKE '%test%'
  OR transaction_id LIKE '%TEST%'
  OR transaction_id LIKE '%demo%'

UNION ALL

-- ============================================================================
-- ANOMALY 5: Currency Mismatch with Country
-- ============================================================================

SELECT 
  '💱 Currency/Country Mismatch' as anomaly_type,
  'MEDIUM' as severity,
  event_date,
  transaction_id,
  revenue,
  currency,
  source,
  medium,
  country,
  CONCAT('Currency ', currency, ' unusual for country ', country) as issue,
  'VPN user, incorrect currency setting, or geo data error' as likely_cause
FROM purchase_events
WHERE 
  -- US orders in non-USD
  (country = 'United States' AND currency NOT IN ('USD', NULL))
  -- UK orders in non-GBP/EUR
  OR (country = 'United Kingdom' AND currency NOT IN ('GBP', 'EUR', 'USD', NULL))
  -- EU orders in non-EUR
  OR (country IN ('Germany', 'France', 'Italy', 'Spain') AND currency NOT IN ('EUR', 'USD', NULL))

UNION ALL

-- ============================================================================
-- ANOMALY 6: Revenue Without Items
-- ============================================================================

SELECT 
  '📦 Revenue Without Products' as anomaly_type,
  'HIGH' as severity,
  event_date,
  transaction_id,
  revenue,
  currency,
  source,
  medium,
  country,
  'Purchase has revenue but no items array' as issue,
  'Incomplete ecommerce data - prevents product-level analysis' as likely_cause
FROM purchase_events
WHERE revenue > 0
  AND (item_count IS NULL OR item_count = 0)

UNION ALL

-- ============================================================================
-- ANOMALY 7: Items Total Doesn't Match Revenue
-- ============================================================================

SELECT 
  '🧮 Revenue Calculation Mismatch' as anomaly_type,
  'MEDIUM' as severity,
  event_date,
  transaction_id,
  revenue,
  currency,
  source,
  medium,
  country,
  CONCAT(
    'Transaction revenue: $', CAST(revenue AS STRING),
    ' vs Items total: $', 
    CAST(
      (SELECT SUM(item.price * item.quantity) 
       FROM UNNEST(items) as item
      ) AS STRING
    )
  ) as issue,
  'Shipping/tax included in total but not itemized, or calculation error' as likely_cause
FROM purchase_events
WHERE item_count > 0
  AND ABS(
    revenue - 
    (SELECT SUM(COALESCE(item.price, 0) * COALESCE(item.quantity, 1)) 
     FROM UNNEST(items) as item
    )
  ) > 0.50  -- Allow $0.50 rounding difference

ORDER BY 
  CASE severity
    WHEN 'CRITICAL' THEN 1
    WHEN 'HIGH' THEN 2  
    WHEN 'MEDIUM' THEN 3
    ELSE 4
  END,
  event_date DESC,
  revenue DESC;

-- ============================================================================
-- INTERPRETATION & ACTION GUIDE
-- ============================================================================
--
-- CRITICAL ISSUES (Fix Immediately):
--   - Negative revenue: Logic error in tracking code
--   - Action: Review dataLayer implementation
--
-- HIGH PRIORITY (Fix This Week):
--   - Zero revenue purchases: Determine if expected
--   - High revenue: Verify if legitimate B2B orders
--   - Missing items: Add product data to tracking
--
-- MEDIUM PRIORITY (Fix This Month):
--   - Test transactions: Filter from production data
--   - Currency mismatches: Review multi-currency setup
--   - Revenue calculation differences: Investigate discrepancy
--
-- ============================================================================
-- CUSTOMIZATION FOR YOUR BUSINESS
-- ============================================================================
--
-- Adjust high-revenue threshold:
--   Low-ticket e-commerce: WHERE revenue > 500
--   High-ticket B2B: WHERE revenue > 50000
--
-- Add industry-specific checks:
--   Subscription: Check if annual > 12x monthly
--   Digital products: Revenue without shipping address
--   Services: Revenue without associated service_type parameter
--
-- ============================================================================
