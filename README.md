# GTM/GA4 Tracking Demo

Complete demo site showing GTM (Google Tag Manager) and GA4 (Google Analytics 4) tracking implementations with dataLayer push examples.

## Live Demos

| Demo | Description | Link |
|------|-------------|------|
| Form Tracking | Good vs Bad form submission tracking | [View Demo](https://stiigg.github.io/gtm-ga4-form-tracking-demo/) |
| E-commerce | Full e-commerce funnel tracking | [View Demo](https://stiigg.github.io/gtm-ga4-form-tracking-demo/ecommerce.html) |

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

### 1. Clone Repository
```
git clone https://github.com/stiigg/gtm-ga4-form-tracking-demo.git
cd gtm-ga4-form-tracking-demo
```

### 2. Set Up GTM Container

**Option A: Import Pre-configured Container (Fastest)**
1. Go to [tagmanager.google.com](https://tagmanager.google.com)
2. Create/select account → Import Container
3. Upload `gtm-container-export.json` from this repo
4. Update GA4 Measurement ID in configuration tag
5. Publish container

**Option B: Manual Setup**
Follow the detailed guide: [GTM-CONTAINER-SETUP.md](GTM-CONTAINER-SETUP.md)

### 3. Update HTML Files
Replace `GTM-XXXXXXX` in both HTML files with your actual GTM container ID:
- `index.html` (head and body)
- `ecommerce.html` (head and body)

### 4. Test Locally
```
# Serve files locally
python3 -m http.server 8000
# Or use any local server

# Open in browser
open http://localhost:8000
```

### 5. Enable GTM Preview Mode
1. In GTM, click **Preview**
2. Enter your test URL
3. Test all events (form submissions, add to cart, purchase)
4. Verify in GA4 DebugView

### 6. Publish GTM Container
Once testing is complete:
1. GTM → **Submit**
2. Add version name and description
3. **Publish**

## License

MIT
