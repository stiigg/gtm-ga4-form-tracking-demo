---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# When Variance Exceeds Acceptable Range

**Situation**: GA4 shows 450 conversions, HubSpot shows 387 conversions (14% difference, expected is 0-5%)

## Investigation Checklist (run in order)

### 1. Check Date Range Alignment (5 min)
- [ ] GA4 timezone: Admin → Property Settings → Reporting time zone
- [ ] HubSpot timezone: Settings → General → Time Zone
- [ ] Looker Studio filter: Verify both use same date range
- [ ] **Fix**: Align all to client's business timezone (usually their HQ location)

### 2. Verify Attribution Windows (10 min)
- [ ] GA4: Uses 30-day click attribution by default
- [ ] HubSpot: First-touch attribution (never changes)
- [ ] **Expected**: GA4 may be 5-8% higher due to longer window
- [ ] **Fix**: Document this in reconciliation notes: "GA4 includes 30-day lookback"

### 3. Bot Traffic Check (10 min)
- [ ] GA4: Admin → Data Settings → Data Filters → "Internal Traffic" enabled?
- [ ] GA4: Known bots are filtered automatically
- [ ] HubSpot: No native bot filtering
- [ ] **Expected**: GA4 typically 2-5% lower than HubSpot due to bot filtering
- [ ] **If variance is opposite** (GA4 higher): Investigate spam submissions in HubSpot

### 4. Form Submission Timing (15 min)
- [ ] Check browser console: Does `dataLayer.push()` happen BEFORE form submit?
- [ ] Test: Submit form, wait 5 seconds, check if both GA4 and HubSpot counted it
- [ ] **Common issue**: Form redirects before GTM tag fires → GA4 undercounts
- [ ] **Fix**: Add 500ms delay in form submit handler (see snippets/datalayer-form-tracking.js)

### 5. Deduplication Logic (10 min)
- [ ] GA4: Counts by client_id (browser-based)
- [ ] HubSpot: Deduplicates by email address
- [ ] **Scenario**: User submits form twice = 2 GA4 events, 1 HubSpot contact
- [ ] **Fix**: This is expected behavior, document variance range 0-10%

### 6. API Sync Delay (5 min)
- [ ] HubSpot API: 15-minute batch sync for contacts
- [ ] Looker Studio: Refreshes every 12-24 hours (free tier)
- [ ] **Fix**: Compare same date (e.g., Dec 1) after both platforms have synced

## Documentation for Client

When variance exceeds 10%, send this email:

```
Subject: Dashboard Data Variance - Investigation Complete

I investigated the 14% variance between GA4 (450) and HubSpot (387) conversions for [date range].

Root causes identified:
1. Attribution window: GA4 uses 30-day lookback, HubSpot is first-touch only → 5-8% expected difference
2. Bot filtering: GA4 filters known bots, HubSpot doesn't → 2-5% expected difference
3. Deduplication: Multiple form submissions = multiple GA4 events, one HubSpot contact → 2-4% expected difference

Combined expected variance: 9-17%  
Actual variance: 14%  
Status: ✓ Within acceptable range

For stakeholder reporting, I recommend using HubSpot contact count (387) as "source of truth" for lead volume, with GA4 providing campaign attribution detail.

Updated your reconciliation workbook (Sheet 2) with these notes.
```
