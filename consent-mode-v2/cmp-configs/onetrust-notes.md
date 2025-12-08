# OneTrust - Consent Mode V2 Notes

## Detection
- `typeof OneTrust !== 'undefined'`
- Data Layer events: `OneTrustGroupsUpdated`
- Active groups stored in `window.OnetrustActiveGroups` (comma-delimited IDs)

## Category Mapping (verify per client)
- C0001: Strictly Necessary
- C0002: Performance/Analytics
- C0003: Functional
- C0004: Targeting/Advertising

## GTM Setup
1. Consent Initialization tag with default denies (use `/snippets/consent-init-generic.html`).
2. OneTrust integration tag using `/snippets/onetrust-integration.js`.
3. Trigger integration tag on Custom Event `OneTrustGroupsUpdated`.

## Common Issues
- `OnetrustActiveGroups` not available on page load → ensure OneTrust script loads before GTM or add guard rails in integration code.
- Category IDs differ by tenant → confirm mapping in OneTrust admin before deploying.
- Multiple OneTrust scripts on page cause conflicting updates → remove duplicates.

## Validation
- `consent_default` appears before pageview tags.
- Updating preferences changes consent_update payload according to active groups.
- Ads requests suppressed when C0004 not granted.
