# Cookiebot - Consent Mode V2 Notes

## Detection
- `typeof Cookiebot !== 'undefined'`
- Preview → Consent tab should show events tied to `CookiebotOnAccept` / `CookiebotOnDecline`.

## GTM Setup
1. Consent Initialization tag with default denies (use `/snippets/consent-init-generic.html`).
2. Cookiebot integration tag (Custom HTML) using `/snippets/cookiebot-integration.js`.
3. Triggers:
   - Consent Initialization → All Pages
   - Custom Event `CookiebotOnAccept`
   - Custom Event `CookiebotOnDecline`

## Common Issues
- Cookiebot script loaded async after GTM → add default tag in Consent Init to gate early tags.
- Marketing vs Statistics categories map to Ads vs Analytics. Confirm with client's Cookiebot settings.
- Duplicate consent code in site template can conflict; remove hard-coded `gtag('consent', ...)` if GTM handles it.

## Validation
- `consent_default` fires before any pageview tags.
- `consent_update` aligns with Accept/Decline actions.
- Marketing denied should suppress Ads/remarketing calls.
