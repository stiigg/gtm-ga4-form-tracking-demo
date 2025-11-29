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
- GA4 gtag.js integration
- GitHub Pages hosting

## License

MIT
