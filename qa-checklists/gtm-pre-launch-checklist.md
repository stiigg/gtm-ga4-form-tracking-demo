---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# GTM Pre-Launch Checklist (Run Before Every "Publish")

## Preview Mode Tests
- [ ] Open GTM Preview mode, connect to client site
- [ ] Submit test form - verify `form_submission_success` event fires
- [ ] Check Tag Assistant - GA4 tag shows "Tags Fired"
- [ ] Inspect dataLayer in console - all fields populated correctly?
- [ ] Test mobile view - does tracking still work on phone?

## GA4 DebugView Validation
- [ ] Open GA4 property → Admin → DebugView
- [ ] Submit form on site
- [ ] Verify `generate_lead` event appears within 30 seconds
- [ ] Check event parameters - form_id, form_type visible?
- [ ] Confirm user properties sending correctly

## Common Failure Checks
- [ ] Ad blockers disabled during testing
- [ ] GTM Container ID matches in HTML (head + body)
- [ ] GA4 Measurement ID correct in GTM configuration tag
- [ ] No console JavaScript errors on form page
- [ ] dataLayer.push happens BEFORE form submit

## Production Publish
- [ ] GTM: Click "Submit" (not just Save)
- [ ] Version name: "v[X.X] - [Client Name] - [Date]"
- [ ] Version description: "Form tracking for [form names], GA4 Measurement ID [ID]"
- [ ] Click "Publish"
- [ ] Wait 5 minutes for propagation
- [ ] Test on live site (not Preview)
- [ ] Verify in GA4 Realtime report (not DebugView)

## Client Notification
- [ ] Send "GTM published and tested" email
- [ ] Include screenshot of GA4 Realtime showing event
- [ ] Remind: "Data takes 24-48 hours to appear in standard reports"
