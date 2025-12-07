/**
 * FORM SUBMISSIONS - DETAILED ANALYSIS WITH ALL PARAMETERS
 * 
 * Purpose: Comprehensive form analysis including topic and plan selection
 * Use case: Understand which form configurations drive most conversions
 * 
 * Project: gtm-ga4-analytics
 * Property: G-S9SRF7GGHW (514638991)
 * 
 * Custom parameters analyzed:
 * - form_id: Form identifier
 * - form_type: Form type
 * - form_location: Page location
 * - form_topic: Selected topic (sales, support, partnership)
 * - form_plan: Selected plan (basic, pro)
 * 
 * Expected output columns:
 * - event_date: Date of submission
 * - form_id: Form identifier (e.g., contact_us)
 * - form_type: Type (e.g., lead)
 * - form_location: Location (e.g., demo_page)
 * - form_topic: Topic selected (sales, support, partnership)
 * - form_plan: Plan selected (basic, pro)
 * - submissions: Total submission count
 * - unique_users: Deduplicated user count
 * - percentage_of_total: Percentage of all submissions
 * 
 * Cost: ~10-20MB for 30 days (FREE - within 1TB limit)
 */

SELECT
  event_date,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id') as form_id,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_type') as form_type,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_location') as form_location,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_topic') as form_topic,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_plan') as form_plan,
  COUNT(*) as submissions,
  COUNT(DISTINCT user_pseudo_id) as unique_users,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage_of_total
FROM `gtm-ga4-analytics.analytics_514638991.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name = 'generate_lead'
GROUP BY event_date, form_id, form_type, form_location, form_topic, form_plan
ORDER BY submissions DESC;

/**
 * INSIGHTS TO LOOK FOR:
 * 1. Which form_topic gets most submissions? (sales vs support vs partnership)
 * 2. Which form_plan is more popular? (basic vs pro)
 * 3. Are there patterns by day of week?
 * 4. What's the submissions_per_user ratio? (>1 might indicate issues)
 */