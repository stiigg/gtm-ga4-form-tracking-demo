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
