-- Duplicate Purchase Detection Query
-- Purpose: Identify if deduplication logic is working
-- Expected result: 0 duplicates after proper server-side setup

WITH purchase_events AS (
  SELECT
    event_date,
    event_timestamp,
    user_pseudo_id,
    ecommerce.transaction_id,
    traffic_source.source,
    traffic_source.medium,
    ecommerce.purchase_revenue,
    
    -- Identify if event came from client or server
    CASE
      WHEN event_name = 'purchase' AND traffic_source.source LIKE '%gtm%' THEN 'server'
      ELSE 'client'
    END AS event_source,
    
    -- Extract event_id if present (used for deduplication)
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'event_id') AS event_id
    
  FROM `your-project.analytics_XXXXX.events_*`
  WHERE event_name = 'purchase'
    AND _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
),

duplicates AS (
  SELECT
    transaction_id,
    COUNT(*) AS duplicate_count,
    ARRAY_AGG(
      STRUCT(
        event_timestamp,
        user_pseudo_id,
        event_source,
        event_id,
        purchase_revenue
      ) 
      ORDER BY event_timestamp
    ) AS event_details
  FROM purchase_events
  GROUP BY transaction_id
  HAVING COUNT(*) > 1
)

SELECT
  transaction_id,
  duplicate_count,
  event_details,
  
  -- Calculate revenue inflation
  duplicate_count * event_details[OFFSET(0)].purchase_revenue AS total_inflated_revenue,
  (duplicate_count - 1) * event_details[OFFSET(0)].purchase_revenue AS excess_revenue
  
FROM duplicates
ORDER BY duplicate_count DESC, total_inflated_revenue DESC;

-- If this returns rows:
-- 1. Check that event_id is being passed from client to server
-- 2. Verify Stape deduplication settings enabled (if using Stape)
-- 3. Confirm Firestore/datastore is accessible for ID storage
-- 4. Look for timezone issues (event_id generated at different times)

-- To calculate total duplicate impact:
SELECT
  COUNT(DISTINCT transaction_id) AS unique_transactions,
  SUM(duplicate_count) AS total_duplicate_events,
  SUM(excess_revenue) AS total_revenue_inflation,
  ROUND(AVG(duplicate_count), 2) AS avg_duplicates_per_transaction
FROM duplicates;
