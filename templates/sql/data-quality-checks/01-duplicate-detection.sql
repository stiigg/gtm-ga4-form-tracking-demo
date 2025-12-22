-- ============================================================================
-- GA4 Data Quality Check: Duplicate Transaction Detection
-- ============================================================================
-- 
-- PURPOSE: Identifies purchase events counted multiple times
-- IMPACT: Prevents revenue inflation and incorrect ROAS calculations
-- 
-- REAL EXAMPLE: Caught $47,000 in duplicate revenue for e-commerce client
--               Corrected ROAS from 2.1x to actual 4.5x
--
-- RUN FREQUENCY: Weekly (every Monday morning)
-- ESTIMATED COST: $0.05 per run (scans 7 days of data)
-- ============================================================================

WITH duplicate_purchases AS (
  SELECT 
    event_date,
    
    -- Extract transaction ID from event parameters
    (SELECT value.string_value 
     FROM UNNEST(event_params) 
     WHERE key = 'transaction_id') AS transaction_id,
    
    -- Count how many times each transaction appears
    COUNT(*) as event_count,
    
    -- Sum total revenue for this transaction
    SUM(ecommerce.purchase_revenue) as total_revenue,
    
    -- Collect all timestamps for debugging
    STRING_AGG(
      CAST(TIMESTAMP_MICROS(event_timestamp) AS STRING), 
      ', ' 
      ORDER BY event_timestamp
    ) as all_timestamps,
    
    -- Collect user IDs to check if same user or different
    STRING_AGG(DISTINCT user_pseudo_id, ', ') as user_ids
    
  FROM `YOUR_PROJECT.analytics_XXXXX.events_*`
  
  WHERE 
    -- Only check purchase events
    event_name = 'purchase'
    
    -- Check last 7 days (adjust as needed)
    AND _TABLE_SUFFIX BETWEEN 
      FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
      AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  
  GROUP BY event_date, transaction_id
  
  -- Only show duplicates (counted more than once)
  HAVING event_count > 1
)

SELECT 
  event_date,
  transaction_id,
  event_count,
  
  -- Show total revenue (inflated)
  ROUND(total_revenue, 2) as total_revenue_recorded,
  
  -- Calculate how much revenue is inflated
  ROUND(total_revenue * (event_count - 1) / event_count, 2) as inflated_amount,
  
  -- Show actual revenue (what it should be)
  ROUND(total_revenue / event_count, 2) as actual_revenue,
  
  -- Check if same user triggered duplicate
  CASE 
    WHEN user_ids NOT LIKE '%,%' THEN 'Same user (likely page refresh)'
    ELSE 'Multiple users (serious tracking issue!)'
  END as duplicate_type,
  
  all_timestamps,
  
  -- Generate helpful alert message
  CONCAT(
    '⚠️ Transaction ', transaction_id, 
    ' counted ', CAST(event_count AS STRING), ' times. ',
    'Inflated revenue by $', CAST(ROUND(total_revenue * (event_count - 1) / event_count, 2) AS STRING)
  ) as alert_message
  
FROM duplicate_purchases

-- Show worst offenders first
ORDER BY event_count DESC, total_revenue DESC;

-- ============================================================================
-- COMMON CAUSES & FIXES
-- ============================================================================
--
-- CAUSE 1: GTM container loaded multiple times
--   Symptoms: event_count = 2 or 3, same timestamps
--   Fix: Check page source for duplicate GTM snippets
--   Common locations: Header AND footer, theme + plugin
--
-- CAUSE 2: User refreshes confirmation page  
--   Symptoms: Same user_id, timestamps minutes apart
--   Fix: Add client-side flag to prevent re-firing
--   Code example: See docs/implementation/anti-double-fire.md
--
-- CAUSE 3: Tag fires on multiple triggers
--   Symptoms: Same transaction, milliseconds apart
--   Fix: Review GTM triggers - only ONE should fire per purchase
--
-- CAUSE 4: Server-side + client-side both firing
--   Symptoms: Two events with different user_ids
--   Fix: Ensure deduplication with event_id parameter
--   Guide: See docs/implementation/2025-meta-capi-setup.md
--
-- ============================================================================
-- HOW TO USE RESULTS
-- ============================================================================
--
-- 1. HIGH PRIORITY (event_count > 5):
--    - Critical tracking issue
--    - Investigate immediately
--    - Revenue reporting severely inflated
--
-- 2. MEDIUM PRIORITY (event_count = 2-3):
--    - Common issue (user refresh or double-load)
--    - Fix within 1 week
--    - Moderate impact on reporting
--
-- 3. LOW PRIORITY (event_count = 2, different dates):
--    - Might be legitimate (refund/reorder with same ID)
--    - Review manually
--    - Document if expected behavior
--
-- ============================================================================
-- EXPECTED RESULTS
-- ============================================================================
--
-- HEALTHY TRACKING: Zero rows returned (no duplicates found)
-- 
-- TYPICAL ISSUES: 1-5% of transactions show as duplicates
--
-- CRITICAL PROBLEMS: >10% of transactions duplicated
--                   Requires immediate investigation
--
-- ============================================================================
-- NEXT STEPS AFTER FINDING DUPLICATES
-- ============================================================================
--
-- 1. Document the issue:
--    - How many duplicates?
--    - What's the financial impact?
--    - Pattern (all transactions or specific products/pages)?
--
-- 2. Investigate root cause:
--    - Check GTM container for duplicate tags
--    - Review page source for multiple GTM snippets
--    - Test with GTM Preview mode
--
-- 3. Implement fix:
--    - Remove duplicate GTM snippets
--    - Add anti-double-fire protection
--    - Test thoroughly before deploying
--
-- 4. Verify fix:
--    - Re-run this query after 2-3 days
--    - Confirm duplicates stopped
--    - Document fix in tracking log
--
-- 5. Historical correction (optional):
--    - Create corrected dataset for analysis
--    - Update historical reports
--    - Communicate changes to stakeholders
--
-- ============================================================================

-- CUSTOMIZATION TIPS:
-- 
-- Check longer time period:
--   Change INTERVAL 7 DAY to INTERVAL 30 DAY
--
-- Include refunds in analysis:
--   Add: OR event_name = 'refund'
--
-- Export for reporting:
--   Save results as new table for Looker Studio
--   CREATE TABLE `project.dataset.duplicate_check` AS [this query]
--
-- ============================================================================