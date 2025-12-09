---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Consent Mode V2 Testing Checklist

## Environment
- [ ] GTM Preview open and connected
- [ ] CMP visible on page
- [ ] Console logging enabled

## Default Load (no action)
- [ ] `consent_default` appears first in Consent tab
- [ ] ad_storage = denied
- [ ] analytics_storage = denied
- [ ] ad_user_data = denied
- [ ] ad_personalization = denied
- [ ] No GA4/Ads tags fire before consent update

## Accept All
- [ ] Trigger CMP Accept
- [ ] `consent_update` logs granted for all four parameters
- [ ] GA4 tags fire after consent_update
- [ ] Google Ads/remarketing tags fire after consent_update

## Reject All
- [ ] Trigger CMP Reject
- [ ] `consent_update` logs denied for all four parameters
- [ ] GA4/Ads tags suppressed (only non-consent tags fire)

## Granular (if supported)
- [ ] Accept Analytics only
- [ ] Verify analytics_storage = granted; ad_* parameters remain denied
- [ ] GA4 fires; Ads tags stay suppressed

## Data Verification
- [ ] GA4 DebugView shows events with consented state
- [ ] Tag Assistant has no consent-related errors
- [ ] Network panel shows no Ads requests when ad_storage denied

## Artifacts
- [ ] Screenshot before fix saved to `/consent-mode-v2/client-diagnostics/[client]-before.png`
- [ ] Screenshot after fix saved to `/consent-mode-v2/client-diagnostics/[client]-after.png`

Notes:
- Document any custom event names used by CMP
- Log tag IDs updated with consent requirements
