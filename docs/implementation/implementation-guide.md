# GTM/GA4 Form Tracking Implementation Guide

Production-ready implementation patterns for single and multi-step forms.

---

## Table of Contents

1. [Single-Step Forms](#single-step-forms)
2. [instance_id (Required for Production)](#instance_id-required-for-production)
3. [Multi-Step Form Funnels](#multi-step-form-funnels-in-ga4)
4. [Server-Side Event Deduplication](#server-side-event-deduplication)
5. [Platform-Specific Patterns](#platform-specific-patterns)

---

## Single-Step Forms

### Core Pattern

```javascript
// Generate unique instance ID once per form load
const instanceId = Date.now() + '_' + Math.random().toString(16).slice(2);

// Listen for form submit
form.addEventListener('submit', function(e) {
  e.preventDefault();
  
  // Validate first
  if (!formIsValid()) return;
  
  // Push to dataLayer ONLY on success
  window.dataLayer.push({
    event: 'form_submission_success',
    form_id: 'contact_us',
    instance_id: instanceId,
    form_type: 'lead',
    form_location: 'pricing_page',
    form_fields: {
      topic: topicValue,
      plan: planValue
    }
  });
  
  // Submit after push
  setTimeout(() => form.submit(), 500);
});
```

### Key Principles

1. **Validate before pushing** - Only fire events on successful submission
2. **Use instance_id** - Track unique form attempts
3. **Avoid high-cardinality fields** - Never send PII or free-text messages
4. **Standard event names** - Use `form_submission_success` for consistency

---

## instance_id (Required for Production)

Each form attempt should generate a unique `instance_id` when the form loads.

### Why It's Critical

- **Distinguish multiple attempts** in the same session
- **Correlate multi-step progression** across pages/steps
- **Support SPA rendering** where forms reload dynamically
- **Enable server-side deduplication** later (with `event_id`)

### Implementation Pattern

```javascript
// Generate ONCE per form load (not per submit)
const instance_id = Date.now() + '_' + Math.random().toString(16).slice(2);

// Include in ALL form-related events
window.dataLayer.push({
  event: 'form_submission_success',
  form_id: 'signup',
  instance_id: instance_id,  // ✅ Required
  // ... other fields
});
```

### What NOT to Do

❌ Generating a new `instance_id` on every submit (breaks multi-attempt tracking)  
❌ Omitting `instance_id` entirely (can't correlate events in SPAs)  
❌ Using session IDs or user IDs as `instance_id` (not specific to form instances)

---

## Multi-Step Form Funnels in GA4

### Event Model (5 Events)

For multi-step forms, fire these events in sequence:

| Event | When | Required Parameters |
|-------|------|--------------------|
| `form_start` | First interaction | `total_steps` |
| `form_step_view` | Step becomes visible | `step_number`, `step_name` |
| `form_step_complete` | Validation passed | `step_number` |
| `form_error` | Validation failed | `step_number`, `error_fields` |
| `form_submit_success` | Final success | `total_steps_completed` |

### Implementation Example

```javascript
// Generate instance ID once
const instanceId = Date.now() + '_' + Math.random().toString(16).slice(2);
const formId = 'multi_step_signup';

// Step 1: Form start
dataLayer.push({
  event: 'form_start',
  form_id: formId,
  instance_id: instanceId,
  total_steps: 3
});

// On step view
function stepView(step, name) {
  dataLayer.push({
    event: 'form_step_view',
    form_id: formId,
    instance_id: instanceId,
    step_number: step,
    step_name: name
  });
}

// On successful validation
function stepComplete(step) {
  dataLayer.push({
    event: 'form_step_complete',
    form_id: formId,
    instance_id: instanceId,
    step_number: step
  });
}

// On error
function stepError(step, fields) {
  dataLayer.push({
    event: 'form_error',
    form_id: formId,
    instance_id: instanceId,
    step_number: step,
    error_fields: fields  // ['email', 'phone']
  });
}

// Final submit
dataLayer.push({
  event: 'form_submit_success',
  form_id: formId,
  instance_id: instanceId,
  total_steps_completed: 3
});
```

### GA4 Funnel Configuration

Recommended funnel in GA4:

1. `form_start`
2. `form_step_complete` (step 1)
3. `form_step_complete` (step 2)
4. `form_step_complete` (step 3)
5. `form_submit_success`

This reveals **exactly where users abandon** the form.

### Drop-Off Analysis Query

```sql
-- BigQuery: Multi-step form drop-off analysis
SELECT
  instance_id,
  COUNTIF(event_name = 'form_start') AS started,
  COUNTIF(event_name = 'form_step_complete' AND step_number = 1) AS step1_complete,
  COUNTIF(event_name = 'form_step_complete' AND step_number = 2) AS step2_complete,
  COUNTIF(event_name = 'form_step_complete' AND step_number = 3) AS step3_complete,
  COUNTIF(event_name = 'form_submit_success') AS submitted
FROM `project.dataset.events_*`
WHERE event_name IN ('form_start', 'form_step_complete', 'form_submit_success')
GROUP BY instance_id;
```

---

## Server-Side Event Deduplication

### When You Need This

When sending the same event from:
- Client-side GTM
- Server-side GTM (GA4 / Meta CAPI)

You **MUST** include the same `event_id` to prevent duplicate counting.

### Pattern

```javascript
const instance_id = Date.now() + '_' + Math.random().toString(16).slice(2);
const event_id = `form_submission_success_${instance_id}`;

window.dataLayer.push({
  event: 'form_submission_success',
  form_id: 'contact_us',
  instance_id: instance_id,
  event_id: event_id,  // ✅ Dedup key
  tracking_source: 'client'
});
```

### Deduplication Rules

GA4 + Meta deduplicate events using:
1. **event_name** (must match exactly)
2. **event_id** (must match exactly)
3. **timestamp proximity** (within ~72 hours)

If all three match, the event is counted **only once**.

---

## Platform-Specific Patterns

### Shopify

- Use `theme.liquid` to inject dataLayer code
- Hook into Shopify's form submission callbacks
- See: `/platforms/shopify/` for complete examples

### WooCommerce

- Use `woocommerce_checkout_order_processed` hook
- Fire server-side events via GTM server container
- See: `/platforms/woocommerce/` for complete examples

### Magento

- Use knockout.js bindings for form interaction
- Integrate with Magento's checkout flow
- See: `/platforms/magento/` for complete examples

---

## Next Steps

1. **Review demos** - See `/demos/client-side/` for runnable examples
2. **Check templates** - Copy production-ready code from `/templates/snippets/`
3. **Read QA guide** - Validate your implementation with `/docs/qa/`
4. **Troubleshoot** - Common issues covered in `/docs/troubleshooting/`

---

## Related Documentation

- [QA & Testing Guide](../qa/)
- [Troubleshooting Guide](../troubleshooting/)
- [Platform-Specific Examples](../../platforms/)
- [GTM Container Templates](../../templates/gtm/)