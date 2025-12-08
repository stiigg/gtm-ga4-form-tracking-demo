-- VARIANCE CALCULATION (use in Looker Studio calculated field)
-- Compares GA4 events to HubSpot form submissions
ABS((GA4_Events - HubSpot_Forms) / GA4_Events) * 100

-- VARIANCE STATUS (green/red indicator)
CASE
  WHEN ABS((GA4_Events - HubSpot_Forms) / GA4_Events) * 100 <= 5 THEN "✓ Within Range"
  WHEN ABS((GA4_Events - HubSpot_Forms) / GA4_Events) * 100 <= 10 THEN "⚠ Review"
  ELSE "❌ Investigate"
END

-- CONVERSION RATE
(HubSpot_Deals_Won / GA4_Sessions) * 100

-- COST PER LEAD
LinkedIn_Ad_Spend / HubSpot_New_Leads
