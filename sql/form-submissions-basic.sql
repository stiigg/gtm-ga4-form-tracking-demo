/**
 * FORM SUBMISSIONS - BASIC ANALYSIS
 * 
 * Purpose: Count total form submissions and unique users
 * Events: generate_lead
 * Parameters: form_id, form_type, form_location
 * 
 * Project: gtm-ga4-analytics (179616959118)
 * Dataset: analytics_514638991
 * Property: G-S9SRF7GGHW
 * 
 * Usage: 
 * 1. Open BigQuery console: https://console.cloud.google.com/bigquery?project=gtm-ga4-analytics
 * 2. Copy and paste this query
 * 3. Click "Run"
 * 
 * Expected output columns:
 * - event_date: Date of submission (YYYYMMDD)
 * - form_id: Form identifier (e.g., contact_us)
 * - form_type: Form type (e.g., lead)
 * - form_location: Page location (e.g., demo_page)
 * - total_submissions: Count of form submits
 * - unique_users: Deduplicated user count
 * - submissions_per_user: Average submissions per user
 * 
 * Cost: ~5-10MB processed for 7 days of typical demo data (FREE)
 */

SELECT
  event_date,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id') as form_id,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_type') as form_type,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_location') as form_location,
  COUNT(*) as total_submissions,
  COUNT(DISTINCT user_pseudo_id) as unique_users,
  ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT user_pseudo_id), 2) as submissions_per_user
FROM `gtm-ga4-analytics.analytics_514638991.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name = 'generate_lead'
GROUP BY event_date, form_id, form_type, form_location
ORDER BY event_date DESC, total_submissions DESC;