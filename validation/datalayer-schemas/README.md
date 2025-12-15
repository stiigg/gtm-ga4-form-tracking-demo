# DataLayer Validation Schemas

JSON Schema definitions for validating dataLayer events before they reach GTM.

## Purpose

- **Catch errors early**: Validate event structure in development before production deployment
- **Type safety**: Ensure numeric values aren't accidentally sent as strings
- **Required fields**: Prevent incomplete events from firing
- **Enum validation**: Restrict values to predefined lists
- **Pattern matching**: Validate format (e.g., transaction IDs, currency codes)

## Schema Files

### `form-submission.schema.json`
Validates `form_submission_success` events:
- Required fields: `event`, `form_id`, `form_type`, `form_location`
- Pattern validation for `form_id` (snake_case only)
- Enum validation for `form_type` (lead, support, sales, newsletter, download)
- Optional `form_fields` object with predefined properties

### `purchase.schema.json`
Validates `purchase` ecommerce events:
- Required nested structure: `event` → `ecommerce` → `transaction_id`, `value`, `currency`, `items`
- Type enforcement: `value` must be number (not string "99.99")
- Currency code validation: 3-letter ISO 4217 format (USD, EUR, GBP)
- Items array validation: min 1, max 200 items per transaction
- Item required fields: `item_id`, `item_name`, `price`, `quantity`

## Usage

### Browser Console (Development)

```javascript
// Load validation utility
<script src="/validation/validate-datalayer.js"></script>

// Automatically validate all dataLayer pushes when ?debug=1 in URL
// OR on localhost

// Manual validation
validateDataLayer('form_submission_success');
validateDataLayer('purchase');

// Expected output:
// ✅ DataLayer validation passed: form_submission_success
// OR
// ❌ DataLayer Validation Failed: purchase
//   • Field "value" expected number, got string
//   • Field "currency" value "usd" doesn't match pattern: ^[A-Z]{3}$
```

### Automated Testing (Playwright/Puppeteer)

```javascript
const { test, expect } = require('@playwright/test');

test('contact form submits valid dataLayer event', async ({ page }) => {
  await page.goto('https://example.com/contact');
  
  // Inject validation utility
  await page.addScriptTag({ path: './validation/validate-datalayer.js' });
  
  // Fill and submit form
  await page.fill('#email', 'test@example.com');
  await page.click('#submit');
  
  // Validate dataLayer event
  const isValid = await page.evaluate(() => {
    return validateDataLayer('form_submission_success');
  });
  
  expect(isValid).toBe(true);
});
```

### CI/CD Pipeline Integration

```yaml
# .github/workflows/datalayer-validation.yml
name: DataLayer Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - name: Install dependencies
        run: npm install ajv ajv-formats
      - name: Validate schemas
        run: |
          npx ajv validate -s validation/datalayer-schemas/purchase.schema.json \
                          -d test/fixtures/valid-purchase.json
```

## Common Validation Errors

### 1. Number sent as string

**Error**:
```
❌ Field "value" expected number, got string
```

**Cause**:
```javascript
dataLayer.push({
  ecommerce: {
    value: "99.99"  // ❌ String
  }
});
```

**Fix**:
```javascript
dataLayer.push({
  ecommerce: {
    value: 99.99  // ✅ Number
  }
});
```

### 2. Lowercase currency code

**Error**:
```
❌ Field "currency" value "usd" doesn't match pattern: ^[A-Z]{3}$
```

**Fix**: Use uppercase: `USD` not `usd`

### 3. Missing required field

**Error**:
```
❌ Missing required field: transaction_id
```

**Fix**: Ensure all required fields present before push

### 4. Invalid enum value

**Error**:
```
❌ Field "form_type" value "contact" not in allowed values: lead, support, sales, newsletter, download
```

**Fix**: Use predefined values or update schema to include new value

## Schema Development Guidelines

### Adding New Event Schema

1. Create `validation/datalayer-schemas/{event-name}.schema.json`
2. Define structure matching GA4 event specification
3. Add to `validate-datalayer.js` SCHEMAS object
4. Document in this README
5. Create test fixtures in `test/fixtures/`

### Schema Best Practices

- **Be strict in development**: Use `additionalProperties: false` to catch typos
- **Type enforcement**: Always specify `type` for every property
- **Numeric constraints**: Use `minimum`, `maximum` to prevent unrealistic values
- **String patterns**: Use regex `pattern` for structured strings (IDs, codes)
- **Array bounds**: Set `minItems`, `maxItems` to prevent empty or oversized arrays
- **Examples**: Include valid example in schema for documentation

## Research Basis

Based on industry research:
- **ObservePoint** (2025): "Tag governance requires defined processes for quality assurance"
- **DataTrue** (2024): "Automated data layer testing reduces errors by 80-90%"
- Industry case studies document that schema validation catches structural errors before production

## Related Files

- `validation/validate-datalayer.js` - Browser validation utility
- `snippets/datalayer-form-tracking.js` - Example implementation
- `snippets/datalayer-ecommerce.js` - Example implementation
- `TROUBLESHOOTING.md` - Common dataLayer errors
