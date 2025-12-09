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
