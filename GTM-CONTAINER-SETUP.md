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

**Questions?** Review [GTM-CONFIG.md](GTM-CONFIG.md) for additional details or see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).