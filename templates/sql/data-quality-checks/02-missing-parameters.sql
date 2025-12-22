-- ============================================================================
-- GA4 Data Quality Check: Missing Critical Parameters
-- ============================================================================
-- 
-- PURPOSE: Identifies events missing required parameters
-- IMPACT: Incomplete data prevents proper attribution and analysis
-- 
-- REAL EXAMPLE: Found 89% of form submissions missing form_id
--               After fix, identified best-converting forms (3x difference)
--
-- RUN FREQUENCY: Weekly
-- ESTIMATED COST: $0.05 per run
-- ============================================================================

WITH event_parameters AS (
  SELECT 
    event_date,
    event_name,
    event_timestamp,
    
    -- Extract key parameters
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'transaction_id') AS transaction_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'value') AS value,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'currency') AS currency,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id') AS form_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_name') AS form_name,
    
    -- Ecommerce data
    ecommerce.purchase_revenue,
    ARRAY_LENGTH(ecommerce.items) as item_count,
    
    -- Context
    user_pseudo_id,
    traffic_source.source,
    traffic_source.medium
    
  FROM `YOUR_PROJECT.analytics_XXXXX.events_*`
  
  WHERE _TABLE_SUFFIX BETWEEN 
    FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
    AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
)

-- ============================================================================
-- CHECK 1: Purchase Events Missing Critical Data
-- ============================================================================

SELECT 
  'Purchase Missing transaction_id' as issue_type,
  'CRITICAL' as severity,
  event_date,
  COUNT(*) as affected_events,
  ROUND(SUM(COALESCE(purchase_revenue, 0)), 2) as total_revenue_affected,
  '❌ Can\'t deduplicate or reconcile with order system' as impact
FROM event_parameters
WHERE event_name = 'purchase'
  AND transaction_id IS NULL
GROUP BY event_date

UNION ALL

SELECT 
  'Purchase Missing revenue value' as issue_type,
  'CRITICAL' as severity,
  event_date,
  COUNT(*) as affected_events,
  0 as total_revenue_affected,
  '❌ Revenue reporting incomplete, ROAS calculations wrong' as impact
FROM event_parameters
WHERE event_name = 'purchase'
  AND (value IS NULL OR value = 0)
  AND (purchase_revenue IS NULL OR purchase_revenue = 0)
GROUP BY event_date

UNION ALL

SELECT 
  'Purchase Missing items array' as issue_type,
  'HIGH' as severity,
  event_date,
  COUNT(*) as affected_events,
  ROUND(SUM(COALESCE(purchase_revenue, 0)), 2) as total_revenue_affected,
  '⚠️ Can\'t analyze product performance or create audiences' as impact
FROM event_parameters
WHERE event_name = 'purchase'
  AND (item_count IS NULL OR item_count = 0)
GROUP BY event_date

UNION ALL

SELECT 
  'Purchase Missing currency' as issue_type,
  'MEDIUM' as severity,
  event_date,
  COUNT(*) as affected_events,
  ROUND(SUM(COALESCE(purchase_revenue, 0)), 2) as total_revenue_affected,
  '⚠️ Multi-currency sites: revenue in wrong currency' as impact
FROM event_parameters
WHERE event_name = 'purchase'
  AND currency IS NULL
GROUP BY event_date

-- ============================================================================
-- CHECK 2: Form Submission Events Missing Data
-- ============================================================================

UNION ALL

SELECT 
  'Form Submission Missing form_id' as issue_type,
  'HIGH' as severity,
  event_date,
  COUNT(*) as affected_events,
  0 as total_revenue_affected,
  '⚠️ Can\'t identify which forms convert best' as impact
FROM event_parameters
WHERE event_name IN ('form_submit', 'form_submission', 'generate_lead')
  AND form_id IS NULL
  AND form_name IS NULL
GROUP BY event_date

-- ============================================================================
-- CHECK 3: Add to Cart Missing Product Info
-- ============================================================================

UNION ALL

SELECT 
  'Add to Cart Missing items' as issue_type,
  'HIGH' as severity,
  event_date,
  COUNT(*) as affected_events,
  0 as total_revenue_affected,
  '⚠️ Can\'t track product affinity or cart abandonment by product' as impact
FROM event_parameters
WHERE event_name = 'add_to_cart'
  AND (item_count IS NULL OR item_count = 0)
GROUP BY event_date

ORDER BY 
  CASE severity
    WHEN 'CRITICAL' THEN 1
    WHEN 'HIGH' THEN 2
    WHEN 'MEDIUM' THEN 3
    ELSE 4
  END,
  affected_events DESC;

-- ============================================================================
-- INTERPRETATION GUIDE
-- ============================================================================
--
-- SEVERITY LEVELS:
--
-- CRITICAL: Breaks core functionality
--   - Fix immediately (same day)
--   - Blocks revenue tracking or attribution
--
-- HIGH: Significantly limits analysis
--   - Fix within 1 week
--   - Prevents important optimizations
--
-- MEDIUM: Reduces data quality
--   - Fix within 2 weeks
--   - Nice to have for complete data
--
-- ============================================================================
-- COMMON FIXES
-- ============================================================================
--
-- Missing transaction_id:
--   dataLayer.push({
--     event: 'purchase',
--     ecommerce: {
--       transaction_id: '{{ Order ID }}',  // ADD THIS
--       value: 99.99,
--       items: [...]
--     }
--   });
--
-- Missing value/revenue:
--   Check if using 'value' vs 'purchase_revenue'
--   Both should be populated for compatibility
--
-- Missing items array:
--   Must include at least one item:
--   items: [{
--     item_id: 'SKU123',
--     item_name: 'Product Name',
--     price: 29.99,
--     quantity: 1
--   }]
--
-- Missing form_id:
--   Add to form submit handler:
--   dataLayer.push({
--     event: 'form_submit',
--     form_id: form.id,  // ADD THIS
--     form_name: form.getAttribute('name')
--   });
--
-- ============================================================================
