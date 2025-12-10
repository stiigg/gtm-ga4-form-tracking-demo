# Server-Side GTM Pre-Launch Checklist

**Purpose:** Validate ALL critical components before enabling server container in production.

**Usage:** Complete checklist in staging environment. DO NOT proceed to production until all items marked ✅.

## Infrastructure Validation

### DNS and SSL
- [ ] Custom subdomain configured (track.yourstore.com)
- [ ] DNS propagation complete (check: `nslookup track.yourstore.com`)
- [ ] SSL certificate active and valid (check in browser - no warnings)
- [ ] Server container URL responds: `https://track.yourstore.com/healthz`

### Server Container Setup
- [ ] Server container published (not just saved)
- [ ] Stape workspace connected to GTM server container ID
- [ ] Stape environment shows "Active" status
- [ ] Test webhook successfully received (Stape logs show 200 OK)

## Attribution & Tracking Accuracy

### UTM Parameter Forwarding
- [ ] Test: Visit site with `?utm_source=test&utm_medium=validation`
- [ ] Server GTM Preview shows utm_source = "test"
- [ ] GA4 DebugView (server event) shows traffic_source.source = "test"
- [ ] BigQuery query confirms utm_source populated:
```
SELECT 
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'utm_source') as source
FROM `project.dataset.events_*`
WHERE _TABLE_SUFFIX = FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name = 'purchase'
LIMIT 10
-- Should show actual sources, NOT null
```

### Cookie Strategy
- [ ] Inspect browser cookies: Only ONE `_ga` cookie exists
- [ ] Cookie domain matches your site domain
- [ ] Server container cookie strategy = "JavaScript Managed" (if client tags active)
- [ ] Session count stable (not dropped >10% vs client-side baseline)

### IP Address and User-Agent Forwarding
- [ ] Server GTM Preview shows client_ip_address variable populated
- [ ] Server GTM Preview shows user_agent variable populated
- [ ] Meta Events Manager test event shows actual city/device (not "Unknown")
- [ ] GA4 geo reports show realistic country distribution (not all "United States")

## Deduplication Validation

### GA4 Transaction Deduplication
- [ ] Place test order
- [ ] Check BigQuery for duplicate transaction_id (should be ZERO):
```
SELECT 
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'transaction_id') as txn,
  COUNT(*) as occurrences
FROM `project.dataset.events_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))
  AND event_name = 'purchase'
GROUP BY txn
HAVING occurrences > 1
```

### Meta CAPI Deduplication
- [ ] Client Pixel and Server CAPI use IDENTICAL event_id generation
- [ ] Meta Events Manager shows "Deduplicated" badge on server events
- [ ] Test: Fire same event from client + server → Meta counts only 1

### Stape Firestore Deduplication
- [ ] Stape deduplication toggle enabled (if using Stape)
- [ ] Test: Send duplicate webhook → Stape logs show "Event already processed, skipping"

## Consent Mode Compliance

### Consent Synchronization
- [ ] Deny all cookies via consent banner
- [ ] Check Server GTM Preview: No tags should fire
- [ ] Accept analytics cookies
- [ ] Check Server GTM Preview: GA4 tags fire, Meta blocked (if ad_storage denied)

### GDPR/CCPA Validation
- [ ] Server tags check consent object from client dataLayer
- [ ] Tags have blocking triggers for denied consent categories
- [ ] Documentation for client: How to validate consent compliance

## Performance and Cost

### Response Time
- [ ] Server container response time <200ms (check Stape logs or GCP metrics)
- [ ] Webhook processing time <500ms
- [ ] No timeout errors in Stape error logs

### Cost Validation
- [ ] Estimated monthly cost matches traffic tier (Stape pricing calculator)
- [ ] BigQuery daily cost <$1/day (if writing directly to BQ)
- [ ] No unexpected Cloud Run charges (if self-hosted)

## Revenue Reconciliation

### Accuracy Benchmark
Complete 7-day parallel tracking (client + server both active):

- [ ] GA4 revenue (server events) within 2% of Shopify order system
- [ ] GA4 transaction count matches Shopify order count
- [ ] Average order value within $5 of Shopify actual AOV

```
-- Revenue reconciliation query
SELECT 
  PARSE_DATE('%Y%m%d', event_date) as date,
  SUM((SELECT value.float_value FROM UNNEST(event_params) WHERE key = 'value')) as ga4_revenue,
  COUNT(DISTINCT (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'transaction_id')) as ga4_transactions
FROM `project.dataset.events_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
  AND event_name = 'purchase'
GROUP BY date
ORDER BY date
-- Compare to Shopify orders report for same dates
```

## Failure Mode Testing

### Webhook Delivery Failure
- [ ] Test: Temporarily disable Stape container
- [ ] Place order
- [ ] Verify: Client-side still tracks (fallback works)
- [ ] Re-enable Stape
- [ ] Verify: Webhook redelivery attempted (if enabled)

### Ad Blocker Bypass Validation
- [ ] Enable uBlock Origin
- [ ] Place test order
- [ ] Check: Client-side purchase blocked (expected)
- [ ] Check: Server-side webhook still delivers (expected)
- [ ] GA4 reports show purchase (server-side bypass successful)

### Server Container Downtime
- [ ] Check Stape uptime SLA (should be 99.9%)
- [ ] Test: What happens if Stape down during checkout?
- [ ] Fallback plan documented (client-side takes over automatically)

## Documentation for Client

### Handoff Checklist
- [ ] Server container export provided (JSON file)
- [ ] Custom domain DNS settings documented
- [ ] Stape account credentials transferred (if managed by client)
- [ ] Troubleshooting runbook provided
- [ ] Monitoring dashboard configured (Stape alerts + GA4 reports)

### Ongoing Maintenance
- [ ] Weekly revenue reconciliation automated (BigQuery scheduled query)
- [ ] Monthly server container review (check for deprecated tags)
- [ ] Quarterly cost review (Stape/GCP invoices)

## Sign-Off

**Completed by:** _______________  
**Date:** _______________  
**Client approval:** _______________  

**All items marked ✅ before production?**
- [ ] YES → Proceed to production
- [ ] NO → Document blockers, resolve before enabling

**Production cutover plan:**
1. Enable server container in GTM (publish)
2. Monitor first 100 purchases (expect 1-2% errors)
3. 24-hour validation: Revenue reconciliation
4. 7-day validation: Full attribution analysis
5. Client sign-off: Server-side approved OR rollback to client-only
