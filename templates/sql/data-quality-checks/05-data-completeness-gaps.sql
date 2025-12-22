-- ============================================================================
-- GA4 BigQuery Data Quality: Data Completeness & Export Gap Detection
-- ============================================================================
-- Purpose: Identify missing data, export failures, and incomplete event batches
-- Use Case: Catch BigQuery export issues before they impact reporting
-- Schedule: Run daily (morning) to detect previous day's issues
-- ============================================================================

-- Replace these variables:
-- YOUR_PROJECT_ID: Your Google Cloud project ID
-- YOUR_DATASET: Your GA4 BigQuery dataset name
-- LOOKBACK_DAYS: Days to check (default: 30)

-- ============================================================================
-- Query 1: Detect Missing Daily Export Tables
-- ============================================================================
-- Problem: BigQuery export can fail silently leaving gaps in data
-- Impact: Missing conversion data, incomplete reporting

WITH date_range AS (
  SELECT 
    FORMAT_DATE('%Y%m%d', date) as expected_date
  FROM 
    UNNEST(GENERATE_DATE_ARRAY(
      DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY),
      DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
    )) AS date
),
actual_tables AS (
  SELECT DISTINCT
    _TABLE_SUFFIX as table_date
  FROM `YOUR_PROJECT_ID.YOUR_DATASET.events_*`
  WHERE _TABLE_SUFFIX BETWEEN 
    FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
    AND FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))
)
SELECT 
  PARSE_DATE('%Y%m%d', dr.expected_date) as missing_date,
  FORMAT_DATE('%A', PARSE_DATE('%Y%m%d', dr.expected_date)) as day_of_week,
  DATE_DIFF(CURRENT_DATE(), PARSE_DATE('%Y%m%d', dr.expected_date), DAY) as days_ago,
  '❌ EXPORT FAILED' as status,
  'No events table found for this date. Check GA4 BigQuery export settings.' as action_required
FROM date_range dr
LEFT JOIN actual_tables at
  ON dr.expected_date = at.table_date
WHERE at.table_date IS NULL
ORDER BY missing_date DESC;

-- ============================================================================
-- Query 2: Detect Unusually Low Event Volumes
-- ============================================================================
-- Purpose: Identify partial exports or tracking failures
-- Method: Compare daily volumes to 7-day moving average

WITH daily_volumes AS (
  SELECT 
    event_date,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_pseudo_id) as user_count,
    COUNT(DISTINCT CONCAT(user_pseudo_id, '.', 
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))) as session_count
  FROM `YOUR_PROJECT_ID.YOUR_DATASET.events_*`
  WHERE _TABLE_SUFFIX BETWEEN 
    FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
    AND FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))
  GROUP BY event_date
),
moving_averages AS (
  SELECT 
    event_date,
    event_count,
    user_count,
    session_count,
    AVG(event_count) OVER (
      ORDER BY event_date
      ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
    ) as avg_event_count_7d,
    AVG(user_count) OVER (
      ORDER BY event_date  
      ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
    ) as avg_user_count_7d,
    AVG(session_count) OVER (
      ORDER BY event_date
      ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING  
    ) as avg_session_count_7d
  FROM daily_volumes
)
SELECT 
  PARSE_DATE('%Y%m%d', event_date) as date,
  FORMAT_DATE('%A', PARSE_DATE('%Y%m%d', event_date)) as day_of_week,
  event_count,
  ROUND(avg_event_count_7d, 0) as expected_events,
  ROUND((event_count - avg_event_count_7d) / avg_event_count_7d * 100, 1) as pct_change,
  user_count,
  ROUND(avg_user_count_7d, 0) as expected_users,
  session_count,
  ROUND(avg_session_count_7d, 0) as expected_sessions,
  CASE 
    WHEN event_count < avg_event_count_7d * 0.5 THEN '❌ CRITICAL: 50%+ drop'
    WHEN event_count < avg_event_count_7d * 0.7 THEN '⚠️ WARNING: 30%+ drop'
    ELSE '✅ Normal'
  END as alert_level
FROM moving_averages
WHERE event_count < avg_event_count_7d * 0.7  -- Show only concerning drops
  AND avg_event_count_7d IS NOT NULL
ORDER BY event_date DESC
LIMIT 20;

-- ============================================================================
-- Query 3: Detect Missing Critical Events
-- ============================================================================
-- Purpose: Ensure key events fire every day (form submits, purchases, etc.)

WITH critical_events AS (
  -- Define events that should occur daily
  SELECT 'form_submit' as event_name UNION ALL
  SELECT 'form_start' UNION ALL
  SELECT 'page_view' UNION ALL
  SELECT 'session_start'
),
daily_event_presence AS (
  SELECT 
    event_date,
    ce.event_name,
    COUNTIF(e.event_name = ce.event_name) as event_count
  FROM critical_events ce
  CROSS JOIN (
    SELECT DISTINCT event_date
    FROM `YOUR_PROJECT_ID.YOUR_DATASET.events_*`
    WHERE _TABLE_SUFFIX BETWEEN 
      FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY))
      AND FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))
  ) dates
  LEFT JOIN `YOUR_PROJECT_ID.YOUR_DATASET.events_*` e
    ON e.event_date = dates.event_date
    AND e.event_name = ce.event_name
    AND e._TABLE_SUFFIX = dates.event_date
  GROUP BY event_date, ce.event_name
)
SELECT 
  PARSE_DATE('%Y%m%d', event_date) as date,
  FORMAT_DATE('%A', PARSE_DATE('%Y%m%d', event_date)) as day_of_week,
  event_name,
  event_count,
  CASE 
    WHEN event_count = 0 THEN '❌ MISSING'
    WHEN event_count < 10 THEN '⚠️ VERY LOW'
    ELSE '✅ Present'
  END as status,
  CASE 
    WHEN event_count = 0 THEN 'Critical event not fired. Check GTM triggers and website functionality.'
    WHEN event_count < 10 THEN 'Unusually low count. Investigate tracking or user behavior changes.'
    ELSE 'OK'
  END as recommendation
FROM daily_event_presence
WHERE event_count < 10  -- Flag missing or very low counts
ORDER BY event_date DESC, event_name;

-- ============================================================================
-- Query 4: Detect Incomplete Form Tracking Sessions
-- ============================================================================
-- Purpose: Find form_start events without corresponding form_submit
-- Indicates: Broken tracking or legitimate abandonment (needs investigation)

WITH form_sessions AS (
  SELECT 
    event_date,
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') as session_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id') as form_id,
    COUNTIF(event_name = 'form_start') as starts,
    COUNTIF(event_name = 'form_submit') as submits
  FROM `YOUR_PROJECT_ID.YOUR_DATASET.events_*`
  WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))
    AND event_name IN ('form_start', 'form_submit')
  GROUP BY event_date, user_pseudo_id, session_id, form_id
),
incomplete_tracking AS (
  SELECT 
    event_date,
    form_id,
    COUNT(*) as incomplete_sessions,
    SUM(starts) as total_starts,
    SUM(submits) as total_submits
  FROM form_sessions
  WHERE starts > 0 AND submits = 0  -- Started but never submitted
  GROUP BY event_date, form_id
)
SELECT 
  PARSE_DATE('%Y%m%d', event_date) as date,
  form_id,
  incomplete_sessions,
  total_starts,
  total_submits,
  ROUND(incomplete_sessions * 100.0 / total_starts, 1) as incomplete_rate_pct,
  CASE 
    WHEN incomplete_sessions * 100.0 / total_starts > 95 THEN '❌ CRITICAL: Tracking likely broken'
    WHEN incomplete_sessions * 100.0 / total_starts > 80 THEN '⚠️ HIGH: Investigate tracking'
    ELSE '📉 Normal abandonment rate'
  END as assessment
FROM incomplete_tracking
WHERE incomplete_sessions * 100.0 / total_starts > 80  -- Flag high incomplete rates
ORDER BY incomplete_rate_pct DESC;

-- ============================================================================
-- Query 5: Detect Data Export Lag
-- ============================================================================
-- Purpose: Identify delays in BigQuery export processing
-- Expected: Data available within 24-48 hours

WITH recent_tables AS (
  SELECT 
    _TABLE_SUFFIX as table_date,
    MAX(event_timestamp) as latest_event_timestamp,
    COUNT(*) as event_count
  FROM `YOUR_PROJECT_ID.YOUR_DATASET.events_*`
  WHERE _TABLE_SUFFIX BETWEEN 
    FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
    AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY _TABLE_SUFFIX
)
SELECT 
  PARSE_DATE('%Y%m%d', table_date) as event_date,
  TIMESTAMP_MICROS(latest_event_timestamp) as latest_event_time,
  event_count,
  TIMESTAMP_DIFF(
    CURRENT_TIMESTAMP(), 
    TIMESTAMP_MICROS(latest_event_timestamp), 
    HOUR
  ) as hours_since_latest_event,
  CASE 
    WHEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), TIMESTAMP_MICROS(latest_event_timestamp), HOUR) > 72 
      THEN '❌ DELAYED: >72 hours'
    WHEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), TIMESTAMP_MICROS(latest_event_timestamp), HOUR) > 48 
      THEN '⚠️ SLOW: >48 hours'
    ELSE '✅ Normal latency'
  END as status
FROM recent_tables
WHERE TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), TIMESTAMP_MICROS(latest_event_timestamp), HOUR) > 48
ORDER BY table_date DESC;

-- ============================================================================
-- Query 6: Detect NULL Critical Fields
-- ============================================================================
-- Purpose: Identify events with missing essential identifiers

SELECT 
  event_date,
  event_name,
  COUNTIF(user_pseudo_id IS NULL) as null_user_id_count,
  COUNTIF((SELECT value.int_value FROM UNNEST(event_params) 
    WHERE key = 'ga_session_id') IS NULL) as null_session_id_count,
  COUNTIF(event_timestamp IS NULL) as null_timestamp_count,
  COUNT(*) as total_events,
  ROUND(COUNTIF(user_pseudo_id IS NULL) * 100.0 / COUNT(*), 2) as null_user_id_pct
FROM `YOUR_PROJECT_ID.YOUR_DATASET.events_*`
WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))
GROUP BY event_date, event_name
HAVING 
  null_user_id_count > 0 
  OR null_session_id_count > 0 
  OR null_timestamp_count > 0
ORDER BY null_user_id_count DESC;

-- ============================================================================
-- IMPLEMENTATION NOTES
-- ============================================================================
/*
1. Schedule: Run daily at 9 AM (after BigQuery export completes)

2. Alert Priorities:
   - Missing daily tables = CRITICAL (immediate action)
   - 50%+ volume drop = CRITICAL
   - Missing critical events = HIGH
   - 30-50% volume drop = MEDIUM
   - High form abandonment = LOW (may be user behavior)

3. Common Causes:
   - Missing tables: GA4 property misconfigured, export quota exceeded
   - Low volumes: Website down, GTM not loading, ad blockers
   - Missing events: GTM trigger conditions broken
   - NULL fields: Tracking code errors, bot traffic

4. Automated Response:
   - Send email/Slack alert with query results
   - Log to monitoring table for trend analysis
   - Trigger PagerDuty for CRITICAL issues
*/
