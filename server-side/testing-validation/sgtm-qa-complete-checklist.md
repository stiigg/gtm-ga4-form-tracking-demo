---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Server-Side GTM QA Checklist

Use this checklist before launching server-side tracking. Mark each item as completed during validation.

## Pre-Launch Checklist
1. Server container imported and credentials stored securely
2. DNS records propagated and SSL valid
3. GA4 client receiving requests
4. Webhook client receiving Shopify events (orders/create, checkouts/create)
5. Measurement Protocol secret configured
6. Meta CAPI access token stored and active
7. Event parameters mapped: event_id, transaction_id, currency, value, items
8. IP and user agent forwarded to tags
9. Timezone aligned between GA4 and source system
10. Test purchase completes end-to-end
11. Consent preferences handled (if applicable)
12. Error logging enabled in Stape
13. Backup of web container and server container exports created
14. Rollback plan documented
15. Stakeholders notified of validation window

## Validation Procedures
- **GTM Preview Mode**: Confirm server container receives webhook payloads and populates variables.
- **GA4 DebugView**: Verify each ecommerce event flows through with correct params and a single purchase per transaction_id.
- **Meta Test Events**: Send test events and confirm deduplication between Pixel and CAPI.
- **BigQuery duplicate detection**: Run `deduplication-audit-query.sql` for current date.
- **Revenue reconciliation**: Run `revenue-reconciliation-sgtm.sql` for the past 30 days; expect <5% variance.
- **Webhook delivery**: Check Stape logs for 99%+ delivery success and retry counts near zero.

## Go-Live Checklist
1. Production DNS cutover completed
2. Monitoring alerts configured (GA4 anomaly detection, Stape webhook errors)
3. Validation results reviewed with stakeholders
4. Documentation handoff completed
5. Support channel agreed (Slack/email) for 7-day validation period
6. Calendar reminder set for 7-day review
7. Backup/rollback plan accessible to on-call team
8. Change log updated in repository
9. Privacy/compliance review signed off
10. Pixel + CAPI deduplication confirmed on live traffic

## Common Issues & Solutions
- **Purchase events not appearing in GA4** → Check Measurement Protocol secret and verify event names match GA4 schema.
- **Duplicate purchases detected** → Ensure client and server share identical `event_id`; confirm Stape deduplication toggle.
- **Meta CAPI events not matching Pixel** → Hash PII correctly and pass IP/user agent headers; review Match Quality score.
- **Webhook delivery failures** → Reauthorize Shopify app, ensure firewall allows Stape IPs, retry failed deliveries.
- **Currency/value mismatches** → Normalize currency server-side and round values to two decimals.
