---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Troubleshooting Guide

Common issues and solutions for GTM/GA4/BigQuery/Looker Studio setup.

---

## Server-Side Tracking Issues

### Issue: Server GTM Shows "(direct) / (none)" for All Traffic

**Symptom:**
- Webhooks fire successfully (Stape logs confirm)
- Events reach GA4
- But 80-100% show as "Direct" traffic instead of "Google / Organic"

**Root Cause:**
UTM parameters exist in URL on client-side but webhooks don't include URL context.

**Solution:**
[Link to full solution in docs/advanced/server-side/PRODUCTION-REALITY.md section 1](../advanced/server-side/PRODUCTION-REALITY.md#1-utm-parameters-dont-auto-forward-to-server-container)

**Quick validation:**
```
// In Server GTM Preview Mode:
// Click on webhook event
// Go to "Variables" tab
// Check Event Parameter - utm_source

// Should show: "google" or actual source
// If shows: undefined or null → UTM forwarding not configured
```

---

### Issue: Revenue Doubled in GA4 After Enabling Server-Side

**Symptom:**
- Same transaction_id appears twice in reports
- Revenue shows 200% of Shopify order total

**Root Cause:**
Both client-side tag AND server-side webhook fire purchase events without deduplication.

**Diagnosis:**
```
-- BigQuery check
SELECT 
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'transaction_id') as txn,
  COUNT(*) as count,
  STRING_AGG(DISTINCT (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')) as sessions
FROM `project.dataset.events_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name = 'purchase'
GROUP BY txn
HAVING count > 1
```

If returns rows: Deduplication failing

**Solutions:**

**Option 1: Disable client-side purchase event**
- In Web GTM, disable the GA4 Purchase tag
- Let server-side webhook handle ALL purchases
- Pro: Simple, guaranteed no duplicates
- Con: Loses real-time purchase tracking (webhook delayed 30-60 seconds)

**Option 2: Implement proper deduplication**
[Link to full solution in docs/advanced/server-side/PRODUCTION-REALITY.md section 4](../advanced/server-side/PRODUCTION-REALITY.md#4-deduplication-tokens-misconfigured)

---

### Issue: Meta Conversions API Shows Low Match Rate (<40%)

**Symptom:**
- Meta Events Manager → Event Match Quality shows 30-40%
- Should be 60-70%+

**Root Cause:**
Server container sending server's IP address instead of user's IP.

**Diagnosis:**
1. Go to Meta Events Manager
2. Click "Test Events"  
3. Trigger purchase on your site
4. In test events, expand "Customer Information"
5. If shows "Iowa" or "Virginia" (cloud provider location): IP not forwarded

**Solution:**
[Link to full solution in docs/advanced/server-side/PRODUCTION-REALITY.md section 5](../advanced/server-side/PRODUCTION-REALITY.md#5-ip-address-and-user-agent-not-forwarded)

---

### Issue: GA4 Shows Massive "Unassigned" Traffic After Enabling Server-Side

**Symptom:**
- Acquisition reports show 30-50% "Unassigned" channel
- Was <5% before server-side implementation

**Root Cause:**
Cookie management strategy misconfigured - server and client creating different _ga cookies.

**Diagnosis:**
```
// On your site's homepage, open browser console:
document.cookie.split(';').filter(c => c.trim().startsWith('_ga'));

// If shows MULTIPLE _ga cookies (e.g., _ga, _ga_G123456): PROBLEM
// Should only show ONE _ga cookie
```

**Solution:**
[Link to full solution in docs/advanced/server-side/PRODUCTION-REALITY.md section 2](../advanced/server-side/PRODUCTION-REALITY.md#2-cookie-strategy-misconfiguration--unassigned-traffic-spike)

---

### Issue: Server Container Events Don't Fire When User Denies Cookies

**Symptom:**
- User denies consent via cookie banner
- Client-side respects it (no tags fire)
- Server-side still fires tags → GDPR violation

**Root Cause:**
Server container has no visibility into client-side CMP decisions.

**Solution:**
[Link to full solution in docs/advanced/server-side/PRODUCTION-REALITY.md section 3](../advanced/server-side/PRODUCTION-REALITY.md#3-consent-mode-not-synchronized-between-client-and-server)

---

## GTM Issues

### Issue: GTM Container Not Loading

**Symptoms:**
- No GTM requests in browser Network tab
- `dataLayer` is undefined in console
- Tags never fire in Preview mode

**Solutions:**

1. **Check container code placement:**
   ```
   <!-- Must be in <head BEFORE any other scripts -->
   <script>(function(w,d,s,l,i){...})(window,document,'script','dataLayer','GTM-XXXXXXX');</script>
   ```

2. **Check noscript fallback:**
   ```
   <!-- Must be immediately after opening <body tag -->
   <noscript><iframe src="https://www.googletagmanager.com/ns.html?id=GTM-XXXXXXX"></iframe></noscript>
   ```

3. **Verify container ID:**
   - Go to GTM → Admin → Container settings
   - Copy Container ID (format: `GTM-XXXXXXX`)
   - Replace in both HTML files

4. **Check for JavaScript errors:**
   - Open browser DevTools → Console
   - Look for errors that might block GTM from loading

---

### Issue: dataLayer Push Not Triggering Tags

**Symptoms:**
- `dataLayer.push()` executes in console
- Event appears in dataLayer (check with browser extension)
- But trigger doesn't fire in GTM Preview

**Debug Steps:**

1. **Check event name matches trigger:**
   ```
   // In your code:
   dataLayer.push({event: 'form_submission_success'});
   
   // In GTM trigger configuration:
   // Event name must EXACTLY match: form_submission_success
   ```

2. **Check trigger conditions:**
   - Open GTM Preview
   - Click on the event in timeline
   - Go to "Triggers" tab
   - Look for your trigger - if missing, condition failed
   - Click "Trigger Evaluation" to see why

3. **Verify variables resolve:**
   - In GTM Preview, click event
   - Go to "Variables" tab
   - Check Data Layer Variables - should NOT be `undefined`
   - If undefined, check dataLayer structure

**Common mistakes:**

```
// WRONG - Missing 'event' key
dataLayer.push({
  form_id: 'contact_us',
  form_type: 'lead'
});

// CORRECT - 'event' key triggers GTM
dataLayer.push({
  event: 'form_submission_success',  // This line is CRITICAL
  form_id: 'contact_us',
  form_type: 'lead'
});
```

---

### Issue: Variables Showing as "undefined"

**Symptoms:**
- GTM Preview shows variable value as `undefined`
- Tag fires but parameters are empty in GA4

**Solutions:**

1. **Check dataLayer path:**
   ```
   // Your dataLayer push:
   dataLayer.push({
     event: 'form_submit',
     form_fields: {
       topic: 'sales',
       plan: 'pro'
     }
   });
   
   // Variable configuration in GTM:
   // Variable name: form_fields.topic
   // NOT: topic (wrong - won't find nested value)
   ```

2. **Check Data Layer Version:**
   - In GTM, edit variable
   - Data Layer Version should be: **Version 2**
   - Version 1 doesn't support nested objects

3. **Set default values:**
   - In variable configuration
   - Check "Set Default Value"
   - Default: `not_set` or `(not provided)`
   - Helps identify when variable isn't populating

---

## GA4 Issues

### Issue: Events Not Appearing in GA4 DebugView

**Prerequisites:**
- GA4 DebugView requires `debug_mode` enabled
- For web: Install GA4 Debug Chrome extension OR add `?debug_mode=true` to URL

**Symptoms:**
- GTM Preview shows tags firing
- But GA4 DebugView shows no events

**Solutions:**

1. **Enable debug mode:**
   - Install [Google Analytics Debugger](https://chrome.google.com/webstore/detail/google-analytics-debugger) extension
   - Click icon to enable (icon turns green)
   - Reload page and test again

2. **Check Measurement ID:**
   ```
   // In GTM GA4 Configuration tag:
   // Measurement ID: G-XXXXXXXXX
   // 
   // Must match your GA4 property ID
   // Find in GA4: Admin → Property Settings → Measurement ID
   ```

3. **Check ad blockers:**
   - Disable uBlock Origin, AdBlock Plus, etc.
   - These block GA4 requests by default
   - Test in Incognito mode without extensions

4. **Verify GA4 property is active:**
   - Go to GA4 Admin → Property details
   - Status should be "Active"
   - If "Deleted", restore or create new property

---

### Issue: Custom Parameters Not Visible in GA4 Reports

**Symptoms:**
- Events appear in GA4
- But custom parameters (form_topic, form_plan) missing from reports

**Cause:** Custom dimensions not registered

**Solution:**

1. Go to GA4 → Admin → Custom definitions
2. Click "Create custom dimension"
3. Configuration:
   - **Dimension name:** `Form Topic`
   - **Scope:** Event
   - **Event parameter:** `form_topic`
   - **Description:** Topic selected in contact form
4. Click "Save"

Repeat for all custom parameters:
- `form_plan` → Form Plan
- `form_location` → Form Location
- `form_id` → Form ID

**Important:** Wait 24-48 hours for dimensions to populate with data.

---

### Issue: E-commerce Items Array Not Tracking

**Symptoms:**
- `purchase` event fires
- But item details missing in GA4

**Solution:**

Verify items array structure matches GA4 schema:

```
// CORRECT structure:
dataLayer.push({
  event: 'purchase',
  ecommerce: {
    transaction_id: 'TXN123',
    value: 99.99,
    currency: 'USD',
    items: [  // Array of objects
      {
        item_id: 'SKU001',      // Required
        item_name: 'Product A',  // Required
        price: 99.99,
        quantity: 1
      }
    ]
  }
});
```

**Common mistakes:**

```
// WRONG - Items not in array
items: {
  item_id: 'SKU001',
  item_name: 'Product A'
}

// WRONG - Missing required fields
items: [
  {
    name: 'Product A',  // Should be 'item_name'
    id: 'SKU001'        // Should be 'item_id'
  }
]
```

---

## BigQuery Issues

### Issue: "Table not found: events_20251207"

**Symptoms:**
- SQL query fails with table not found error
- Or "Not found: Dataset gtm-ga4-analytics:analytics_514638991"

**Solutions:**

1. **Check BigQuery export is enabled:**
   - GA4 → Admin → BigQuery Links
   - Status should show "Linked"
   - If not, click "Link" and follow setup

2. **Wait for first export:**
   - After enabling, wait **24-48 hours** for first table
   - Daily exports run once per day (usually overnight)
   - Check if any tables exist:
     ```
     SELECT table_name
     FROM `gtm-ga4-analytics.analytics_514638991.INFORMATION_SCHEMA.TABLES`
     WHERE table_name LIKE 'events_%'
     LIMIT 10;
     ```

3. **Verify project and dataset names:**
   - In BigQuery console, check actual names
   - Update SQL queries with correct:
     - Project ID: `gtm-ga4-analytics` (replace with yours)
     - Dataset ID: `analytics_514638991` (your GA4 property number)

4. **Check permissions:**
   - Need `bigquery.dataViewer` role minimum
   - Go to BigQuery → dataset → Share
   - Add your email with appropriate role

---

### Issue: Query Returns No Results

**Symptoms:**
- Query executes successfully
- But returns 0 rows

**Debug Steps:**

1. **Check date range:**
   ```
   -- Test if ANY data exists
   SELECT COUNT(*) as total_events
   FROM `gtm-ga4-analytics.analytics_514638991.events_*`
   WHERE _TABLE_SUFFIX >= '20251201';  // Adjust date
   ```

2. **Check event name:**
   ```
   -- List all event names in last 7 days
   SELECT event_name, COUNT(*) as count
   FROM `gtm-ga4-analytics.analytics_514638991.events_*`
   WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
   GROUP BY event_name
   ORDER BY count DESC;
   ```

3. **Verify event parameters exist:**
   ```
   -- Check if form_id parameter exists
   SELECT 
     event_name,
     (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id') as form_id
   FROM `gtm-ga4-analytics.analytics_514638991.events_*`
   WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
     AND event_name = 'generate_lead'
   LIMIT 10;
   ```

---

### Issue: BigQuery Costs Are High

**Symptoms:**
- Monthly BigQuery bill exceeds free tier
- Looker Studio dashboards expensive to refresh

**Solutions:**

1. **Always use date-partitioned queries:**
   ```
   -- EXPENSIVE - Scans ALL tables
   SELECT * FROM `events_*`
   WHERE event_date = '20251207';
   
   -- CHEAP - Only scans one table
   SELECT * FROM `events_*`
   WHERE _TABLE_SUFFIX = '20251207';
   ```

2. **Select only needed columns:**
   ```
   -- EXPENSIVE - Scans all columns (GB of data)
   SELECT * FROM `events_20251207`;
   
   -- CHEAP - Scans specific columns only
   SELECT event_name, event_timestamp, user_pseudo_id
   FROM `events_20251207`;
   ```

3. **Create materialized views:**
   ```
   CREATE MATERIALIZED VIEW `reporting.form_submissions_mv` AS
   SELECT ...  -- Your expensive query here
   ```

4. **Enable Looker Studio caching:**
   - In data source settings
   - Set "Data freshness" to 12 hours
   - Prevents repeated BigQuery queries

---

## Looker Studio Issues

### Issue: Dashboard Shows "Configuration Error"

**Symptoms:**
- Red error message in chart
- "Configuration error: Invalid query" or similar

**Solutions:**

1. **Test query in BigQuery first:**
   - Copy query from Looker Studio
   - Run in BigQuery console
   - Fix any SQL errors
   - Update Looker Studio with corrected query

2. **Check field names match:**
   - If query has `submission_date` column
   - Chart must use `submission_date` (exact match)
   - Case-sensitive!

3. **Verify date fields:**
   - Date columns must be DATE type (not STRING)
   - Use `PARSE_DATE()` or `DATE()` in query:
     ```
     PARSE_DATE('%Y%m%d', event_date) as submission_date
     ```

---

### Issue: Dashboard Performance Is Slow

**Symptoms:**
- Charts take 20+ seconds to load
- "Still loading..." spinner persists

**Solutions:**

1. **Use custom queries, not direct tables:**
   - Don't connect to `events_*` tables directly
   - Use pre-aggregated queries (see [sql/](../sql/) directory)

2. **Enable data caching:**
   - Resource → Manage added data sources
   - Data freshness: 12 hours

3. **Limit date ranges:**
   - Don't query 365 days when 30 days is sufficient
   - Use date range controls in dashboard

4. **Pre-aggregate in BigQuery:**
   ```
   -- Instead of row-level data:
   SELECT event_date, user_id, event_name  -- Millions of rows
   
   -- Use aggregated data:
   SELECT event_date, 
          event_name, 
          COUNT(*) as event_count  -- Hundreds of rows
   GROUP BY event_date, event_name
   ```

---

## Testing Checklist

Use this checklist to systematically debug issues:

### GTM Setup
- [ ] Container code in `<head>` before other scripts
- [ ] Noscript fallback after opening `<body>` tag
- [ ] Container ID (GTM-XXXXXXX) is correct
- [ ] GTM Preview mode connects successfully
- [ ] All built-in variables enabled (Event, Page Path, etc.)

### dataLayer Events
- [ ] `window.dataLayer` initialized before any pushes
- [ ] Each push includes `event` key
- [ ] Event names match trigger configurations exactly
- [ ] Variable paths match dataLayer structure (e.g., `form_fields.topic`)
- [ ] Data Layer Variables use Version 2

### GA4 Configuration
- [ ] GA4 Configuration tag fires on All Pages
- [ ] Measurement ID (G-XXXXXXXXX) is correct
- [ ] GA4 DebugView enabled (browser extension)
- [ ] Events visible in DebugView within 1-2 minutes
- [ ] Custom dimensions registered in GA4 Admin

### BigQuery Setup
- [ ] BigQuery link enabled in GA4 Admin
- [ ] 24-48 hours passed since enabling
- [ ] Tables exist: `events_YYYYMMDD`
- [ ] Queries use `_TABLE_SUFFIX` for date filtering
- [ ] Service account has `bigquery.dataViewer` role

### Looker Studio
- [ ] Data source uses custom queries (not direct tables)
- [ ] Queries return results in BigQuery console
- [ ] Date fields are DATE type (not STRING)
- [ ] Data freshness caching enabled (12 hours recommended)
- [ ] Field names in charts match query column names

---

## E-commerce Specific Issues

### Duplicate Purchase Events

**Symptom**: Same transaction appears 2-3 times in GA4 reports
**Root Cause**: User refreshes thank-you page, event fires again

**Solution 1: Transaction ID Deduplication (GTM)**
1. Create Custom JavaScript Variable: `Deduplication Check`
```
function() {
  var txnId = {{DLV - Transaction ID}};
  var firedTxns = sessionStorage.getItem('ga4_purchases') || '';
  
  if (firedTxns.includes(txnId)) {
    return false; // Already fired
  }
  
  // Mark as fired
  sessionStorage.setItem('ga4_purchases', firedTxns + '|' + txnId);
  return true;
}
```

2. Add Firing Trigger Condition: `Deduplication Check equals true`

**Solution 2: Platform-Level Prevention**
- Shopify Liquid: `{% if first_time_accessed %}`
- WooCommerce PHP: `get_post_meta($order_id, '_ga4_tracked', true)`
- Magento: Session variable check in controller

**Solution 3: GA4 Data Stream Settings**
Enable "Enhanced measurement" → Unwanted referrals: Add your own domain to ignore internal navigation

---

### Missing Item-Level Parameters

**Symptom**: Products show "(not set)" in Item reports
**Root Cause**: Required parameters missing from items array

**Required Parameters Checklist**:
- [x] `item_id` - Product SKU or ID (REQUIRED)
- [x] `item_name` - Product display name (REQUIRED)
- [ ] `price` - Individual item price (HIGHLY RECOMMENDED)
- [ ] `quantity` - Number of items (defaults to 1)
- [ ] `item_brand` - Brand/manufacturer
- [ ] `item_category` - Primary category
- [ ] `item_variant` - Size/color variant

**Debugging Process**:
1. Open GTM Preview Mode
2. Trigger purchase event
3. Check dataLayer:
```
// In browser console:
dataLayer.find(obj => obj.event === 'purchase').ecommerce.items
```
4. Verify all required fields exist and are non-empty
5. Check for trailing spaces, null values, undefined

**Common Mistakes**:
```
// BAD - Missing price
{item_id: 'SKU123', item_name: 'Product', quantity: 1}

// BAD - Price as string with currency symbol
{item_id: 'SKU123', item_name: 'Product', price: '$99.99'}

// GOOD
{item_id: 'SKU123', item_name: 'Product', price: 99.99, quantity: 1}
```

---

### Currency Formatting Issues

**Symptom**: Revenue reports show inflated or deflated values
**Root Cause**: Locale-based decimal formatting (Europe: 99,99 vs US: 99.99)

**Detection**:
```
// Check in browser console:
typeof {{DLV - Transaction Value}}  // Should be 'number', not 'string'
```

**Solution**:
```
// GTM Custom JavaScript Variable: Clean Currency Value
function() {
  var rawValue = {{DLV - Transaction Value}};
  
  // Remove currency symbols and spaces
  rawValue = rawValue.replace(/[^0-9,.-]/g, '');
  
  // Handle European format (comma as decimal)
  if (rawValue.includes(',') && !rawValue.includes('.')) {
    rawValue = rawValue.replace(',', '.');
  }
  
  // Remove thousands separators
  rawValue = rawValue.replace(/,(?=\d{3})/g, '');
  
  return parseFloat(rawValue);
}
```

---

### Items Array Empty or Malformed

**Symptom**: ecommerce.items shows as empty array or undefined
**Root Cause**: DataLayer cleared incorrectly or items not constructed

**Validation Script**:
```
// Add as Custom HTML tag after ecommerce events
<script>
(function() {
  var lastEcom = dataLayer.filter(obj => obj.ecommerce).pop();
  
  if (!lastEcom || !lastEcom.ecommerce.items) {
    console.error('❌ GA4 ERROR: ecommerce.items missing');
    return;
  }
  
  var items = lastEcom.ecommerce.items;
  
  if (!Array.isArray(items) || items.length === 0) {
    console.error('❌ GA4 ERROR: items array empty');
    return;
  }
  
  items.forEach((item, idx) => {
    if (!item.item_id) console.error('❌ Item ' + idx + ': missing item_id');
    if (!item.item_name) console.error('❌ Item ' + idx + ': missing item_name');
    if (!item.price) console.warn('⚠️ Item ' + idx + ': missing price (recommended)');
  });
  
  console.log('✓ Items array validation passed');
})();
</script>
```

---

### Event Firing Out of Sequence

**Symptom**: `purchase` fires before `add_to_cart`, funnel reports broken
**Root Cause**: Asynchronous page loads, SPAs, timing issues

**Solution: Event Sequence Validator**
```
// GTM Custom HTML - All Pages
<script>
window.ga4EventSequence = window.ga4EventSequence || [];

dataLayer.push(function() {
  var eventName = {{Event}};
  
  var ecomEvents = ['view_item', 'add_to_cart', 'begin_checkout', 'add_payment_info', 'purchase'];
  
  if (ecomEvents.includes(eventName)) {
    ga4EventSequence.push(eventName);
    
    // Check logical sequence
    var currentIdx = ecomEvents.indexOf(eventName);
    var lastEvent = ga4EventSequence[ga4EventSequence.length - 2];
    var lastIdx = ecomEvents.indexOf(lastEvent);
    
    if (lastIdx > currentIdx) {
      console.warn('⚠️ GA4 SEQUENCE WARNING: ' + eventName + ' fired after ' + lastEvent);
    }
  }
});
</script>
```

---

## Getting Help

If issues persist after following this guide:

1. **Check GTM Preview:**
   - Summary tab shows tag firing status
   - Variables tab shows if values are defined
   - Trigger tab shows why triggers fired or didn't fire

2. **Check GA4 DebugView:**
   - Confirms events reaching GA4
   - Shows parameter names and values
   - Real-time (no 24-48 hour delay)

3. **Check BigQuery Job History:**
   - BigQuery console → Job history
   - Shows failed queries and error messages
   - Helps identify permission or syntax issues

4. **Enable verbose logging:**
   ```
   // Add to browser console for debugging
   window.dataLayer.push = new Proxy(window.dataLayer.push, {
     apply: function(target, thisArg, argumentsList) {
       console.log('dataLayer push:', argumentsList);
       return target.apply(thisArg, argumentsList);
     }
   });
   ```

---

**Still stuck?** Open a GitHub issue with:
- Description of problem
- Screenshots of GTM Preview
- Error messages from browser console
- SQL query causing issues (if BigQuery related)
