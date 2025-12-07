/**
 * TRAFFIC SOURCE PERFORMANCE
 * 
 * Purpose: Analyze which marketing channels drive form submissions
 * Uses: traffic_source.source, traffic_source.medium, traffic_source.name
 * 
 * Project: gtm-ga4-analytics
 * Dataset: analytics_514638991
 * 
 * Output: Submissions and purchases by UTM parameters
 * Filters: Minimum 5 users to exclude noise
 * 
 * Use case: Attribution and marketing ROI analysis
 * 
 * Cost: ~20-40MB for 30 days (FREE)
 */

SELECT
  traffic_source.source,
  traffic_source.medium,
  traffic_source.name as campaign,
  COUNT(DISTINCT user_pseudo_id) as unique_users,
  COUNTIF(event_name = 'generate_lead') as total_form_submissions,
  COUNTIF(event_name = 'purchase') as total_purchases,
  ROUND(COUNTIF(event_name = 'generate_lead') * 100.0 / COUNT(DISTINCT user_pseudo_id), 2) as lead_conversion_rate,
  ROUND(COUNTIF(event_name = 'purchase') * 100.0 / COUNT(DISTINCT user_pseudo_id), 2) as purchase_conversion_rate
FROM `gtm-ga4-analytics.analytics_514638991.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
GROUP BY traffic_source.source, traffic_source.medium, campaign
HAVING unique_users >= 5  -- Filter out low-volume sources (reduces noise)
ORDER BY total_form_submissions DESC
LIMIT 20;

/**
 * EXPECTED OUTPUT EXAMPLE:
 * 
 * source   | medium  | campaign        | unique_users | form_submissions | purchases | lead_conv_rate | purchase_conv_rate
 * ---------|---------|-----------------|--------------|------------------|-----------|----------------|-------------------
 * google   | organic | (not set)       | 1,245        | 156              | 23        | 12.53%         | 1.85%
 * (direct) | (none)  | (not set)       | 892          | 98               | 18        | 10.99%         | 2.02%
 * facebook | cpc     | summer_campaign | 456          | 67               | 12        | 14.69%         | 2.63%
 * google   | cpc     | brand_search    | 234          | 45               | 9         | 19.23%         | 3.85%
 * 
 * INSIGHTS TO LOOK FOR:
 * 1. Which channel has highest conversion rate? (quality over quantity)
 * 2. Paid vs organic performance comparison
 * 3. Campaign-specific ROI (if you have cost data)
 * 4. Direct traffic often has highest conversion (intent-driven)
 * 
 * NEXT STEPS:
 * 1. Join with ad spend data to calculate CPA (cost per acquisition)
 * 2. Segment by device/browser for channel-specific optimization
 * 3. Create attribution model (first-click, last-click, linear)
 */