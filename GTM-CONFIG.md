# GTM Configuration Guide

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

In GA4 Admin > Custom definitions, create event-scoped dimensions:

| Dimension Name | Event Parameter | Scope |
|----------------|-----------------|-------|
| Form ID | `form_id` | Event |
| Form Type | `form_type` | Event |
| Form Topic | `form_topic` | Event |
| Form Plan | `form_plan` | Event |

### Key Events (Conversions)

Mark these as key events in GA4:
- `generate_lead`
- `purchase`

## Testing Checklist

- [ ] GTM Preview shows `form_submission_success` event on valid form submit
- [ ] GTM Preview shows NO event on failed validation
- [ ] Data Layer tab shows all expected parameters
- [ ] Variables tab shows resolved values (not undefined)
- [ ] GA4 DebugView shows `generate_lead` event
- [ ] GA4 DebugView shows correct parameters
- [ ] E-commerce events fire in correct sequence

## Live Demo

- Form Tracking: https://stiigg.github.io/gtm-ga4-form-tracking-demo/
- E-commerce: https://stiigg.github.io/gtm-ga4-form-tracking-demo/ecommerce.html
