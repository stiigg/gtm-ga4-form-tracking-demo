# 👨‍💻 Developer Quick Start

**Goal:** Get GTM/GA4 form tracking running in 5-10 minutes.

---

## Prerequisites

- [ ] Google Analytics 4 property created
- [ ] Google Tag Manager container created
- [ ] Access to your website's code/theme files

---

## 5-Minute Setup (Client-Side)

### Step 1: Import GTM Container (1 min)

1. Download: [`gtm-container-web.json`](../reference/gtm-container-exports/gtm-container-web.json)
2. In GTM: **Admin → Import Container**
3. Select "Merge" with conflict strategy "Rename conflicting tags"

**What you get:**
- Form submission event listener
- GA4 event tag (form_submit)
- Validation trigger (prevents double-fires)
- Error logging variable

---

### Step 2: Add DataLayer Code (2 min)

Copy this snippet **above your closing `</body>` tag:**

```javascript
<script>
window.dataLayer = window.dataLayer || [];

// Form validation and submission tracking
document.addEventListener('DOMContentLoaded', function() {
  const forms = document.querySelectorAll('form');
  
  forms.forEach(function(form) {
    form.addEventListener('submit', function(e) {
      // Only track if form is valid
      if (form.checkValidity()) {
        dataLayer.push({
          'event': 'form_submit',
          'form_id': form.id || 'unknown',
          'form_name': form.name || 'unknown',
          'form_destination': form.action || window.location.href
        });
      }
    });
  });
});
</script>
```

---

### Step 3: Configure GA4 Measurement ID (1 min)

In GTM:
1. Go to **Variables → Google Analytics: GA4 Configuration**
2. Update `Measurement ID` to your GA4 property ID (G-XXXXXXXXXX)
3. Save

---

### Step 4: Test (1 min)

1. In GTM: Click **Preview**
2. Enter your website URL
3. Submit a form on your site
4. Check GTM Preview: You should see `form_submit` event

**Expected dataLayer:**
```json
{
  "event": "form_submit",
  "form_id": "contact-form",
  "form_name": "contact",
  "form_destination": "/thank-you"
}
```

---

### Step 5: Publish (30 sec)

In GTM: **Submit → Publish**

**Version name:** `Form tracking v1.0 - Initial deployment`

---

## Platform-Specific Setup

### Shopify

**Code location:** `theme.liquid` before `</body>`

```liquid
{% if template == 'page.contact' or template == 'customers/register' %}
<script>
window.dataLayer = window.dataLayer || [];

document.addEventListener('DOMContentLoaded', function() {
  const forms = document.querySelectorAll('form');
  
  forms.forEach(function(form) {
    form.addEventListener('submit', function(e) {
      if (form.checkValidity()) {
        dataLayer.push({
          'event': 'form_submit',
          'form_id': form.id || 'unknown',
          'form_name': form.name || 'unknown',
          'form_destination': form.action || window.location.href
        });
      }
    });
  });
});
</script>
{% endif %}
```

[Full Shopify guide →](../platforms/shopify/)

---

### WooCommerce

**Code location:** `functions.php` in child theme

```php
add_action('wp_footer', 'gtm_form_tracking');
function gtm_form_tracking() {
  if (is_checkout() || is_cart() || is_account_page()) {
    ?>
    <script>
    window.dataLayer = window.dataLayer || [];
    
    document.addEventListener('DOMContentLoaded', function() {
      const forms = document.querySelectorAll('form');
      
      forms.forEach(function(form) {
        form.addEventListener('submit', function(e) {
          if (form.checkValidity()) {
            dataLayer.push({
              'event': 'form_submit',
              'form_id': form.id || 'unknown',
              'form_name': form.name || 'unknown',
              'form_destination': form.action || window.location.href
            });
          }
        });
      });
    });
    </script>
    <?php
  }
}
```

[Full WooCommerce guide →](../platforms/woocommerce/)

---

### Magento 2

**Code location:** `default.xml` layout file

```xml
<referenceContainer name="before.body.end">
  <block class="Magento\Framework\View\Element\Template" 
         template="Vendor_Module::gtm-tracking.phtml"/>
</referenceContainer>
```

[Full Magento guide →](../platforms/magento/)

---

## Verify It's Working

### Method 1: GTM Preview Mode

1. GTM Preview → Submit form
2. Check "Data Layer" tab for `form_submit` event
3. Check "Tags" tab - GA4 tag should fire

---

### Method 2: GA4 DebugView

1. GA4 → **Configure → DebugView**
2. Submit form on your site
3. Within 10 seconds, see `form_submit` event

---

### Method 3: Browser DevTools

```javascript
// In browser console, check dataLayer
console.log(window.dataLayer);

// Submit form, then check again
console.log(window.dataLayer);
// Should show new form_submit event
```

---

## Common Issues

### Form event not firing

**Cause:** Form validation failing, JavaScript errors  
**Fix:** Check browser console for errors

```javascript
// Debug: Add this before form tracking code
console.log('Form tracking script loaded');
```

---

### Duplicate events

**Cause:** Multiple tracking scripts, page refresh on thank-you page  
**Fix:** Add deduplication guard

```javascript
let submittedForms = new Set();

form.addEventListener('submit', function(e) {
  const formKey = form.id + '-' + Date.now();
  
  if (submittedForms.has(form.id)) {
    return; // Already tracked
  }
  
  submittedForms.add(form.id);
  
  dataLayer.push({
    'event': 'form_submit',
    // ...
  });
  
  // Clear after 5 seconds
  setTimeout(() => submittedForms.delete(form.id), 5000);
});
```

---

### Events in GTM Preview but not GA4

**Cause:** GA4 Measurement ID incorrect  
**Fix:** Double-check GA4 configuration variable

1. GTM → Variables → GA4 Configuration
2. Verify Measurement ID matches your GA4 property
3. Re-publish container

---

## Next Steps

**You're now tracking form submissions!** 

### Level Up:

- [ ] Add server-side GTM for ad blocker bypass → [Server-Side Guide](../server-side/)
- [ ] Track eCommerce events (add_to_cart, purchase) → [Platforms](../platforms/)
- [ ] Build Looker Studio dashboard → [Dashboard Guide](../reference/looker-studio-setup.md)
- [ ] Set up BigQuery export for analysis → [SQL Queries](../reference/bigquery-queries/)

---

## Full Documentation

For complete implementation including:
- Consent Mode v2 setup
- Enhanced eCommerce tracking
- Cross-domain tracking
- Server-side architecture

**See:** [Implementation Checklist](implementation-checklist.md)

---

## Need Help?

**Stuck?** Check [Troubleshooting Guide](troubleshooting.md)  
**Want implementation done for you?** [See pricing](../business/pricing.md)

---

[← Back to guides](README.md) | [View live demos →](../demos/)