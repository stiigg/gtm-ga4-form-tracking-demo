-- ============================================================================
-- GA4 BigQuery Data Quality: Schema & Data Type Validation
-- ============================================================================
-- Purpose: Validate event parameter data types remain consistent over time
-- Use Case: Catch implementation errors where same parameter uses different types
-- Schedule: Run weekly or after GTM container updates
-- ============================================================================

-- Replace these variables with your actual values:
-- YOUR_PROJECT_ID: Your Google Cloud project ID
-- YOUR_DATASET: Your GA4 BigQuery dataset name
-- LOOKBACK_DAYS: Number of days to analyze (default: 7)

-- ============================================================================
-- Query 1: Detect Event Parameters with Inconsistent Data Types
-- ============================================================================
-- Problem: Same parameter key using multiple data types breaks downstream pipelines
-- Example: "form_value" sometimes string ("$50") vs double (50.0)

WITH parameter_types AS (
  SELECT 
    event_name,
    params.key AS parameter_name,
    CASE 
      WHEN params.value.string_value IS NOT NULL THEN 'string'
      WHEN params.value.int_value IS NOT NULL THEN 'int'
      WHEN params.value.double_value IS NOT NULL THEN 'double'
      WHEN params.value.float_value IS NOT NULL THEN 'float'
    END AS data_type,
    COUNT(*) as occurrence_count,
    MIN(event_date) as first_seen,
    MAX(event_date) as last_seen
  FROM `YOUR_PROJECT_ID.YOUR_DATASET.events_*`,
  UNNEST(event_params) AS params
  WHERE _TABLE_SUFFIX BETWEEN 
    FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL LOOKBACK_DAYS DAY))
    AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY event_name, parameter_name, data_type
),
inconsistent_params AS (
  SELECT 
    event_name,
    parameter_name,
    COUNT(DISTINCT data_type) as distinct_type_count,
    STRING_AGG(DISTINCT CONCAT(data_type, ' (', occurrence_count, ' events)'), ', ' 
      ORDER BY occurrence_count DESC) as type_breakdown
  FROM parameter_types
  GROUP BY event_name, parameter_name
  HAVING COUNT(DISTINCT data_type) > 1
)
SELECT 
  event_name,
  parameter_name,
  distinct_type_count,
  type_breakdown,
  '❌ CRITICAL' as severity,
  'Parameter uses multiple data types. Standardize in GTM configuration.' as recommendation
FROM inconsistent_params
ORDER BY distinct_type_count DESC, event_name;

-- ============================================================================
-- Query 2: Validate Required Event Parameters Schema
-- ============================================================================
-- Purpose: Ensure critical events maintain expected parameter structure
-- Customize based on your tracking plan

WITH event_requirements AS (
  -- Define your required parameters per event type
  SELECT 'form_submit' as event_name, 'form_id' as required_param UNION ALL
  SELECT 'form_submit', 'form_name' UNION ALL
  SELECT 'form_submit', 'form_destination' UNION ALL
  SELECT 'form_start', 'form_id' UNION ALL
  SELECT 'form_start', 'form_name' UNION ALL
  SELECT 'page_view', 'page_location' UNION ALL
  SELECT 'page_view', 'page_title' UNION ALL
  SELECT 'purchase', 'transaction_id' UNION ALL
  SELECT 'purchase', 'value' UNION ALL
  SELECT 'purchase', 'currency'
),
event_actual_params AS (
  SELECT DISTINCT
    event_name,
    params.key as param_key
  FROM `YOUR_PROJECT_ID.YOUR_DATASET.events_*`,
  UNNEST(event_params) AS params
  WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
    AND event_name IN ('form_submit', 'form_start', 'page_view', 'purchase')
)
SELECT 
  er.event_name,
  er.required_param,
  CASE 
    WHEN eap.param_key IS NOT NULL THEN '✅ Present'
    ELSE '❌ MISSING'
  END as status,
  CASE 
    WHEN eap.param_key IS NULL THEN 'Required parameter not found in today''s data'
    ELSE 'OK'
  END as issue
FROM event_requirements er
LEFT JOIN event_actual_params eap
  ON er.event_name = eap.event_name 
  AND er.required_param = eap.param_key
WHERE eap.param_key IS NULL  -- Show only missing parameters
ORDER BY er.event_name, er.required_param;

-- ============================================================================
-- Query 3: Detect Unexpected New Event Parameters
-- ============================================================================
-- Purpose: Flag newly introduced parameters that weren't in baseline
-- Helps catch typos or unplanned tracking changes

WITH baseline_params AS (
  -- Parameters seen in the baseline period (days 8-14)
  SELECT DISTINCT
    event_name,
    params.key as parameter_name
  FROM `YOUR_PROJECT_ID.YOUR_DATASET.events_*`,
  UNNEST(event_params) AS params
  WHERE _TABLE_SUFFIX BETWEEN 
    FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY))
    AND FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 8 DAY))
),
recent_params AS (
  -- Parameters seen in recent period (last 7 days)
  SELECT DISTINCT
    event_name,
    params.key as parameter_name
  FROM `YOUR_PROJECT_ID.YOUR_DATASET.events_*`,
  UNNEST(event_params) AS params
  WHERE _TABLE_SUFFIX BETWEEN 
    FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
    AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
)
SELECT 
  r.event_name,
  r.parameter_name,
  '🆕 NEW' as status,
  'New parameter detected. Verify this was intentional.' as recommendation
FROM recent_params r
LEFT JOIN baseline_params b
  ON r.event_name = b.event_name
  AND r.parameter_name = b.parameter_name
WHERE b.parameter_name IS NULL
  AND r.event_name IN ('form_submit', 'form_start', 'page_view', 'purchase')  -- Focus on key events
ORDER BY r.event_name, r.parameter_name;

-- ============================================================================
-- Query 4: Validate User Properties Schema Consistency
-- ============================================================================

WITH user_property_types AS (
  SELECT 
    props.key AS property_name,
    CASE 
      WHEN props.value.string_value IS NOT NULL THEN 'string'
      WHEN props.value.int_value IS NOT NULL THEN 'int'
      WHEN props.value.double_value IS NOT NULL THEN 'double'
      WHEN props.value.float_value IS NOT NULL THEN 'float'
    END AS data_type,
    COUNT(*) as occurrence_count
  FROM `YOUR_PROJECT_ID.YOUR_DATASET.events_*`,
  UNNEST(user_properties) AS props
  WHERE _TABLE_SUFFIX BETWEEN 
    FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
    AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY property_name, data_type
)
SELECT 
  property_name,
  COUNT(DISTINCT data_type) as distinct_type_count,
  STRING_AGG(DISTINCT CONCAT(data_type, ' (', occurrence_count, ')'), ', ') as type_distribution,
  CASE 
    WHEN COUNT(DISTINCT data_type) > 1 THEN '❌ Inconsistent'
    ELSE '✅ Consistent'
  END as validation_status
FROM user_property_types
GROUP BY property_name
HAVING COUNT(DISTINCT data_type) > 1
ORDER BY property_name;

-- ============================================================================
-- Query 5: Validate Items Array Structure (E-commerce)
-- ============================================================================
-- Purpose: Ensure e-commerce items maintain consistent schema

WITH items_schema AS (
  SELECT 
    event_date,
    event_name,
    item.item_id,
    item.item_name,
    item.price,
    item.quantity,
    item.item_brand,
    item.item_category,
    CASE 
      WHEN item.item_id IS NULL THEN 'missing_item_id'
      WHEN item.item_name IS NULL THEN 'missing_item_name'
      WHEN item.price IS NULL THEN 'missing_price'
      WHEN item.quantity IS NULL THEN 'missing_quantity'
      ELSE 'complete'
    END as schema_issue
  FROM `YOUR_PROJECT_ID.YOUR_DATASET.events_*`,
  UNNEST(items) as item
  WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
    AND event_name IN ('purchase', 'add_to_cart', 'view_item')
)
SELECT 
  event_name,
  schema_issue,
  COUNT(*) as item_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY event_name), 2) as percentage
FROM items_schema
GROUP BY event_name, schema_issue
HAVING schema_issue != 'complete'
ORDER BY event_name, item_count DESC;

-- ============================================================================
-- IMPLEMENTATION NOTES
-- ============================================================================
/*
1. Schedule: Run weekly or after GTM container publishes
2. Alert Thresholds:
   - Any inconsistent parameter types = CRITICAL alert
   - Missing required parameters on >5% of events = HIGH alert
   - New unexpected parameters = MEDIUM alert (review needed)

3. Common Issues & Solutions:
   - String vs Number: Update GTM variable to cast to correct type
   - Missing Parameters: Fix GTM trigger conditions or add default values
   - New Parameters: Update tracking plan documentation if intentional

4. Integration:
   - Export results to a monitoring table
   - Set up BigQuery scheduled queries with email alerts
   - Create dashboard showing schema drift over time
*/
