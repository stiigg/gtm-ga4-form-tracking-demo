# GTM/GA4 Tracking Demo

Complete demo site showing GTM (Google Tag Manager) and GA4 (Google Analytics 4) tracking implementations with dataLayer push examples.

## Live Demos

| Demo | Description | Link |
|------|-------------|------|
| Form Tracking | Good vs Bad form submission tracking | [View Demo](https://stiigg.github.io/gtm-ga4-form-tracking-demo/) |
| E-commerce | Full e-commerce funnel tracking | [View Demo](https://stiigg.github.io/gtm-ga4-form-tracking-demo/ecommerce.html) |

## ⚠️ Important: Configuration Required

This demo repository uses placeholder IDs. **You must configure it with your own credentials before it will work:**

1. **Get your GTM Container ID**: 
   - Go to [tagmanager.google.com](https://tagmanager.google.com)
   - Find your Container ID (format: `GTM-XXXXXXX`)
   - Note: This repo currently has `GTM-NNS86ML` as a placeholder

2. **Get your GA4 Measurement ID**:
   - Go to Google Analytics 4
   - Admin → Data Streams → Select your stream
   - Copy Measurement ID (format: `G-XXXXXXXXX`)

3. **Update files** (see Quick Start below for detailed steps)

**The demo will NOT work until you complete these configuration steps.**

## Features

### Form Tracking Demo
- **GOOD Implementation**: Fires only on success, anti-double-fire guard, clean dataLayer push
- **BAD Implementation**: Fires on click, no validation, high cardinality fields
- Live dataLayer event visualization
- Uses GA4 recommended `generate_lead` event

### E-commerce Demo
- `view_item_list` - Product listing view
- `view_item` - Product detail click
- `add_to_cart` - Add item to cart
- `begin_checkout` - Start checkout process
- `purchase` - Complete purchase with transaction ID

## Documentation

- **[🔧 Configuration Guide](CONFIGURATION.md)** - **START HERE: Required setup to make demo work**
- [GTM Configuration Guide](GTM-CONFIG.md) - Variables, triggers, and tags setup
- [Upwork Training Guide](UPWORK-TRAINING.md) - Complete skills guide for GTM/GA4 freelancing
- [GTM Container Setup](GTM-CONTAINER-SETUP.md) - Step-by-step container build
- [Looker Studio Dashboard Guide](LOOKER-STUDIO.md) - Build dashboards on GA4 BigQuery export
- [Troubleshooting Guide](TROUBLESHOOTING.md) - Debug GTM/GA4/BigQuery/Looker Studio

## dataLayer Structure

### Form Events
```javascript
window.dataLayer.push({
  event: 'form_submission_success',
  form_id: 'contact_us',
  form_type: 'lead',
  form_location: 'demo_page',
  form_fields: {
    topic: 'sales',
    plan: 'pro'
  }
});
```

### E-commerce Events
```javascript
window.dataLayer.push({
  event: 'purchase',
  ecommerce: {
    transaction_id: 'TXN123456',
    currency: 'USD',
    value: 99.00,
    items: [{
      item_id: 'SKU001',
      item_name: 'Analytics Pro',
      price: 99.00,
      quantity: 1
    }]
  }
});
```

## Tech Stack

- Pure HTML/CSS/JavaScript (no frameworks)
- **Google Tag Manager (GTM)** for tag management
- **GA4** for analytics via GTM
- dataLayer-based event tracking
- GitHub Pages hosting

## Implementation Details

### Architecture

```
┌──────────────┐
│  Website     │
│  HTML/JS     │
└──────┬───────┘
       │ dataLayer.push()
       ↓
┌──────────────┐
│    GTM       │ ← Manages all tags
│  Container   │
└──────┬───────┘
       │ Sends events
       ↓
┌──────────────┐
│     GA4      │ ← Analytics
│  Property    │
└──────┬───────┘
       │ Daily export (overnight)
       ↓
┌──────────────┐
│  BigQuery    │ ← Data warehouse
│   Dataset    │
└──────┬───────┘
       │ SQL queries
       ↓
┌──────────────┐
│Looker Studio │ ← Dashboards
│   Reports    │
└──────────────┘
```

### What Changed from gtag.js to GTM

**Before (gtag.js):**
- Direct GA4 implementation via gtag.js library
- All tracking logic in HTML files
- Required code changes for any modifications
- Limited to Google Analytics only

**After (GTM):**
- True Google Tag Manager implementation
- dataLayer-based event tracking (GTM-independent)
- No-code changes needed after initial setup
- Extensible to Facebook Pixel, LinkedIn tags, etc.
- Professional debugging tools (GTM Preview Mode)

### Key Benefits

✅ **No-code tag management** - Add/modify tracking without developer
✅ **Version control** - GTM tracks all changes with rollback capability
✅ **Multi-vendor support** - Easy to add Facebook, LinkedIn, HubSpot tags
✅ **Better debugging** - GTM Preview shows exactly what fired and why
✅ **Team collaboration** - Multiple users can work in GTM with permissions
✅ **Professional standard** - Clients expect GTM, not gtag.js

## Quick Start

### Prerequisites

- [ ] Google Tag Manager account ([sign up here](https://tagmanager.google.com))
- [ ] Google Analytics 4 property ([create here](https://analytics.google.com))
- [ ] Your GTM Container ID (format: `GTM-XXXXXXX`)
- [ ] Your GA4 Measurement ID (format: `G-XXXXXXXXX`)

### 1. Clone Repository
```
git clone https://github.com/stiigg/gtm-ga4-form-tracking-demo.git
cd gtm-ga4-form-tracking-demo
```

### 2. Option A: Import Pre-configured Container (Recommended)

**Step 2.1: Import Container**
1. Go to [tagmanager.google.com](https://tagmanager.google.com)
2. Select your account or create new
3. Click **Admin** → **Import Container**
4. Choose file: `gtm-container-export.json` from this repo
5. Choose workspace: **New** (recommended)
6. Import option: **Overwrite** (if new container) or **Merge**
7. Click **Confirm**

**Step 2.2: Update GA4 Measurement ID in GTM**
1. In GTM, go to **Tags**
2. Click on `GA4 - Configuration`
3. Change Measurement ID from `G-XXXXXXXXX` to **your actual GA4 ID**
4. Click **Save**

**Step 2.3: Get Your Container ID**
- Look at top-right corner of GTM interface
- Copy the Container ID (format: `GTM-XXXXXXX`)

### 3. Update HTML Files with Your Container ID

**You need to update 4 locations total (2 per file):**

**In `index.html`:**
1. Line ~11 (head section): Replace `GTM-NNS86ML` with your Container ID
2. Line ~167 (body noscript): Replace `GTM-NNS86ML` with your Container ID

**In `ecommerce.html`:**
1. Line ~11 (head section): Replace `GTM-NNS86ML` with your Container ID
2. Line ~17 (body noscript): Replace `GTM-NNS86ML` with your Container ID

**Quick find/replace:**
```
# Use your code editor's find/replace feature
Find: GTM-NNS86ML
Replace: GTM-YOUR_REAL_ID
```

### 4. Test Locally

```
# Method 1: Python (if Python installed)
python3 -m http.server 8000

# Method 2: Node.js
npx serve

# Method 3: PHP
php -S localhost:8000
```

Open in browser: `http://localhost:8000`

### 5. Enable GTM Preview Mode

1. In GTM, click **Preview** button (top-right)
2. Enter your test URL: `http://localhost:8000`
3. Click **Connect**
4. GTM Tag Assistant opens in new window

**Test Form Tracking:**
- Fill out the "Good" form
- Submit
- Verify in Tag Assistant:
  - ✅ Event `form_submission_success` fires
  - ✅ Tag `GA4 - Event - generate_lead` shows under "Tags Fired"
  - ✅ Variables populate with correct values

**Test E-commerce:**
- Navigate to `ecommerce.html`
- Add items to cart
- Complete purchase
- Verify all e-commerce events fire

### 6. Verify in GA4 DebugView

1. Open GA4: [analytics.google.com](https://analytics.google.com)
2. Go to **Admin** → **DebugView**
3. Submit forms on your demo site
4. Events should appear within 10-30 seconds:
   - `page_view`
   - `generate_lead` (form submission)
   - `add_to_cart`, `purchase` (e-commerce)

### 7. Publish GTM Container

**Only publish after successful testing!**

1. In GTM, click **Submit** (top-right)
2. **Version Name**: "v1.0 - Initial production release"
3. **Version Description**: 
   ```
   - GTM container for form and e-commerce tracking
   - Connected to GA4 property [YOUR_MEASUREMENT_ID]
   - Tested in Preview mode
   - All events verified in DebugView
   ```
4. Click **Publish**

### 8. Deploy to GitHub Pages (Optional)

If you want to host the demo publicly:

1. Push your changes to GitHub
2. Go to repository **Settings** → **Pages**
3. Source: **Deploy from branch**
4. Branch: **main** or **gh-pages**
5. Click **Save**
6. Your demo will be live at: `https://[username].github.io/gtm-ga4-form-tracking-demo/`

---

## 🔧 Troubleshooting Setup

### Issue: "No data received from your tag"

**Cause:** Wrong GTM Container ID in HTML files

**Fix:**
1. Verify Container ID in GTM (top-right corner)
2. Check both HTML files have correct ID in 2 locations each
3. Clear browser cache
4. Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)

### Issue: GTM Preview won't connect

**Causes & Fixes:**
- ❌ **Browser extensions blocking**: Disable ad blockers, privacy extensions
- ❌ **Wrong URL**: Use exact URL (http://localhost:8000, not 127.0.0.1)
- ❌ **Container not saved**: Save all changes in GTM before Preview
- ❌ **Popup blocked**: Allow popups from tagmanager.google.com

### Issue: Events not appearing in GA4

**Checklist:**
- [ ] GA4 Measurement ID correct in GTM configuration tag
- [ ] GTM container published (not just saved)
- [ ] GTM Preview shows tags firing successfully
- [ ] Ad blockers disabled
- [ ] Waiting 10-30 seconds for DebugView
- [ ] Using correct GA4 property (check property ID matches)

### Issue: Variables showing "undefined"

**Causes:**
- dataLayer push missing that field
- Variable name misspelled (case-sensitive)
- Data Layer Version set to wrong version (should be Version 2)

**Fix:** Check browser console for dataLayer contents:
```
console.log(window.dataLayer);
```

---

## Option B: Manual Setup (If Not Using Container Import)

If you prefer to build the container from scratch, follow the detailed guide: [GTM-CONTAINER-SETUP.md](GTM-CONTAINER-SETUP.md)

This requires manually creating:
- 12 Data Layer Variables
- 6 Custom Event Triggers
- 7 GA4 Tags

**Time estimate:** 30-45 minutes

## License

MIT
