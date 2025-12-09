/**
 * Product Affinity Analysis
 * Identifies products frequently purchased together
 * Use for cross-sell recommendations and bundle creation
 */

WITH purchase_pairs AS (
  SELECT
    items1.item_id AS product_a_id,
    items1.item_name AS product_a_name,
    items1.item_category AS product_a_category,
    items2.item_id AS product_b_id,
    items2.item_name AS product_b_name,
    items2.item_category AS product_b_category,
    COUNT(DISTINCT ecommerce.transaction_id) AS co_purchase_count,
    SUM(items1.price + items2.price) AS combined_revenue
  FROM `YOUR_PROJECT.analytics_XXXXX.events_*`,
    UNNEST(ecommerce.items) AS items1,
    UNNEST(ecommerce.items) AS items2
  WHERE event_name = 'purchase'
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
                          AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
    AND items1.item_id < items2.item_id -- Avoid duplicates and self-pairs
  GROUP BY 1, 2, 3, 4, 5, 6
  HAVING co_purchase_count >= 5 -- Minimum threshold for statistical significance
),

-- Calculate individual product purchase counts for lift calculation
product_totals AS (
  SELECT
    items.item_id,
    COUNT(DISTINCT ecommerce.transaction_id) AS total_purchases
  FROM `YOUR_PROJECT.analytics_XXXXX.events_*`,
    UNNEST(ecommerce.items) AS items
  WHERE event_name = 'purchase'
    AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
                          AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  GROUP BY item_id
)

SELECT
  pp.product_a_name,
  pp.product_b_name,
  pp.co_purchase_count,
  
  -- Lift metric: How much more likely products are purchased together
  -- vs if purchases were independent
  ROUND(
    pp.co_purchase_count / 
    (pt_a.total_purchases * pt_b.total_purchases / 
     (SELECT COUNT(DISTINCT ecommerce.transaction_id) 
      FROM `YOUR_PROJECT.analytics_XXXXX.events_*`
      WHERE event_name = 'purchase'
        AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
                              AND FORMAT_DATE('%Y%m%d', CURRENT_DATE()))),
    2
  ) AS affinity_lift,
  
  ROUND(pp.combined_revenue / pp.co_purchase_count, 2) AS avg_bundle_value,
  
  -- Cross-category flag (interesting for merchandising)
  IF(pp.product_a_category = pp.product_b_category, 'Same Category', 'Cross-Category') AS purchase_type

FROM purchase_pairs pp
LEFT JOIN product_totals pt_a ON pp.product_a_id = pt_a.item_id
LEFT JOIN product_totals pt_b ON pp.product_b_id = pt_b.item_id

WHERE pp.co_purchase_count >= 10 -- Raise threshold for output

ORDER BY pp.co_purchase_count DESC, affinity_lift DESC
LIMIT 50;
