-- DAILY FORM SUBMISSION COMPARISON (GA4 vs HubSpot)
SELECT
  ga4.event_date AS date,
  COUNTIF(event_name = 'generate_lead') AS ga4_leads,
  COUNT(DISTINCT hubspot.contact_id) AS hubspot_contacts,
  SAFE_DIVIDE(ABS(COUNTIF(event_name = 'generate_lead') - COUNT(DISTINCT hubspot.contact_id)), NULLIF(COUNTIF(event_name = 'generate_lead'),0)) * 100 AS variance_pct
FROM `project.dataset.events_*` AS ga4
LEFT JOIN `project.dataset.hubspot_contacts` AS hubspot
  ON ga4.user_pseudo_id = hubspot.client_id
GROUP BY date
ORDER BY date DESC
LIMIT 30;

-- SPEND VS REVENUE CHECK (LinkedIn vs GA4 ecom)
SELECT
  DATE(spend.date) AS date,
  SUM(spend.amount) AS linkedin_spend,
  SUM(ecom.purchase_revenue) AS ga4_revenue,
  SAFE_DIVIDE(SUM(ecom.purchase_revenue) - SUM(spend.amount), NULLIF(SUM(spend.amount),0)) * 100 AS roi_variance_pct
FROM `project.dataset.linkedin_spend` AS spend
LEFT JOIN `project.dataset.ga4_purchases` AS ecom
  ON DATE(ecom.event_timestamp) = DATE(spend.date)
GROUP BY date
ORDER BY date DESC
LIMIT 30;

-- CHECK FOR MISSING FORM PARAMETERS
SELECT
  event_date,
  COUNTIF(form_id IS NULL) AS missing_form_id,
  COUNTIF(form_type IS NULL) AS missing_form_type,
  COUNTIF(form_location IS NULL) AS missing_form_location
FROM `project.dataset.events_*`
WHERE event_name = 'form_submission_success'
GROUP BY event_date
ORDER BY event_date DESC
LIMIT 14;
