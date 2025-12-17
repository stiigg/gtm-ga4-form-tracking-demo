# GTM/GA4 Implementation Checklist

Use this checklist when implementing tracking based on this repository.

## Phase 1: Planning (Week 1)

### Discovery
- [ ] Audit existing GTM container
- [ ] Review current GA4 property setup
- [ ] Identify critical conversion events
- [ ] Document current data quality issues
- [ ] Determine if server-side is needed

### Requirements
- [ ] List all forms/events to track
- [ ] Define success criteria (e.g., 90% accuracy)
- [ ] Get stakeholder approval on approach
- [ ] Confirm budget for server-side (if applicable)

## Phase 2: Client-Side Implementation (Week 2-3)

### GTM Setup
- [ ] Create/update web GTM container
- [ ] Add GA4 Configuration tag
- [ ] Implement form_submission_success event
- [ ] Add validation-first logic
- [ ] Set up anti-double-fire guards
- [ ] Configure custom event parameters

### Testing (Client-Side)
- [ ] Test in GTM Preview Mode
- [ ] Verify events in GA4 DebugView
- [ ] Check dataLayer in browser console
- [ ] Test all form fields populate correctly
- [ ] Verify deduplication works (refresh test)
- [ ] Test across browsers (Chrome, Safari, Firefox)

## Phase 3: Server-Side Implementation (Week 4-5)

**Only proceed if needed (ad blocker recovery, Meta CAPI, etc.)**

### Infrastructure Setup
- [ ] Create server GTM container
- [ ] Deploy to GCP Cloud Run OR sign up for Stape.io
- [ ] Configure custom domain (CNAME record)
- [ ] Verify DNS propagation (`nslookup track.yourdomain.com`)
- [ ] Test health endpoint (`https://track.yourdomain.com/healthz`)

### Server Container Configuration
- [ ] Add GA4 Client
- [ ] Add GA4 Server Tag
- [ ] Configure Measurement Protocol settings
- [ ] Add Meta CAPI tag (if needed)
- [ ] Set up event deduplication
- [ ] Add custom enrichment variables

### Web Container Updates
- [ ] Add `transport_url` to GA4 Config tag
- [ ] Set `first_party_collection: true`
- [ ] Update all GA4 events to include `transaction_id`
- [ ] Add `tracking_source: 'server'` parameter

### Testing (Server-Side)
- [ ] Verify requests route to custom domain (Network tab)
- [ ] Check server container receives events (Preview mode)
- [ ] Confirm events appear in GA4 with server attribution
- [ ] Test deduplication (same transaction_id doesn't double-count)
- [ ] Verify Meta CAPI events (if applicable)
- [ ] Test with ad blockers enabled (should still track)

## Phase 4: Validation (Week 6)

### Data Quality Check
- [ ] Run 7-day data collection period
- [ ] Compare event counts: client vs server
- [ ] Reconcile purchase revenue vs order system
- [ ] Check for duplicate transactions
- [ ] Verify iOS Safari tracking improved
- [ ] Monitor GA4 processing lag times

### Performance Metrics
- [ ] Track server container response times
- [ ] Monitor GCP/Stape costs
- [ ] Check for any error logs
- [ ] Verify 95%+ capture rate achieved

### Acceptance Criteria
- [ ] ≥90% revenue reconciliation accuracy
- [ ] No duplicate purchase events
- [ ] ≥95% event capture rate (vs baseline)
- [ ] Server response times <500ms
- [ ] Stakeholder approval obtained

## Phase 5: Documentation & Handoff

### Deliverables
- [ ] Implementation guide (platform-specific)
- [ ] GTM container export (backup)
- [ ] Data dictionary (events + parameters)
- [ ] Troubleshooting runbook
- [ ] Training session completed
- [ ] Access transferred to client

### Maintenance Plan
- [ ] Schedule monthly data quality audits
- [ ] Set up automated monitoring alerts
- [ ] Document escalation procedures
- [ ] Provide support contact info

---

## Troubleshooting Common Issues

### Events Not Firing
**Check:**
1. GTM Preview Mode shows tag firing?
2. dataLayer contains event? (console.log)
3. Trigger conditions met?
4. GA4 property not in test mode?

### Server Container Not Receiving
**Check:**
1. DNS CNAME configured correctly?
2. transport_url matches custom domain exactly?
3. SSL certificate valid on custom domain?
4. Server container published (not just saved)?

### Duplicate Events
**Check:**
1. Anti-double-fire guard implemented?
2. transaction_id includes timestamp?
3. Session storage check in place?
4. Not tracking same event in multiple places?

---

## Success Criteria Summary

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Revenue Accuracy | ≥90% | Compare GA4 vs order system |
| Event Capture Rate | ≥95% | Server-side vs baseline |
| Duplicate Rate | <1% | Filter by transaction_id |
| Page Load Impact | <100ms | Chrome DevTools Performance |
| Server Response Time | <500ms | Server container logs |
