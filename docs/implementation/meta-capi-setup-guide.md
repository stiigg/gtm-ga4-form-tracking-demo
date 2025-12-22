# Meta Conversions API (CAPI) Implementation Guide

This guide shows how to implement Meta CAPI alongside GA4 tracking using the patterns from this repository.

## Table of Contents
1. [Overview](#overview)
2. [Quick Start (Browser Only)](#quick-start-browser-only)
3. [Full Setup (Browser + Server)](#full-setup-browser--server)
4. [Testing & Validation](#testing--validation)
5. [Troubleshooting](#troubleshooting)

---

## Overview

### What You're Building

**Single Form Submission → Multiple Platforms:**
- ✓ GA4 (via GTM)
- ✓ Meta Pixel (browser-side)
- ✓ Meta CAPI (server-side via GTM)

**Key Feature: Event Deduplication**
- Same Event ID across all platforms
- Meta counts 1 conversion (not 2)
- No data inflation

### Architecture

```
User Submits Form
      │
      ├─────────→ dataLayer.push() → GTM → GA4
      │                           │
      │                           └──→ Server GTM → Meta CAPI
      │
      └─────────→ fbq('track') → Meta Pixel (browser)
      
      Same Event ID prevents duplicate counting ✓
```

---

## Quick Start (Browser Only)

### Time: 15 minutes
### Cost: FREE
### Good for: Small sites, quick testing

### Step 1: Get Meta Pixel ID

1. Go to [Meta Events Manager](https://business.facebook.com/events_manager2)
2. Click **+ Connect Data Sources** → **Web**
3. Click **Get Started**
4. Name it (e.g., "My Website")
5. Copy your Pixel ID: `123456789012345`

### Step 2: Add Pixel to Your Website

Add this code to the `<head>` section **after** GTM:

```html
<!-- Meta Pixel Code -->
<script>
  !function(f,b,e,v,n,t,s)
  {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
  n.callMethod.apply(n,arguments):n.queue.push(arguments)};
  if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
  n.queue=[];t=b.createElement(e);t.async=!0;
  t.src=v;s=b.getElementsByTagName(e)[0];
  s.parentNode.insertBefore(t,s)}(window, document,'script',
  'https://connect.facebook.net/en_US/fbevents.js');
  
  fbq('init', 'YOUR_PIXEL_ID');  // ← Replace with your Pixel ID
  fbq('track', 'PageView');
</script>
<noscript>
  <img height="1" width="1" style="display:none"
  src="https://www.facebook.com/tr?id=YOUR_PIXEL_ID&ev=PageView&noscript=1"/>
</noscript>
<!-- End Meta Pixel Code -->
```

### Step 3: Update Form Submission Handler

Find your form's JavaScript and enhance it:

```javascript
// EXISTING CODE
window.dataLayer.push({
  event: 'form_submission_success',
  form_id: 'contact_us'
});

// ADD THIS: Generate unique Event ID
const eventId = `${Date.now()}_${Math.random().toString(16).slice(2,10)}`;

// UPDATE: Add event_id to dataLayer
window.dataLayer.push({
  event: 'form_submission_success',
  event_id: eventId,  // ← ADD THIS
  form_id: 'contact_us',
  user_data: {         // ← ADD THIS for Enhanced Matching
    email_address: email,
    first_name: name
  }
});

// ADD THIS: Send to Meta Pixel
if (typeof fbq !== 'undefined') {
  fbq('track', 'Lead', {
    content_name: 'contact_us',
    value: 10.00,
    currency: 'USD'
  }, {
    eventID: eventId  // ← SAME Event ID!
  });
}
```

### Step 4: Test It

1. Install [Meta Pixel Helper](https://chrome.google.com/webstore/detail/meta-pixel-helper) Chrome extension
2. Visit your form page
3. Fill out and submit the form
4. Check Pixel Helper icon - should show "Lead" event
5. Go to Meta Events Manager → **Test Events** tab
6. Submit form again - should see event appear

**✅ Done!** You now have basic browser-side Meta tracking.

---

## Full Setup (Browser + Server)

### Time: 1-2 hours
### Cost: $10-50/month (hosting)
### Good for: E-commerce, serious tracking, ad-blocker resistance

### Why Server-Side?

| Browser Only | Browser + Server |
|--------------|------------------|
| 60-70% accuracy (ad blockers) | 95%+ accuracy |
| Can be blocked | Can't be blocked |
| FREE | $10-50/month |
| 15 min setup | 1-2 hour setup |

### Prerequisites

- ✓ Meta Pixel already installed (from Quick Start)
- ✓ Google Tag Manager web container
- ✓ Access to create server container
- ✓ Google Cloud account OR [Stape.io](https://stape.io) account

### Step 1: Get Meta Access Token

1. Go to Meta Events Manager
2. Select your Pixel → **Settings**
3. Scroll to **Conversions API**
4. Click **Generate Access Token**
5. Copy token (starts with `EAAGm...`)
6. **🔒 IMPORTANT:** Store securely - treat like a password!
7. Note: Token expires every 60 days

### Step 2: Create Server GTM Container

#### Option A: Google Cloud (More Control)

1. Go to [tagmanager.google.com](https://tagmanager.google.com)
2. Click **Create Account** or use existing
3. Click **Add Container**
4. Name: "Your Site - Server"
5. **Target Platform:** Select **Server**
6. Click **Create**
7. Click **Automatically provision tagging server**
8. Choose **Google Cloud Run**
9. Select region closest to your users
10. Click **Provision**
11. Wait 3-5 minutes for deployment
12. Copy the server container URL: `https://gtm-xxxxxx.run.app`

#### Option B: Stape.io (Easier, $10/month)

1. Go to [stape.io](https://stape.io)
2. Sign up (7-day free trial)
3. Click **Create Server Container**
4. Choose plan ($10/month starter)
5. Copy your custom server URL

### Step 3: Configure Web Container to Send to Server

In your **web GTM container**:

#### 3.1 Create Server URL Variable

```
Variable Type: Constant
Name: Server Container URL
Value: https://gtm-xxxxxx.run.app (your server URL)
```

#### 3.2 Update GA4 Configuration Tag

```
Tag Type: GA4 Configuration
Measurement ID: G-XXXXXXXXXX
Server Container URL: {{Server Container URL}}
Transport URL: {{Server Container URL}}

Advanced Settings:
  ✓ Enable sending to server container

Trigger: All Pages
```

#### 3.3 Ensure dataLayer Push Includes Event ID

Your form code should already have this from Quick Start:

```javascript
const eventId = `${Date.now()}_${Math.random().toString(16).slice(2,10)}`;

window.dataLayer.push({
  event: 'form_submission_success',
  event_id: eventId,  // Critical for deduplication!
  form_id: 'contact_us',
  user_data: {
    email_address: email,
    first_name: name
  },
  value: 10.00,
  currency: 'USD'
});
```

### Step 4: Configure Server Container for Meta CAPI

In your **server GTM container**:

#### 4.1 Add Meta CAPI Tag Template

1. Go to **Templates** tab
2. Click **Search Gallery**
3. Search: "Facebook Conversions API"
4. Find official Meta template
5. Click **Add to workspace**

#### 4.2 Create Variables

**Variable 1: Meta Pixel ID**
```
Type: Constant
Name: Meta Pixel ID
Value: 123456789012345 (your Pixel ID)
```

**Variable 2: Meta Access Token**
```
Type: Constant
Name: Meta Access Token
Value: EAAGm0BAA... (your access token)
```

**Variable 3: Test Event Code (for testing only)**
```
Type: Constant
Name: Meta Test Event Code
Value: TEST12345 (from Events Manager)
```

#### 4.3 Create Meta CAPI Tag

```
Tag Type: Facebook Conversions API

API Configuration:
  Pixel ID: {{Meta Pixel ID}}
  API Access Token: {{Meta Access Token}}
  Test Event Code: {{Meta Test Event Code}}  // Remove after testing!

Inherit Event Data:
  ✓ Inherit event data from client
  ✓ Automatically map GA4 events to Meta events

Event Name Mapping:
  form_submission_success → Lead

User Data Parameters (auto-hashed by tag):
  Email: {{user_data.email_address}}
  First Name: {{user_data.first_name}}
  Last Name: {{user_data.last_name}}
  Client IP Address: {{client_ip_address}}  // Auto-populated
  User Agent: {{user_agent}}                // Auto-populated

Custom Data:
  Value: {{value}}
  Currency: {{currency}}
  Content Name: {{form_id}}

Action Source: website

Event ID: {{event_id}}  // ← CRITICAL for deduplication!

Trigger:
  Event Name equals form_submission_success
  AND
  Client Name equals GA4
```

#### 4.4 Test the Server Tag

1. Click **Preview** in Server GTM
2. Enter your website URL
3. Submit a form
4. In Server GTM debugger:
   - Check incoming GA4 event appears
   - Check Meta CAPI tag fires
   - Check no errors

### Step 5: Verify Deduplication Works

1. Go to Meta Events Manager
2. Click **Test Events** tab
3. Make sure Test Event Code is in your server tag
4. Submit a form on your website
5. **You should see:**
   - ✅ Browser event (from Pixel)
   - ✅ Server event (from CAPI)
   - ✅ **Both with same Event ID**
   - ✅ Status shows "Deduplicated" or Meta counts it as 1

**If you see 2 separate events:** Event IDs don't match. Check your code.

### Step 6: Go Live

1. Remove Test Event Code from server tag
2. **Publish** your server container
3. **Publish** your web container
4. Monitor Events Manager for 24-48 hours
5. Check Event Match Quality score (should be > 6.0)

---

## Testing & Validation

### Browser Console Tests

```javascript
// Check dataLayer
dataLayer  // Should show your events

// Check Meta Pixel
fbq('track', 'ViewContent')  // Should fire without errors

// Verify fbq is loaded
typeof fbq  // Should return 'function'
```

### Chrome DevTools Network Tab

1. Open DevTools → Network tab
2. Filter: `facebook.com`
3. Submit form
4. Look for request to `facebook.com/tr`
5. Check payload includes your event

### Meta Pixel Helper Extension

- Install from Chrome Web Store
- Icon turns blue when Pixel fires
- Click icon to see event details
- Check for warnings/errors

### Meta Events Manager Checks

**Test Events Tab:**
- Real-time event monitoring
- Shows event details
- Displays Event Match Quality
- Shows deduplication status

**Overview Tab (after 24 hours):**
- Total events by type
- Event Match Quality trend
- Server vs Browser event ratio
- Attribution data

---

## Troubleshooting

### Events Not Showing in Meta

**Check 1: Pixel ID Correct?**
```javascript
// In browser console:
fbq('getState').pixels  // Should show your Pixel ID
```

**Check 2: Pixel Loaded?**
```javascript
typeof fbq  // Should return 'function', not 'undefined'
```

**Check 3: Event Actually Fired?**
```javascript
// Add console.log to your form handler
console.log('Firing Meta Pixel');
fbq('track', 'Lead', {...});
console.log('Meta Pixel fired');
```

**Check 4: Ad Blocker?**
- Disable ad blockers
- Try incognito mode
- Check Network tab for blocked requests

### Duplicate Events (Counting Twice)

**Problem:** Meta shows 2 Leads for 1 form submission

**Solution:** Event IDs don't match

```javascript
// ❌ BAD: Different IDs
const eventId1 = Date.now();
fbq('track', 'Lead', {}, { eventID: eventId1 });

const eventId2 = Date.now();  // Different!
window.dataLayer.push({ event_id: eventId2 });

// ✓ GOOD: Same ID
const eventId = `${Date.now()}_${Math.random().toString(16).slice(2,10)}`;

fbq('track', 'Lead', {}, { eventID: eventId });
window.dataLayer.push({ event_id: eventId });  // Same!
```

### Low Event Match Quality Score

**Score < 4.0 = Poor matching**

**Fix: Send more user data**

```javascript
// ❌ BAD: Minimal data
window.dataLayer.push({
  event: 'form_submission_success'
});

// ✓ GOOD: Rich user data
window.dataLayer.push({
  event: 'form_submission_success',
  user_data: {
    email_address: email,       // +2.0 points
    first_name: firstName,      // +0.5 points
    last_name: lastName,        // +0.5 points
    phone: phone,               // +1.5 points
    city: city,                 // +0.3 points
    state: state,               // +0.3 points
    zip: zip,                   // +0.3 points
    country: 'US'               // +0.3 points
  }
});
```

### Server Container Not Receiving Events

**Check 1: Web container sends to server?**
- Open Web GTM Preview
- Submit form
- Check if GA4 tag shows "Server Container URL" in config

**Check 2: Server container running?**
- Go to Google Cloud Console
- Check Cloud Run service is "Running"
- Check logs for errors

**Check 3: Server URL correct?**
```javascript
// Should match your server container URL
gtag('config', 'G-XXXXXXXXXX', {
  'server_container_url': 'https://gtm-xxxxxx.run.app'
});
```

---

## Cost Breakdown

### Browser Only (Quick Start)
- Meta Pixel: **FREE**
- Your time: 15 minutes
- **Total: $0**

### Browser + Server (Full Setup)

**Google Cloud (Pay-as-you-go):**
- Low traffic (<50k events/month): $5-15/month
- Medium traffic (50k-200k): $15-35/month
- High traffic (200k+): $35-100+/month

**Stape.io (Fixed pricing):**
- Starter: $10/month (50k events)
- Business: $29/month (200k events)
- Enterprise: Custom pricing

**Your time:**
- Initial setup: 1-2 hours
- Maintenance: ~30 min/month (token refresh)

---

## Next Steps

### After Basic Setup Works

1. **Add more events:**
   - AddToCart
   - InitiateCheckout
   - Purchase
   - ViewContent

2. **Enhance user data:**
   - Phone numbers
   - Addresses
   - Customer IDs

3. **Set up Custom Audiences:**
   - Website visitors
   - Lead submitters
   - High-value customers

4. **Create Lookalike Audiences:**
   - Based on your best leads
   - Expand reach with similar users

5. **Optimize campaigns:**
   - Use Meta's AI with better data
   - Track true ROAS
   - Reduce cost per acquisition

### Resources

- [Official Meta CAPI Docs](https://developers.facebook.com/docs/marketing-api/conversions-api/)
- [GTM Server-Side Guide](https://developers.google.com/tag-platform/tag-manager/server-side)
- [Event Deduplication Guide](https://developers.facebook.com/docs/marketing-api/conversions-api/deduplicate-pixel-and-server-events)
- [This Repo's Demo](../demos/client-side/index-with-meta-capi.html)

---

## Summary

**What you built:**
- Multi-platform form tracking (GA4 + Meta)
- Event deduplication (no double-counting)
- Enhanced user matching
- Ad-blocker resistant tracking (server-side)

**Benefits:**
- 95%+ tracking accuracy (vs 60-70% browser-only)
- Better attribution data
- Lower cost per conversion
- Improved ad performance

**Time investment:**
- Quick Start: 15 minutes
- Full Setup: 1-2 hours
- ROI: Improved campaign performance within 2-3 weeks

Questions? Check the [troubleshooting](#troubleshooting) section or open an issue in this repo.