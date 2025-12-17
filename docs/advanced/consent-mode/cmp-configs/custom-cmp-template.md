---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Custom CMP - Consent Mode V2 Template

Use this when the client has a bespoke banner or an unsupported CMP.

## Discovery
- Inspect page source for custom banner script names.
- In DevTools console, run `console.log(window.dataLayer)` before and after clicking Accept/Reject to capture event names.
- Identify any cookies set for consent state (names containing `consent`, `cookie`, `gdpr`).

## Mapping
- Decide which custom payload keys represent marketing vs analytics consent.
- Map marketing to ad_storage/ad_user_data/ad_personalization; map analytics to analytics_storage.
- If only one boolean exists, apply it to all four parameters.

## GTM Implementation
1. Consent Initialization tag using `/snippets/consent-init-generic.html`.
2. Custom integration tag using `/snippets/custom-cmp-template.js`.
3. Update `CMP_EVENT_NAME` and payload mapping in the snippet to match the site's event.
4. Trigger integration tag on the custom dataLayer event (e.g., `cookie_consent_all`).

## Validation
- `consent_default` fires first.
- Custom event triggers `consent_update` with expected grants/denials.
- GA4/Ads tags respect consent settings.

## Documentation
- Record the event name and payload shape in client hand-off docs.
- Save before/after screenshots in `/consent-mode-v2/client-diagnostics/`.
