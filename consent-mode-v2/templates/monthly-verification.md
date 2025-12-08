# Monthly Consent Mode Verification (5-minute routine)

Run this once per month or after any CMP/GTM/website release.

## Steps
1. Open GTM → Preview → Enter site URL → Connect.
2. In Consent tab, confirm `consent_default` is the first event with all four parameters set to denied.
3. Interact with CMP banner (Accept and Reject flows):
   - Verify `consent_update` fires with expected grants/denials.
   - Ensure tags fire only after the consent_update event.
4. In Tags tab, confirm GA4 and Ads tags show consent requirements satisfied before firing.
5. Capture updated screenshots and save to `/consent-mode-v2/client-diagnostics/[client]-[date]-verification.png`.
6. Update `/consent-mode-v2/templates/client-delivery-doc.md` copy for the client if changes occurred.

## Quick Checks
- [ ] No tags firing before consent_default
- [ ] All four consent parameters visible in Consent tab
- [ ] GA4 DebugView receiving events with consented state
- [ ] Ads requests suppressed when ad_storage denied

## Notes
- If any step fails, rerun Phase 1 and Phase 3 from the Debugging Runbook.
- Record GTM version and CMP version after verification for audit trail.
