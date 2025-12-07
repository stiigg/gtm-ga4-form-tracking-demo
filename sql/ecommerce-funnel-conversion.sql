/**
 * E-COMMERCE FUNNEL - CONVERSION RATES
 * 
 * Purpose: Calculate drop-off rates at each stage of e-commerce funnel
 * Events tracked (in order):
 *   1. view_item_list - User views product gallery
 *   2. view_item - User clicks on specific product
 *   3. add_to_cart - User adds product to cart
 *   4. begin_checkout - User starts checkout process
 *   5. purchase - User completes purchase
 * 
 * Project: gtm-ga4-analytics
 * Dataset: analytics_514638991
 * 
 * Output: Conversion rates between each funnel stage
 * Use case: Identify where users drop off in purchase funnel
 * 
 * Cost: ~10-20MB for 7 days of typical demo traffic (FREE)
 */

WITH funnel_stages AS (
  SELECT
    user_pseudo_id,
    COUNTIF(event_name = 'view_item_list') as viewed_list,
    COUNTIF(event_name = 'view_item') as viewed_item,
    COUNTIF(event_name = 'add_to_cart') as added_to_cart,
    COUNTIF(event_name = 'begin_checkout') as began_checkout,
    COUNTIF(event_name = 'purchase') as purchased
  FROM `gtm-ga4-analytics.analytics_514638991.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
    AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
    AND event_name IN ('view_item_list', 'view_item', 'add_to_cart', 'begin_checkout', 'purchase')
  GROUP BY user_pseudo_id
)
SELECT
  -- Total users at each stage
  COUNTIF(viewed_list > 0) as users_viewed_list,
  COUNTIF(viewed_item > 0) as users_viewed_item,
  COUNTIF(added_to_cart > 0) as users_added_cart,
  COUNTIF(began_checkout > 0) as users_began_checkout,
  COUNTIF(purchased > 0) as users_purchased,
  
  -- Conversion rates between stages (percentage moving to next stage)
  ROUND(COUNTIF(viewed_item > 0) * 100.0 / NULLIF(COUNTIF(viewed_list > 0), 0), 2) as list_to_item_rate,
  ROUND(COUNTIF(added_to_cart > 0) * 100.0 / NULLIF(COUNTIF(viewed_item > 0), 0), 2) as item_to_cart_rate,
  ROUND(COUNTIF(began_checkout > 0) * 100.0 / NULLIF(COUNTIF(added_to_cart > 0), 0), 2) as cart_to_checkout_rate,
  ROUND(COUNTIF(purchased > 0) * 100.0 / NULLIF(COUNTIF(began_checkout > 0), 0), 2) as checkout_to_purchase_rate,
  
  -- Overall funnel conversion (from first touch to purchase)
  ROUND(COUNTIF(purchased > 0) * 100.0 / NULLIF(COUNTIF(viewed_list > 0), 0), 2) as overall_conversion_rate
FROM funnel_stages;

/**
 * EXPECTED OUTPUT:
 * users_viewed_list | users_viewed_item | users_added_cart | users_began_checkout | users_purchased
 *       1000        |       520         |       184        |        112          |       23
 * 
 * list_to_item_rate | item_to_cart_rate | cart_to_checkout_rate | checkout_to_purchase_rate | overall_conversion_rate
 *      52.0%        |      35.4%        |        60.9%          |          20.5%            |        2.3%
 * 
 * INSIGHTS TO LOOK FOR:
 * 1. Biggest drop-off usually occurs at view_item → add_to_cart
 * 2. Good checkout_to_purchase rate indicates smooth checkout UX
 * 3. Overall conversion 2-5% is typical for demo/test sites
 * 4. Lower rates indicate friction points to investigate
 */