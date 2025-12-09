---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# GTM Events Not Firing - Quick Fixes

1. **Check Preview Mode**: Does Tag Assistant show the custom event? If not, dataLayer push may be missing.
2. **Console Check**: Run `console.log(window.dataLayer);` and confirm event payload exists.
3. **Trigger Filter**: Ensure Custom Event trigger listens for exact event name (`form_submission_success`).
4. **Publish Status**: Container changes saved but not published? Publish and retest.
5. **Ad Blockers**: Disable extensions or use Chrome Incognito.
6. **Duplicate IDs**: If multiple forms share ID, use more specific selectors or data attributes.
7. **Race Conditions**: Add 500ms delay before page redirect (see `snippets/datalayer-form-tracking.js`).
8. **Environment**: Are you on production vs staging? Verify correct GTM ID in page source.
