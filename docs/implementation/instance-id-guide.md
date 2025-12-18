# instance_id Implementation Guide

## Overview

**Status**: Required for Production  
**Priority**: Critical  
**Affects**: Form tracking accuracy, multi-step correlation, SPA support

---

## What is instance_id?

The `instance_id` is a unique identifier generated once per form load that distinguishes individual form interaction attempts, even when they occur in the same session.

**Format**: `{timestamp}_{random_string}`  
**Example**: `1734515405123_a8f3c2d9e1b4`

---

## Why It's Critical

### Problem Without instance_id

```javascript
// User submits form multiple times in same session:
Session 1:
  ├─ form_submission_success (contact_us)  ← Which attempt?
  ├─ form_submission_success (contact_us)  ← Same or different?
  └─ form_submission_success (contact_us)  ← Can't distinguish
```

Without `instance_id`, you cannot:
- Distinguish multiple form attempts in the same session
- Track multi-step form progression
- Handle SPA form re-renders correctly
- Deduplicate events in server-side scenarios

### Solution With instance_id

```javascript
// Same user, but now trackable:
Session 1:
  ├─ form_submission_success (instance_id: 1734515405123_a8f3c2d9e1b4) ← First attempt
  ├─ form_submission_success (instance_id: 1734515482044_b3e7a9c5f2d8) ← Second attempt
  └─ form_submission_success (instance_id: 1734515513967_c8d2b4e6a1f9) ← Third attempt
```

---

## Implementation Patterns

### Single-Step Forms

Generate `instance_id` once when the form becomes visible:

```javascript
// Generate on page/form load
const instance_id = `${Date.now()}_${Math.random().toString(16).slice(2)}`;

// Use in all form events
window.dataLayer.push({
  event: 'form_submission_success',
  form_id: 'contact_us',
  instance_id: instance_id,  // ← Same ID for this form instance
  form_type: 'lead',
  form_location: 'homepage'
});
```

### Multi-Step Forms

Generate `instance_id` once at form start, reuse across all steps:

```javascript
// Generate ONCE at form start
const instance_id = `${Date.now()}_${Math.random().toString(16).slice(2)}`;

// Step 1
window.dataLayer.push({
  event: 'form_step_complete',
  form_id: 'signup_form',
  instance_id: instance_id,  // ← Same ID
  step_number: 1
});

// Step 2
window.dataLayer.push({
  event: 'form_step_complete',
  form_id: 'signup_form',
  instance_id: instance_id,  // ← Same ID
  step_number: 2
});

// Final submission
window.dataLayer.push({
  event: 'form_submit_success',
  form_id: 'signup_form',
  instance_id: instance_id,  // ← Same ID
  total_steps_completed: 2
});
```

### SPA (Single-Page Application)

Regenerate `instance_id` when form is re-rendered:

```javascript
function initContactForm() {
  // New instance ID each time form is rendered
  const instance_id = `${Date.now()}_${Math.random().toString(16).slice(2)}`;
  
  const form = document.getElementById('contact-form');
  
  form.addEventListener('submit', function(e) {
    e.preventDefault();
    
    window.dataLayer.push({
      event: 'form_submission_success',
      form_id: 'contact_us',
      instance_id: instance_id,  // ← Unique per render
      form_type: 'lead'
    });
  });
}

// Call whenever form is rendered
initContactForm();
```

---

## Use Cases Enabled

### 1. Multiple Attempts Analysis

**BigQuery SQL Example**:
```sql
SELECT
  user_pseudo_id,
  COUNT(DISTINCT event_params.value) AS form_attempts,
  MIN(event_timestamp) AS first_attempt,
  MAX(event_timestamp) AS last_attempt
FROM `project.dataset.events_*`,
  UNNEST(event_params) AS event_params
WHERE
  event_name = 'form_submission_success'
  AND event_params.key = 'instance_id'
GROUP BY user_pseudo_id
HAVING form_attempts > 1
ORDER BY form_attempts DESC;
```

**Insight**: Users submitting forms multiple times may indicate:
- Unclear success confirmation
- Technical errors
- Impatient users

### 2. Multi-Step Funnel Correlation

```sql
WITH form_steps AS (
  SELECT
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'instance_id') AS instance_id,
    event_name,
    event_timestamp
  FROM `project.dataset.events_*`
  WHERE event_name IN ('form_start', 'form_step_complete', 'form_submit_success')
)
SELECT
  instance_id,
  COUNTIF(event_name = 'form_start') AS started,
  COUNTIF(event_name = 'form_step_complete') AS steps_completed,
  COUNTIF(event_name = 'form_submit_success') AS submitted
FROM form_steps
GROUP BY instance_id
HAVING started = 1 AND submitted = 0;  -- Abandoned forms
```

### 3. Server-Side Deduplication

Combine with `event_id` for server-side tracking:

```javascript
const instance_id = `${Date.now()}_${Math.random().toString(16).slice(2)}`;
const event_id = `form_submission_${instance_id}`;

window.dataLayer.push({
  event: 'form_submission_success',
  form_id: 'contact_us',
  instance_id: instance_id,
  event_id: event_id,  // ← Deduplication key
  tracking_source: 'client'
});
```

Server-side GTM sends same `event_id` → GA4 deduplicates automatically.

---

## GTM Configuration

### Data Layer Variable

**Variable Name**: `DLV - instance_id`  
**Variable Type**: Data Layer Variable  
**Data Layer Variable Name**: `instance_id`  
**Data Layer Version**: Version 2

### GA4 Event Parameter

Add to all form-related event tags:

| Parameter Name | Value | Scope |
|---------------|-------|-------|
| `instance_id` | `{{DLV - instance_id}}` | Event |

### GA4 Custom Dimension

**Dimension Name**: `instance_id`  
**Scope**: Event  
**Event Parameter**: `instance_id`  
**Description**: Unique identifier per form load/render

---

## Validation Checklist

### Development Testing

- [ ] Open form in browser
- [ ] Note generated `instance_id` in console/debugger
- [ ] Submit form
- [ ] Verify same `instance_id` sent in dataLayer
- [ ] Refresh page (hard refresh)
- [ ] Verify NEW `instance_id` generated
- [ ] Submit form again
- [ ] Verify different `instance_id` than previous attempt

### GTM Preview Mode

- [ ] Load page with GTM Preview active
- [ ] Check dataLayer: `instance_id` populated
- [ ] Submit form
- [ ] Verify `instance_id` sent to GA4
- [ ] Check format: `{timestamp}_{random}` (e.g., `1734515405123_a8f3c2d9e1b4`)

### GA4 DebugView

- [ ] Open GA4 → Admin → DebugView
- [ ] Submit form on test site
- [ ] Find `form_submission_success` event
- [ ] Expand event parameters
- [ ] Verify `instance_id` parameter exists and has value
- [ ] Submit form again
- [ ] Verify NEW `instance_id` value in second event

### Production Validation

```sql
-- BigQuery: Check instance_id is populated
SELECT
  event_name,
  COUNT(*) AS total_events,
  COUNTIF((
    SELECT value.string_value 
    FROM UNNEST(event_params) 
    WHERE key = 'instance_id'
  ) IS NOT NULL) AS events_with_instance_id,
  ROUND(COUNTIF((
    SELECT value.string_value 
    FROM UNNEST(event_params) 
    WHERE key = 'instance_id'
  ) IS NOT NULL) * 100.0 / COUNT(*), 2) AS coverage_pct
FROM `project.dataset.events_*`
WHERE
  event_name IN ('form_submission_success', 'form_step_complete')
  AND _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
                        AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
GROUP BY event_name;
```

**Expected Result**: Coverage should be 100% for form events.

---
## Common Issues

### Issue 1: Same instance_id Across Page Loads

**Symptom**: `instance_id` value doesn't change when user refreshes page  
**Cause**: `instance_id` generated globally and cached  
**Solution**: Generate inside form initialization function or ensure it's scoped correctly

**Bad**:
```javascript
// Global scope - persists across SPA navigation
const instance_id = `${Date.now()}_${Math.random().toString(16).slice(2)}`;

function handleFormSubmit() {
  window.dataLayer.push({
    instance_id: instance_id  // ← Always same value
  });
}
```

**Good**:
```javascript
function initForm() {
  // Local scope - regenerated each initialization
  const instance_id = `${Date.now()}_${Math.random().toString(16).slice(2)}`;
  
  form.addEventListener('submit', function() {
    window.dataLayer.push({
      instance_id: instance_id
    });
  });
}
```

### Issue 2: instance_id Undefined in GTM

**Symptom**: GTM variable `{{DLV - instance_id}}` resolves to `undefined`  
**Cause**: dataLayer push happens before `instance_id` is defined  
**Solution**: Ensure `instance_id` is generated before any dataLayer pushes

```javascript
// Generate FIRST
const instance_id = `${Date.now()}_${Math.random().toString(16).slice(2)}`;

// Then push
window.dataLayer.push({
  event: 'form_submission_success',
  instance_id: instance_id  // ← Now defined
});
```

### Issue 3: Different instance_id Per Step (Multi-Step Forms)

**Symptom**: Each step has different `instance_id`, can't correlate steps  
**Cause**: `instance_id` regenerated inside step handlers  
**Solution**: Generate once at form start, store in closure/state

```javascript
class MultiStepForm {
  constructor() {
    // Generate once
    this.instance_id = `${Date.now()}_${Math.random().toString(16).slice(2)}`;
  }
  
  submitStep(stepNumber) {
    window.dataLayer.push({
      event: 'form_step_complete',
      instance_id: this.instance_id,  // ← Reuse same ID
      step_number: stepNumber
    });
  }
}

const form = new MultiStepForm();
```

---

## Migration from Existing Implementation

### Step 1: Add instance_id to Code

Update all form tracking scripts to generate and include `instance_id`:

```javascript
// Before
window.dataLayer.push({
  event: 'form_submission_success',
  form_id: 'contact_us'
});

// After
const instance_id = `${Date.now()}_${Math.random().toString(16).slice(2)}`;
window.dataLayer.push({
  event: 'form_submission_success',
  form_id: 'contact_us',
  instance_id: instance_id  // ← Added
});
```

### Step 2: Update GTM Variables

Create new Data Layer Variable:
- Name: `DLV - instance_id`
- Variable: `instance_id`

### Step 3: Update GA4 Tags

Add parameter to all form event tags:
- Parameter: `instance_id`
- Value: `{{DLV - instance_id}}`

### Step 4: Create GA4 Custom Dimension

In GA4:
1. Admin → Custom definitions → Create custom dimension
2. Dimension name: `instance_id`
3. Scope: Event
4. Event parameter: `instance_id`

### Step 5: Validate

- [ ] Test in GTM Preview
- [ ] Verify in GA4 DebugView
- [ ] Monitor coverage using BigQuery SQL above
- [ ] Wait 24-48h for custom dimension to populate

---

## References

- [Multi-Step Form Guide](multi-step-forms.md) - How to use `instance_id` across steps
- [Server-Side Tracking](../advanced/server-side/README.md) - Combining with `event_id`
- [BigQuery Examples](../../templates/sql/instance-id-analysis.sql) - Analysis queries

---

**Status**: Production-ready  
**Last Updated**: December 18, 2025  
**Author**: @stiigg
