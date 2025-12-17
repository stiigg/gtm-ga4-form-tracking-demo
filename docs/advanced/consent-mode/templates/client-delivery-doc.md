---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Consent Mode V2 Implementation Summary

Client: [Name]
Date: [Date]
Implementation time: [X hours]
Prepared by: [Your name]

## What Was Fixed

### Issue Identified
- Screenshot (before): `/consent-mode-v2/client-diagnostics/[client-name]-before.png`
- Problem statement:
- Impact statement (conversions/audience loss):

### Solution Implemented
- Consent Initialization tag created and prioritized
- Consent Mode V2 parameters added (ad_user_data, ad_personalization)
- CMP integration configured ([CMP name])
- Consent requirements applied to GTM tags
- Any conflicting scripts removed/disabled

## Verification
- Screenshot (after): `/consent-mode-v2/client-diagnostics/[client-name]-after.png`
- ✅ Consent signals fire before tags
- ✅ All 4 V2 parameters present
- ✅ Tags respect user consent choices
- ✅ EU compliance requirements met

## GTM Changes Made
1. Created: "Consent Mode - Default State (V2)" (Consent Initialization)
2. Created: "Consent Update - Accept All"
3. Created: "Consent Update - Reject All"
4. Modified: [List existing tags updated with consent requirements]

## Testing Performed
- [ ] Default state (no interaction)
- [ ] Accept all cookies
- [ ] Reject all cookies
- [ ] Granular consent (analytics only) if applicable
- [ ] GA4 events visible in DebugView
- [ ] Google Ads tags respect ad_storage consent

## Monthly Verification Steps (hand-off)
1. Open GTM → Preview
2. Check Consent tab shows consent_default first
3. Interact with CMP banner and confirm consent_update
4. Confirm tags fire after consent update
5. Log results and screenshots in `/consent-mode-v2/client-diagnostics/`

## Next Steps / Support
- Monitor GA4/Ads metrics over next 48 hours
- If consent behavior changes after CMP/GTM/website updates, rerun Phase 1 diagnostics
- Contact: [Your details]
- Typical diagnostic time: 15–30 minutes
