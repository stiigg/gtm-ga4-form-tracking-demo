# Complete GTM/GA4 Implementation Guide\n
## GTM Container Setup\n
---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# GTM Container Setup Guide

This guide shows how to configure your Google Tag Manager container to work with this demo.

## Prerequisites

Before starting this guide, ensure you have:

- [ ] Google Tag Manager account ([tagmanager.google.com](https://tagmanager.google.com))
- [ ] Google Analytics 4 property created
- [ ] Your GA4 Measurement ID ready (format: `G-XXXXXXXXX`)
  - Find it in GA4: Admin → Data Streams → Select stream → Measurement ID
- [ ] Access to edit GTM container (at least "Edit" permission)
- [ ] Basic understanding of dataLayer and event tracking

**Example IDs:**
- ✅ GA4 Measurement ID: `G-S9SRF7GGHW` (this is YOUR actual ID from the screenshot)
- ✅ GTM Container ID: `GTM-XXXXXXX` (you need to find yours in GTM interface)
- ❌ **Don't use** `GTM-N4B8K7P` - this is a placeholder!

---

## Step 1: Create GTM Container

1. Go to [tagmanager.google.com](https://tagmanager.google.com)
2. Click "Create Account" (if new) or select existing account
3. Click "Create Container"
4. Container name: `gtm-ga4-form-tracking-demo`
5. Target platform: **Web**
6. Click "Create"

**Copy the container ID (GTM-XXXXXXX)** - you'll need this for HTML files.

---

## Step 2: Install Container Code

Replace `GTM-XXXXXXX` in both HTML files with your actual container ID:

- `index.html` (in `<head>` and after `<body>` tag)
- `ecommerce.html` (in `<head>` and after `<body>` tag)

---

## Step 3: Create Data Layer Variables

In GTM, go to **Variables** → **User-Defined Variables** → **New**

Create these Data Layer Variables:

### Form Tracking Variables

| Variable Name | Variable Type | Data Layer Variable Name |
|---------------|---------------|-------------------------|
| DLV - event | Data Layer Variable | `event` |
| DLV - form_id | Data Layer Variable | `form_id` |
| DLV - form_type | Data Layer Variable | `form_type` |
| DLV - form_location | Data Layer Variable | `form_location` |
| DLV - form_topic | Data Layer Variable | `form_fields.topic` |
| DLV - form_plan | Data Layer Variable | `form_fields.plan` |

**Configuration for each:**
1. Variable Type: **Data Layer Variable**
2. Data Layer Variable Name: (from table above)
3. Data Layer Version: **Version 2**
4. Set Default Value: `undefined` (optional but recommended)

### E-commerce Variables

| Variable Name | Variable Type | Data Layer Variable Name |
|---------------|---------------|-------------------------|
| DLV - ecommerce | Data Layer Variable | `ecommerce` |
| DLV - ecommerce.items | Data Layer Variable | `ecommerce.items` |
| DLV - ecommerce.value | Data Layer Variable | `ecommerce.value` |
| DLV - ecommerce.currency | Data Layer Variable | `ecommerce.currency` |
| DLV - ecommerce.transaction_id | Data Layer Variable | `ecommerce.transaction_id` |
| DLV - ecommerce.item_list_id | Data Layer Variable | `ecommerce.item_list_id` |
| DLV - ecommerce.item_list_name | Data Layer Variable | `ecommerce.item_list_name` |

---

## Step 4: Create Custom Event Triggers

In GTM, go to **Triggers** → **New**

### Trigger 1: Form Submission Success

- **Trigger Name:** `CE - form_submission_success`
- **Trigger Type:** Custom Event
- **Event name:** `form_submission_success`
- **This trigger fires on:** Some Custom Events
- **Condition:** `DLV - form_id` equals `contact_us`

### Trigger 2: View Item List

- **Trigger Name:** `CE - view_item_list`
- **Trigger Type:** Custom Event
- **Event name:** `view_item_list`
- **This trigger fires on:** All Custom Events

### Trigger 3: View Item

- **Trigger Name:** `CE - view_item`
- **Trigger Type:** Custom Event
- **Event name:** `view_item`
- **This trigger fires on:** All Custom Events

### Trigger 4: Add to Cart

- **Trigger Name:** `CE - add_to_cart`
- **Trigger Type:** Custom Event
- **Event name:** `add_to_cart`
- **This trigger fires on:** All Custom Events

### Trigger 5: Begin Checkout

- **Trigger Name:** `CE - begin_checkout`
- **Trigger Type:** Custom Event
- **Event name:** `begin_checkout`
- **This trigger fires on:** All Custom Events

### Trigger 6: Purchase

- **Trigger Name:** `CE - purchase`
- **Trigger Type:** Custom Event
- **Event name:** `purchase`
- **This trigger fires on:** All Custom Events

---

## Step 5: Create GA4 Configuration Tag

This tag initializes GA4 on every page and must fire before any event tags.

### Method 1: Using Google Tag (Recommended - Newer Format)

1. Go to **Tags** → **New**
2. **Tag Name:** `Google Tag - GA4 Configuration`
3. **Tag Type:** Click **Tag Configuration** → Search "Google Tag" → Select **Google Tag**
4. **Tag ID:** `G-S9SRF7GGHW` (your actual Measurement ID)
   - ⚠️ **Important**: Replace with YOUR actual GA4 Measurement ID
   - Format must be `G-XXXXXXXXX` (starts with G-, not GT-)
5. **Configuration Settings (Optional):**
   - Enable "Send an event when this configuration loads" ✅ (recommended)
   - Add **Fields to Set** (optional):
     - Field Name: `send_page_view` → Value: `true`
     - Field Name: `anonymize_ip` → Value: `true` (for GDPR compliance)
6. **Triggering:** Select **All Pages - Page View**
7. **Tag firing options:** "Once per page" (recommended)
8. Click **Save**

### Method 2: Using GA4 Configuration (Legacy Format)

**If "Google Tag" is not available in your GTM, use this:**

1. Go to **Tags** → **New**
2. **Tag Name:** `GA4 - Configuration`
3. **Tag Type:** Google Analytics: GA4 Configuration
4. **Measurement ID:** `G-S9SRF7GGHW`
5. Enable: "Send a page view event when this configuration loads" ✅
6. **Triggering:** All Pages
7. **Save**

### Verification

After creating the tag:
1. Click **Preview**
2. Load your demo page
3. Verify in Tag Assistant:
   - Tag fires on page load
   - Shows as "Succeeded" status
   - Measurement ID displays correctly

**Common Errors:**
- ❌ "Tag not firing" → Check trigger is set to "All Pages"
- ❌ "Invalid Measurement ID" → Verify format is `G-XXXXXXXXX` (no spaces, correct ID)
- ❌ "Multiple configuration tags" → Only one configuration tag should exist per GA4 property

---

## Step 6: Create GA4 Event Tags

### Tag 1: Generate Lead (Form Submission)

1. **Tag Name:** `GA4 - Event - generate_lead`
2. **Tag Type:** Google Analytics: GA4 Event
3. **Configuration Tag:** Select `GA4 - Configuration` (from previous step)
4. **Event Name:** `generate_lead`
5. **Event Parameters:**
   - **Parameter Name:** `form_id` → **Value:** `{{DLV - form_id}}`
   - **Parameter Name:** `form_type` → **Value:** `{{DLV - form_type}}`
   - **Parameter Name:** `form_location` → **Value:** `{{DLV - form_location}}`
   - **Parameter Name:** `form_topic` → **Value:** `{{DLV - form_topic}}`
   - **Parameter Name:** `form_plan` → **Value:** `{{DLV - form_plan}}`
6. **Triggering:** `CE - form_submission_success`
7. **Save**

### Tag 2: View Item List

1. **Tag Name:** `GA4 - Event - view_item_list`
2. **Tag Type:** Google Analytics: GA4 Event
3. **Configuration Tag:** `GA4 - Configuration`
4. **Event Name:** `view_item_list`
5. **Event Parameters:**
   - **Parameter Name:** `items` → **Value:** `{{DLV - ecommerce.items}}`
   - **Parameter Name:** `item_list_id` → **Value:** `{{DLV - ecommerce.item_list_id}}`
   - **Parameter Name:** `item_list_name` → **Value:** `{{DLV - ecommerce.item_list_name}}`
6. **Triggering:** `CE - view_item_list`
7. **Save**

### Tag 3: View Item

1. **Tag Name:** `GA4 - Event - view_item`
2. **Tag Type:** Google Analytics: GA4 Event
3. **Configuration Tag:** `GA4 - Configuration`
4. **Event Name:** `view_item`
5. **Event Parameters:**
   - **Parameter Name:** `currency` → **Value:** `{{DLV - ecommerce.currency}}`
   - **Parameter Name:** `value` → **Value:** `{{DLV - ecommerce.value}}`
   - **Parameter Name:** `items` → **Value:** `{{DLV - ecommerce.items}}`
6. **Triggering:** `CE - view_item`
7. **Save**

### Tag 4: Add to Cart

1. **Tag Name:** `GA4 - Event - add_to_cart`
2. **Tag Type:** Google Analytics: GA4 Event
3. **Configuration Tag:** `GA4 - Configuration`
4. **Event Name:** `add_to_cart`
5. **Event Parameters:**
   - **Parameter Name:** `currency` → **Value:** `{{DLV - ecommerce.currency}}`
   - **Parameter Name:** `value` → **Value:** `{{DLV - ecommerce.value}}`
   - **Parameter Name:** `items` → **Value:** `{{DLV - ecommerce.items}}`
6. **Triggering:** `CE - add_to_cart`
7. **Save**

### Tag 5: Begin Checkout

1. **Tag Name:** `GA4 - Event - begin_checkout`
2. **Tag Type:** Google Analytics: GA4 Event
3. **Configuration Tag:** `GA4 - Configuration`
4. **Event Name:** `begin_checkout`
5. **Event Parameters:**
   - **Parameter Name:** `currency` → **Value:** `{{DLV - ecommerce.currency}}`
   - **Parameter Name:** `value` → **Value:** `{{DLV - ecommerce.value}}`
   - **Parameter Name:** `items` → **Value:** `{{DLV - ecommerce.items}}`
6. **Triggering:** `CE - begin_checkout`
7. **Save**

### Tag 6: Purchase

1. **Tag Name:** `GA4 - Event - purchase`
2. **Tag Type:** Google Analytics: GA4 Event
3. **Configuration Tag:** `GA4 - Configuration`
4. **Event Name:** `purchase`
5. **Event Parameters:**
   - **Parameter Name:** `transaction_id` → **Value:** `{{DLV - ecommerce.transaction_id}}`
   - **Parameter Name:** `currency` → **Value:** `{{DLV - ecommerce.currency}}`
   - **Parameter Name:** `value` → **Value:** `{{DLV - ecommerce.value}}`
   - **Parameter Name:** `items` → **Value:** `{{DLV - ecommerce.items}}`
6. **Triggering:** `CE - purchase`
7. **Save**

---

## Step 7: Test in Preview Mode

1. In GTM, click **Preview** (top right)
2. Enter your demo URL: `https://stiigg.github.io/gtm-ga4-form-tracking-demo/`
3. Click **Connect**

### Testing Checklist

**Form Tracking Test:**
- [ ] Load index.html
- [ ] Fill out "Good" form with valid data
- [ ] Submit form
- [ ] Verify in GTM Preview:
  - [ ] `form_submission_success` event appears
  - [ ] Tag `GA4 - Event - generate_lead` fires
  - [ ] Variables show correct values (topic, plan)
- [ ] Check GA4 DebugView (Admin → DebugView):
  - [ ] `generate_lead` event appears
  - [ ] Parameters: form_id, form_topic, form_plan visible

**E-commerce Test:**
- [ ] Load ecommerce.html
- [ ] Verify `view_item_list` fires on page load
- [ ] Click a product → verify `view_item` fires
- [ ] Add to cart → verify `add_to_cart` fires
- [ ] Begin checkout → verify `begin_checkout` fires
- [ ] Complete purchase → verify `purchase` fires with transaction_id

---

## Step 8: Publish Container

1. In GTM, click **Submit** (top right)
2. **Version Name:** `v1 - Initial GTM setup with form + ecommerce tracking`
3. **Version Description:**
   ```
   - Added GA4 configuration tag
   - Implemented form tracking (generate_lead)
   - Implemented e-commerce events (view_item_list, view_item, add_to_cart, begin_checkout, purchase)
   - Created all required data layer variables and triggers
   ```
4. Click **Publish**

---

## Troubleshooting

### Issue: Tags not firing

**Check:**
1. GTM container code installed correctly in HTML
2. dataLayer pushes happening (check browser console)
3. Triggers configured with correct event names
4. Variables resolving to actual values (not `undefined`)

### Issue: GA4 DebugView shows no events

**Check:**
1. GA4 Configuration tag fires on All Pages
2. Measurement ID is correct in configuration tag
3. Browser console shows no GTM errors
4. Ad blockers disabled (they block GA4 requests)

### Issue: Custom parameters not visible in GA4

**Solution:**
1. Go to GA4 → Admin → Custom definitions
2. Create custom dimensions for:
   - `form_id` (event-scoped)
   - `form_topic` (event-scoped)
   - `form_plan` (event-scoped)
3. Wait 24-48 hours for data to populate

---

## GTM Container Export

For quick setup, import the pre-configured container:

1. Download `gtm-container-export.json` from this repository (coming soon)
2. In GTM, go to Admin → Import Container
3. Choose file → `gtm-container-export.json`
4. Choose workspace: **New** or **Existing**
5. Import option: **Merge** (recommended) or **Overwrite**
6. Click **Confirm**
7. **Important:** Update GA4 Measurement ID in the configuration tag
8. Preview and test
9. Publish

---

## Next Steps

- [ ] Set up GA4 custom dimensions
- [ ] Enable BigQuery export (see [sql/README.md](sql/README.md))
- [ ] Create Looker Studio dashboard (see [LOOKER-STUDIO.md](LOOKER-STUDIO.md))
- [ ] Configure conversion events in GA4

---

**Questions?** Review [GTM-CONFIG.md](GTM-CONFIG.md) for additional details or see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).\n## GA4 Property Configuration\n
---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Configuration Guide - Required Setup

This guide shows you how to configure the demo with your own Google Tag Manager and Google Analytics 4 credentials.

## Why Configuration is Needed

This repository uses placeholder IDs for security and portability. The demo **will not work** until you replace these with your actual account credentials.

---

## Step 1: Find Your GTM Container ID

### What is a GTM Container ID?

- **Format:** `GTM-XXXXXXX` (always starts with "GTM-")
- **Purpose:** Loads your specific GTM container on the website
- **Where it goes:** HTML files (both `index.html` and `ecommerce.html`)

### How to Find It

**Method 1: GTM Interface Header**
1. Log into [Google Tag Manager](https://tagmanager.google.com)
2. Select your container
3. Look at the **top-right corner** of the screen
4. You'll see your Container ID next to the "Preview" and "Submit" buttons

**Method 2: Install Code**
1. In GTM, click on your Container ID (top-right)
2. A modal appears showing installation code
3. The Container ID appears in the code: `GTM-XXXXXXX`

**Method 3: Admin Settings**
1. Click **Admin** (top navigation)
2. Look in the **Container** column
3. Container ID shown next to container name

### Example

```
Your Container ID might look like:
✅ GTM-ABC1234
✅ GTM-WXYZ789
✅ GTM-NNS86ML (this is what's currently in the demo)
```

---

## Step 2: Find Your GA4 Measurement ID

### What is a GA4 Measurement ID?

- **Format:** `G-XXXXXXXXX` (always starts with "G-")
- **Purpose:** Identifies which GA4 property receives the data
- **Where it goes:** Inside GTM's Google Tag configuration

### How to Find It

1. Log into [Google Analytics](https://analytics.google.com)
2. Click **Admin** (bottom-left gear icon)
3. In the **Property** column, click **Data Streams**
4. Click on your web data stream
5. Copy the **Measurement ID** (format: `G-XXXXXXXXX`)

### From Your Screenshot

According to your Tag Manager screenshot, your Measurement ID is:
```
G-S9SRF7GGHW
```

You also have a Google Tag ID:
```
GT-NNS86MLN
```

**Important:** Use the `G-` ID (Measurement ID), not the `GT-` ID (Google Tag ID), in the GTM configuration tag.

---

## Step 3: Update Files with Your IDs

### Files to Update

| File | What to Change | How Many Times |
|------|---------------|----------------|
| `index.html` | Replace `GTM-NNS86ML` with your Container ID | 2 locations |
| `ecommerce.html` | Replace `GTM-NNS86ML` with your Container ID | 2 locations |
| `gtm-container-export.json` | Replace `G-XXXXXXXXX` with `G-S9SRF7GGHW` | 1 location |

### Update index.html

**Location 1 - Line ~11 (head section):**
```
// FIND:
})(window,document,'script','dataLayer','GTM-NNS86ML');</script>

// REPLACE WITH:
})(window,document,'script','dataLayer','GTM-ABC1234');</script>
// ^^^ Use YOUR actual Container ID
```

**Location 2 - Line ~167 (body noscript):**
```
<!-- FIND: -->
<noscript><iframe src="https://www.googletagmanager.com/ns.html?id=GTM-NNS86ML"

<!-- REPLACE WITH: -->
<noscript><iframe src="https://www.googletagmanager.com/ns.html?id=GTM-ABC1234"
```

### Update ecommerce.html

**Same changes as `index.html`:**
- Replace `GTM-NNS86ML` in the `<head>` section
- Replace `GTM-NNS86ML` in the `<body>` noscript section

### Update gtm-container-export.json

**Find line ~26:**
```
{
  "type": "TEMPLATE",
  "key": "measurementId",
  "value": "G-XXXXXXXXX"  // ← CHANGE THIS
}
```

**Replace with:**
```
{
  "type": "TEMPLATE",
  "key": "measurementId",
  "value": "G-S9SRF7GGHW"  // ← Your actual Measurement ID
}
```

---

## Step 4: Import Container to GTM

After updating `gtm-container-export.json`:

1. Go to [tagmanager.google.com](https://tagmanager.google.com)
2. Select your account
3. Click **Admin** → **Import Container**
4. Choose file: `gtm-container-export.json`
5. Choose workspace: **New** (recommended)
6. Import option: **Merge** or **Overwrite**
7. Click **Confirm**

### Verify Import

After import:
- [ ] Check **Variables** tab → Should see 12+ variables
- [ ] Check **Triggers** tab → Should see 6+ triggers
- [ ] Check **Tags** tab → Should see 7 tags
- [ ] Open **"Google Tag - GA4 Configuration"** tag
- [ ] Verify Measurement ID is `G-S9SRF7GGHW`

---

## Step 5: Test Configuration

### Test 1: Preview Mode

1. In GTM, click **Preview**
2. Enter: `http://localhost:8000` (or your test URL)
3. Click **Connect**
4. Tag Assistant opens

**Verify:**
- ✅ Container loads successfully
- ✅ Google Tag fires on page view
- ✅ Submit form → `generate_lead` event fires
- ✅ Variables populate with actual values (not "undefined")

### Test 2: GA4 DebugView

1. Open GA4: [analytics.google.com](https://analytics.google.com)
2. Go to **Admin** → **DebugView**
3. Leave this window open
4. In another tab, test your demo site
5. Within 30 seconds, events should appear in DebugView

**Expected events:**
- `page_view`
- `generate_lead` (after form submission)
- `add_to_cart`, `purchase` (e-commerce demo)

### Test 3: Network Tab

1. Open demo site
2. Press F12 (DevTools)
3. Go to **Network** tab
4. Filter by "collect"
5. Submit a form
6. Look for requests to `google-analytics.com/g/collect`
7. Check URL contains: `tid=G-S9SRF7GGHW`

---

## Step 6: Publish Container

**Only publish after ALL tests pass!**

1. In GTM, click **Submit** (top-right)
2. **Version Name:** `v1.0 - Production release`
3. **Version Description:**
   ```
   Initial production configuration:
   - GA4 Measurement ID: G-S9SRF7GGHW
   - Form tracking (generate_lead) configured
   - E-commerce tracking (5 events) configured
   - All tests passed in Preview mode
   - Verified in GA4 DebugView
   ```
4. Click **Publish**

---

## Verification Checklist

Before considering setup complete:

### Files Updated
- [ ] `index.html` - GTM Container ID updated (2 locations)
- [ ] `ecommerce.html` - GTM Container ID updated (2 locations)
- [ ] `gtm-container-export.json` - GA4 Measurement ID updated

### GTM Container
- [ ] Container imported successfully
- [ ] GA4 Measurement ID is `G-S9SRF7GGHW`
- [ ] Google Tag fires on All Pages
- [ ] Form event tags configured
- [ ] E-commerce event tags configured
- [ ] Container published (not just saved)

### Testing
- [ ] Preview mode connects successfully
- [ ] All expected tags fire in Tag Assistant
- [ ] Events appear in GA4 DebugView
- [ ] Network tab shows requests to GA4
- [ ] No JavaScript errors in console

### Documentation
- [ ] Updated README.md with your specific IDs (optional)
- [ ] Noted configuration date
- [ ] Screenshot of working DebugView (optional but recommended)

---

## Common Issues

### "Container failed to load"
- **Cause:** Wrong Container ID in HTML
- **Fix:** Double-check Container ID matches exactly (case-sensitive)

### "No tags firing"
- **Cause:** Container not published
- **Fix:** Click Submit → Publish in GTM

### "Events not in GA4"
- **Cause:** Wrong Measurement ID
- **Fix:** Verify `G-S9SRF7GGHW` in Google Tag configuration

### "GTM Preview won't connect"
- **Cause:** Browser extensions blocking
- **Fix:** Disable ad blockers, try incognito mode

---

## Need Help?

- Review [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Check [GTM-CONTAINER-SETUP.md](GTM-CONTAINER-SETUP.md) for manual setup
- Verify [GTM-CONFIG.md](GTM-CONFIG.md) for configuration details

**Support:**
- GitHub Issues: [Report a problem](https://github.com/stiigg/gtm-ga4-form-tracking-demo/issues)
- GTM Community: [Tag Manager Help Forum](https://support.google.com/tagmanager/community)
---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# GTM Configuration Guide

> **⚠️ IMPORTANT:** This demo now uses **Google Tag Manager** (not gtag.js). 
> Follow [GTM-CONTAINER-SETUP.md](GTM-CONTAINER-SETUP.md) for step-by-step container setup.
> 
> **Quick Start:** Import `gtm-container-export.json` to skip manual configuration.

---

This document provides the GTM (Google Tag Manager) configuration needed to capture the dataLayer events from this demo.

## Data Layer Variables

Create these Data Layer Variables in GTM to read the pushed data:

### Form Tracking Variables

| Variable Name | Data Layer Variable Name | Version |
|---------------|-------------------------|----------|
| DLV - form_id | `form_id` | Version 2 |
| DLV - form_type | `form_type` | Version 2 |
| DLV - form_location | `form_location` | Version 2 |
| DLV - form_topic | `form_fields.topic` | Version 2 |
| DLV - form_plan | `form_fields.plan` | Version 2 |

### E-commerce Variables

| Variable Name | Data Layer Variable Name | Version |
|---------------|-------------------------|----------|
| DLV - ecommerce.items | `ecommerce.items` | Version 2 |
| DLV - ecommerce.value | `ecommerce.value` | Version 2 |
| DLV - ecommerce.currency | `ecommerce.currency` | Version 2 |
| DLV - ecommerce.transaction_id | `ecommerce.transaction_id` | Version 2 |

## Custom Event Triggers

### Form Submission Trigger

- **Trigger Name:** CE - form_submission_success
- **Trigger Type:** Custom Event
- **Event Name:** `form_submission_success`
- **Fires On:** Some Custom Events where `form_id` equals `contact_us`

### E-commerce Triggers

| Trigger Name | Event Name | Use Case |
|-------------|------------|----------|
| CE - view_item_list | `view_item_list` | Product listing page |
| CE - view_item | `view_item` | Product detail click |
| CE - add_to_cart | `add_to_cart` | Add item to cart |
| CE - begin_checkout | `begin_checkout` | Start checkout |
| CE - purchase | `purchase` | Complete purchase |

## GA4 Event Tags

### Lead Form Tag

- **Tag Type:** Google Analytics: GA4 Event
- **Event Name:** `generate_lead`
- **Parameters:**
  - `form_id` → {{DLV - form_id}}
  - `form_type` → {{DLV - form_type}}
  - `form_location` → {{DLV - form_location}}
  - `form_topic` → {{DLV - form_topic}}
  - `form_plan` → {{DLV - form_plan}}
- **Trigger:** CE - form_submission_success

### E-commerce Tags

For each e-commerce event, create a GA4 Event tag:

```
Tag Type: Google Analytics: GA4 Event
Configuration Tag: Your GA4 Config
Event Name: [view_item_list | view_item | add_to_cart | begin_checkout | purchase]
Parameters:
  - items → {{DLV - ecommerce.items}}
  - value → {{DLV - ecommerce.value}}
  - currency → {{DLV - ecommerce.currency}}
  - transaction_id → {{DLV - ecommerce.transaction_id}} (purchase only)
Trigger: Corresponding custom event trigger
```

## GA4 Configuration

### Custom Dimensions

| Dimension Name | Scope | Event Parameter |
|----------------|-------|-----------------|
| form_id | Event | form_id |
| form_type | Event | form_type |
| form_location | Event | form_location |
| form_topic | Event | form_topic |
| form_plan | Event | form_plan |

### Suggested GA4 Conversions

Mark these as conversions in GA4:
- `generate_lead`
- `purchase`
- (Optional) `begin_checkout`

## Validation Tips

1. Use GTM Preview mode to verify triggers fire and variables resolve
2. Use GA4 DebugView to confirm events and parameters arrive
3. Avoid high-cardinality fields (e.g., free-text message bodies)
\n## Cross-Domain Tracking\n
---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Cross-Domain Tracking Setup Guide

## When You Need This
- Main store on `shop.example.com`, checkout on `checkout.example.com`
- Multiple brand sites sharing a central cart
- Third-party payment processors (Stripe, PayPal) returning to confirmation page
- Affiliate tracking across partner domains

## GTM Configuration Steps

### 1. GA4 Configuration Tag Settings
```
Fields to Set:
- linker → domains: checkout.example.com,payment.example.com
- cookie_domain: auto
- cookie_flags: samesite=none;secure
```

### 2. Create Linker Variable
**Variable Type**: GTM Variable - URL (Auto-Link Domains)
**Name**: `Cross-Domain Linker`
**Domains**: `checkout.example.com`, `payment.example.com`
**Use Hash as Delimiter**: ✓ Checked
**Decorate Forms**: ✓ Checked

### 3. Validation Checklist
- [ ] GA4 debug mode shows consistent `user_id` across domains
- [ ] URL contains `_gl=` parameter when navigating between domains
- [ ] Cookie `_ga` has same value on both domains (check DevTools → Application → Cookies)
- [ ] GTM Preview Mode shows Configuration tag firing on both domains
- [ ] User journey in GA4 Realtime report doesn't show separate sessions

## Common Failure Modes

### Issue 1: _gl Parameter Stripped
**Symptoms**: Parameter visible in network tab but removed before page load
**Causes**:
- Payment processor sanitizes URL parameters
- Server-side redirects without preserving query strings
- Ad blockers removing tracking parameters

**Solution**: 
- Contact payment processor for allowlist request
- Use POST method with hidden form field for `_gl` value
- Implement server-side cookie reading/writing

### Issue 2: Cookies Not Shared
**Symptoms**: Different `_ga` cookie values on subdomains
**Cause**: `cookie_domain` not set to parent domain

**Solution**:
```
// GTM Custom HTML tag - Fire on All Pages
<script>
gtag('config', 'G-XXXXXXXXXX', {
  'cookie_domain': '.example.com',  // Note the leading dot
  'cookie_flags': 'SameSite=None;Secure'
});
</script>
```

### Issue 3: Session Break on Protocol Change
**Symptoms**: HTTP → HTTPS transition creates new session
**Solution**: Ensure both domains use HTTPS exclusively

## Testing Methodology

### Manual Test Flow
1. Open GTM Preview on Domain A
2. Add product to cart
3. Note `_ga` cookie value (DevTools → Application)
4. Click checkout (navigates to Domain B)
5. Verify `_gl` parameter in URL
6. Check `_ga` cookie matches Domain A value
7. Complete purchase
8. Check GA4 Realtime: should show single user journey

### Automated Testing Script
See `/qa-checklists/cross-domain-test.js` for Puppeteer script
