# 🎨 Live Demos

Test working implementations directly in your browser.

---

## Available Demos

### 1. Basic Form Tracking
**File:** [`basic-form.html`](basic-form.html)  
**What it shows:** Good vs Bad form tracking implementation side-by-side

**Live demo:** [View online →](https://stiigg.github.io/gtm-ga4-form-tracking-demo/demos/basic-form.html)

**Features:**
- ✅ Good implementation with validation-first tracking
- ❌ Bad implementation showing common mistakes
- Real-time dataLayer visualization
- GTM Preview Mode instructions

**Test it:**
1. Open demo link
2. Open browser console (F12)
3. Submit both forms
4. Compare dataLayer output

---

### 2. eCommerce Tracking
**File:** [`ecommerce-tracking.html`](ecommerce-tracking.html)  
**What it shows:** Complete GA4 eCommerce event suite

**Live demo:** [View online →](https://stiigg.github.io/gtm-ga4-form-tracking-demo/demos/ecommerce-tracking.html)

**Events included:**
- `view_item_list` - Product listing page
- `view_item` - Product detail page
- `add_to_cart` - Add to cart button
- `remove_from_cart` - Remove from cart
- `begin_checkout` - Checkout initiation
- `add_shipping_info` - Shipping information
- `add_payment_info` - Payment information
- `purchase` - Order confirmation (with deduplication)

---

### 3. Server-Side Comparison
**File:** [`server-side-comparison.html`](server-side-comparison.html)  
**What it shows:** Three tracking architectures compared

**Live demo:** [View online →](https://stiigg.github.io/gtm-ga4-form-tracking-demo/demos/server-side-comparison.html)

**Comparison:**
- **Column 1:** Client-side only (standard GTM)
- **Column 2:** Server-side only (advanced)
- **Column 3:** Hybrid approach (recommended)

---

## How to Use These Demos

### Option 1: View Online
Click "Live demo" links above to test in browser immediately.

### Option 2: Clone Locally
```bash
git clone https://github.com/stiigg/gtm-ga4-form-tracking-demo.git
cd gtm-ga4-form-tracking-demo/demos
open basic-form.html  # macOS
start basic-form.html # Windows
```

### Option 3: Test with Your Own GTM Container

1. Download any demo HTML file
2. Replace `GTM-XXXXXX` with your container ID
3. Open file in browser
4. Submit forms and check your GA4 DebugView

---

## What to Look For

### In Browser Console (F12 → Console tab):

**Good implementation:**
```javascript
[dataLayer] form_submit event pushed:
{
  event: "form_submit",
  form_id: "contact-form",
  form_name: "contact",
  form_destination: "/thank-you",
  form_valid: true
}
```

**Bad implementation:**
```javascript
[dataLayer] form_submit event pushed:
{
  event: "form_submit"
  // Missing: form_id, form_name, validation status
}
```

---

## Next Steps

**Tested the demos?** Now implement on your site:

1. [Developer Quick Start](../guides/for-developers.md) - 5-minute setup
2. [Implementation Checklist](../guides/implementation-checklist.md) - Full deployment
3. [QA Validation](../qa-testing/) - Pre-launch testing

---

## Questions?

**Not working as expected?** [Troubleshooting Guide](../guides/troubleshooting.md)  
**Need custom implementation?** [Pricing & Portfolio Offer](../business/pricing.md)

---

[← Back to main README](../README.md)