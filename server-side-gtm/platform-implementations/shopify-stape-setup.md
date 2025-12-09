---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Shopify + Stape Server-Side GTM Implementation

Comprehensive guide to deploy server-side tagging on Shopify using Stape managed hosting. This abridged version highlights the critical pieces: prerequisites, setup steps, deduplication, validation, troubleshooting, and cost analysis.

## Prerequisites Checklist
- Shopify admin access with permission to manage apps and webhooks
- GA4 property with Measurement ID
- Meta Business Manager access (pixel + Conversions API)
- Stape.io account (recommended plan: $40/month starter)
- Ability to edit Shopify theme (for client-side event_id injection)

## Step-by-Step Stape Setup (15 minutes)
1. Create a new **Server container** in Google Tag Manager.
2. Sign up for **Stape.io** and connect your server container ID.
3. Configure the default domain (e.g., `track.yourstore.com`) and allow DNS to propagate.
4. Install the **Stape Shopify app** and connect your store to the Stape workspace.
5. Enable automatic Shopify webhooks for `orders/create` and `checkouts/create`.
6. Enable **GA4 client** and **Webhook client** in the server container.
7. Import the base configuration from [`../container-configs/sgtm-base-container-export.json`](../container-configs/sgtm-base-container-export.json) as a starting point.

## Server Container Configuration (1-2 hours)
- **GA4 Measurement Protocol tag**: forward events to your GA4 property with required params.
- **Meta Conversions API tag**: install from Community Template Gallery, add access token and pixel ID.
- **Variables**: create Event Parameter variables for `event_id`, `transaction_id`, `email`, `phone`, `currency`, `value`, and `items`.
- **Headers**: pass `x-forwarded-for` and `user_agent` from webhook requests to Meta and GA4 tags for better matching.

## Deduplication Logic (PREVENTS DUPLICATE PURCHASES)

### The Problem
Without deduplication, you count purchases TWICE:
1. Client-side JavaScript fires purchase event
2. Shopify webhook fires same purchase event
→ Result: 150-200% revenue inflation in GA4

### The Solution
Use matching `event_id` between client and server:

**Client-Side (Web GTM):**
```javascript
// In purchase tag, add custom parameter
event_id: {{Custom JS - Generate Event ID}}

// Custom JavaScript Variable:
function() {
  // Use transaction_id as event_id for purchases
  return {{Transaction ID}} + '_' + Date.now();
}
```

**Server-Side (Server GTM):**
```text
// In GA4 tag, map event_id from webhook
Event ID: {{Event Parameter - event_id}}

// Deduplication logic (Stape handles automatically)
// Checks Firestore for existing event_id
// If exists: Skip sending to GA4
// If new: Send to GA4 and store event_id
```

### Validation
BigQuery query to detect duplicates:
```sql
SELECT 
  transaction_id,
  COUNT(*) as duplicate_count
FROM `project.dataset.events_*`
WHERE event_name = 'purchase'
  AND _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
GROUP BY transaction_id
HAVING duplicate_count > 1
-- Should return 0 rows
```

## Webhook Validation Procedures
- Use Stape Logs to confirm Shopify webhook delivery success (>99%).
- In GTM Preview mode, verify server-side events include `event_id`, `transaction_id`, `currency`, and `items` array.
- In GA4 DebugView, confirm a single purchase per transaction ID.
- In Meta Events Manager, check Test Events for deduplicated purchases.

## Troubleshooting
- **Purchase missing in GA4**: confirm Measurement Protocol secret and client/server event_id mapping.
- **Duplicate purchases**: ensure client-side tag sends `event_id` and Stape deduplication toggle is on.
- **Currency mismatches**: normalize currency in server container using lookup tables.
- **Webhook failures**: reauthorize Stape app in Shopify and re-send test webhooks.

## Cost Analysis
- **Stape managed hosting**: $40/month typical for Shopify; scales with traffic.
- **Implementation effort**: 4-6 hours for basic setup, 1-2 days for full validation + CAPI tuning.
- **Expected uplift**: 25-35% more conversions captured, 15-20% better ROAS due to cleaner signals.

## Next Steps
- Complete the Meta CAPI configuration using [Meta CAPI guide](../conversions-api/meta-capi-complete-setup.md).
- Run the [QA checklist](../testing-validation/sgtm-qa-complete-checklist.md) before launch.
- Document results in a case study using the template in `../case-studies/`.
