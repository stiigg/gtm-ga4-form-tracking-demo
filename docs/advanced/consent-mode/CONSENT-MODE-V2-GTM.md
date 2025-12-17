# Google Consent Mode v2 - GTM Implementation Guide

## What is Consent Mode v2?

**Mandatory since March 2024** for websites targeting EEA/UK users running Google Ads or GA4.

Consent Mode v2 adds two new parameters:
- `ad_user_data` - User data sent to Google for advertising
- `ad_personalization` - Personalized advertising

Without proper implementation:
- ❌ Google Ads campaigns paused in EEA
- ❌ Conversion modeling disabled
- ❌ Behavioral modeling limited in GA4
- ❌ Attribution windows shortened

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│  Page Load Sequence                                       │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  1. consent-mode-v2-baseline.js loads                    │
│     ↓                                                     │
│     Sets all consent to 'denied' (GDPR-safe default)     │
│                                                           │
│  2. GTM container loads                                   │
│     ↓                                                     │
│     Respects consent state, fires conditionally          │
│                                                           │
│  3. CMP (Cookie Consent Platform) loads                  │
│     ↓                                                     │
│     Shows banner to user                                 │
│                                                           │
│  4. User clicks "Accept" or "Deny"                       │
│     ↓                                                     │
│     CMP calls window.updateConsent({...})                │
│     ↓                                                     │
│     GTM re-evaluates tags based on new consent state     │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

## Step 1: Add Consent Mode Script to Your Site

### HTML Placement (CRITICAL)

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Your Site</title>
  
  <!-- 1. Consent Mode v2 baseline (FIRST) -->
  <script src="/consent-mode/consent-mode-v2-baseline.js"></script>
  
  <!-- 2. GTM container (SECOND) -->
  <!-- Google Tag Manager -->
  <script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
  new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
  j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
  'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
  })(window,document,'script','dataLayer','GTM-XXXXXX');</script>
  <!-- End Google Tag Manager -->
  
  <!-- 3. Your CMP script (THIRD) -->
  <script src="https://cdn.cookielaw.org/scripttemplates/otSDKStub.js" ...></script>
</head>
```

**Why this order matters:**
1. Consent Mode script creates `gtag('consent', 'default', ...)` **before** GTM loads
2. GTM sees consent state immediately and respects it
3. CMP loads after and can update consent without reload

## Step 2: Configure GTM Container

### Option A: Built-in Consent Settings (Recommended)

1. In GTM, go to **Admin** → **Container Settings**
2. Enable **"Additional Consent Checks"**
3. For each tag (GA4, Google Ads):
   - Go to **Advanced Settings** → **Consent Settings**
   - Check **"Require additional consent for tag to fire"**
   - Select required consent types:
     - GA4 Config: `analytics_storage`
     - GA4 Event: `analytics_storage`
     - Google Ads Conversion: `ad_storage`, `ad_user_data`
     - Remarketing: `ad_storage`, `ad_personalization`

### Option B: Manual Trigger Conditions (Advanced)

Create custom trigger that checks consent:

**Variable**: Consent - Analytics Storage
- Type: Data Layer Variable
- Data Layer Variable Name: `consent.analytics_storage`

**Trigger**: Analytics Consent Granted
- Type: Custom Event
- Event name: `.*` (regex, all events)
- Condition: `Consent - Analytics Storage` equals `granted`

Apply this trigger to GA4 tags.

## Step 3: Integrate with Your CMP

### OneTrust Example

```javascript
// OneTrust callback when user updates consent
function OptanonWrapper() {
  const consent = {
    analytics: OnetrustActiveGroups.includes('C0002'),
    ads: OnetrustActiveGroups.includes('C0004'),
    functional: OnetrustActiveGroups.includes('C0003'),
    personalization: OnetrustActiveGroups.includes('C0005')
  };
  
  window.updateConsent(consent);
}
```

### Cookiebot Example

```javascript
window.addEventListener('CookiebotOnAccept', function () {
  const consent = {
    analytics: Cookiebot.consent.statistics,
    ads: Cookiebot.consent.marketing,
    functional: Cookiebot.consent.preferences,
    personalization: Cookiebot.consent.marketing
  };
  
  window.updateConsent(consent);
});
```

### Complianz Example

```javascript
document.addEventListener('cmplz_status_change', function(e) {
  const consent = {
    analytics: cmplz_has_consent('statistics'),
    ads: cmplz_has_consent('marketing'),
    functional: cmplz_has_consent('functional'),
    personalization: cmplz_has_consent('marketing')
  };
  
  window.updateConsent(consent);
});
```

### Custom CMP Implementation

```javascript
// Example: User clicks "Accept All" button
document.getElementById('accept-all').addEventListener('click', () => {
  window.updateConsent({
    analytics: true,
    ads: true,
    functional: true,
    personalization: true
  });
  
  // Store preference in cookie/localStorage
  localStorage.setItem('cookie_consent', JSON.stringify({
    analytics: true,
    ads: true,
    timestamp: Date.now()
  }));
});
```

## Step 4: Verify Implementation

### Chrome DevTools Network Tab

1. Open DevTools → Network tab
2. Filter by `collect` (GA4 hits)
3. Look for `gcs` parameter in query string:

```
https://www.google-analytics.com/g/collect?...&gcs=G111
```

**GCS Codes** (consent state):
- `G100` = All denied
- `G110` = Analytics granted, Ads denied
- `G101` = Analytics denied, Ads granted
- `G111` = All granted

### GA4 DebugView

In GA4 → **Configure** → **DebugView**:

1. Enable debug mode: `?gtm_debug=1` in URL
2. Check event parameters:
   - `gcs`: Should show current consent state
   - Events should only fire when consent granted

### GTM Preview Mode

1. In GTM, click **Preview**
2. Enter your site URL
3. Navigate to **Consent** tab
4. Verify:
   - Default state shows all denied
   - After accepting, state updates to granted
   - Tags fire conditionally based on consent

## Step 5: Test Edge Cases

### Test Case 1: User Denies All

**Expected behavior:**
- ✅ GTM loads but tags don't fire
- ✅ No cookies set (except necessary security cookies)
- ✅ No network requests to google-analytics.com or googleadservices.com

**Verify:**
```javascript
// In console
document.cookie.split(';').filter(c => c.includes('_ga'))
// Should return empty if analytics denied
```

### Test Case 2: User Accepts Analytics Only

**Expected behavior:**
- ✅ GA4 tags fire
- ✅ `_ga` cookies set
- ✅ Google Ads tags do NOT fire
- ✅ No `_gcl_` cookies

### Test Case 3: Returning User

**Expected behavior:**
- ✅ Consent preference loaded from localStorage/cookie
- ✅ Consent applied immediately (no banner flash)
- ✅ Tags fire without user re-accepting

**Implementation:**
```javascript
// Load saved consent on page load
const saved = JSON.parse(localStorage.getItem('cookie_consent'));
if (saved) {
  window.updateConsent(saved);
}
```

## Troubleshooting

### Issue: Tags fire before user accepts

**Cause:** Consent Mode script loading after GTM

**Fix:** Move consent script ABOVE GTM snippet

### Issue: GCS parameter shows G100 even after accepting

**Cause:** `updateConsent()` not being called by CMP

**Fix:** Add console.log in CMP callback to verify execution:
```javascript
function OptanonWrapper() {
  console.log('[DEBUG] CMP callback fired');
  window.updateConsent({...});
}
```

### Issue: Tags fire inconsistently

**Cause:** Race condition between CMP and GTM

**Fix:** Increase `wait_for_update` timeout:
```javascript
gtag('consent', 'default', {
  ...
  'wait_for_update': 1000  // Increase from 500ms to 1000ms
});
```

### Issue: Google Ads conversions not tracking

**Cause:** Missing `ad_user_data` or `ad_personalization` consent

**Fix:** Verify both are granted:
```javascript
window.updateConsent({
  analytics: true,
  ads: true  // This grants ad_storage, ad_user_data, AND ad_personalization
});
```

## Advanced: Region-Specific Defaults

```javascript
// Detect user region via IP geolocation API
fetch('https://ipapi.co/json/')
  .then(r => r.json())
  .then(data => {
    const isEEA = ['AT','BE','BG','HR','CY','CZ','DK','EE','FI','FR',
                   'DE','GR','HU','IE','IT','LV','LT','LU','MT','NL',
                   'PL','PT','RO','SK','SI','ES','SE','GB'].includes(data.country);
    
    if (!isEEA) {
      // Non-EEA: Default to granted (no GDPR requirement)
      gtag('consent', 'update', {
        'analytics_storage': 'granted',
        'ad_storage': 'granted',
        'ad_user_data': 'granted',
        'ad_personalization': 'granted'
      });
    }
  });
```

## Production Checklist

- [ ] Consent Mode script loads BEFORE GTM
- [ ] All 6 consent types configured (including v2 additions)
- [ ] CMP integration tested (accept/deny/partial)
- [ ] GCS parameter verified in Network tab
- [ ] Tags fire conditionally based on consent
- [ ] Cookies only set when consent granted
- [ ] Returning user consent persists
- [ ] Google Ads conversions tracking with consent
- [ ] GA4 behavioral modeling enabled
- [ ] Privacy policy updated with consent details

## Resources

- [Google Official Docs](https://developers.google.com/tag-platform/security/guides/consent)
- [Consent Mode v2 Migration Guide](https://support.google.com/analytics/answer/9976101)
- [Simo Ahava's Consent Mode Guide](https://www.simoahava.com/analytics/consent-mode-google-tags/)
- [Complianz Integration](https://complianz.io/consent-mode-v2/)
