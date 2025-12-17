# Chrome Privacy Sandbox Testing Guide

Comprehensive guide to preparing for third-party cookie deprecation through Privacy Sandbox APIs testing.

## Executive Summary

**Timeline**: Chrome third-party cookie deprecation started **Q1 2025** (currently rolling out to 100% of users).

**Impact Without Preparation**:
- **25-35% conversion signal loss** across Safari + Chrome (combined ITP + Privacy Sandbox transition)
- Attribution windows collapse from 28 days to <24 hours
- Remarketing campaigns lose 60-80% effectiveness

**Impact With Privacy Sandbox**:
- **<5% conversion signal loss** (industry testing shows 84.9% accuracy vs 88.6% with cookies)
- Event-level attribution maintained for critical conversions
- Server-side measurement compensates for most client-side losses

**What This Guide Covers**:
1. Privacy Sandbox API overview (Attribution Reporting, Protected Audience, Topics)
2. Local Chrome testing setup (no production deployment required)
3. A/B testing methodology to measure impact
4. GA4 integration for seamless measurement
5. Troubleshooting and validation

---

## Part 1: Understanding Privacy Sandbox APIs

### The Three Core APIs

Privacy Sandbox replaces third-party cookies with three specialized APIs:

#### 1. Attribution Reporting API (ARA)

**Replaces**: Conversion pixels, click/view-through attribution

**How It Works**:
```
User clicks ad → Browser registers "source event"
         ↓
User converts on site → Browser registers "trigger event"
         ↓
Browser matches source+trigger → Sends attribution report to ad tech
```

**Key Features**:
- **Event-level reports**: Individual click → conversion matches (with noise)
- **Aggregate reports**: Summary statistics without individual tracking
- **Conversion delay**: Reports sent 2-30 days after conversion (privacy protection)

**Accuracy** (MiQ testing, Oct 2024):
- Event-level: **84.9%** accuracy vs cookie-based (88.6%)
- Aggregate: **92%** accuracy
- Additional captures: **+3.7%** conversions cookies missed

#### 2. Protected Audience API (formerly FLEDGE)

**Replaces**: Remarketing/retargeting pixels

**How It Works**:
```
User visits your site → Browser adds user to "interest group"
         ↓
User visits publisher site → On-device ad auction
         ↓
Browser shows ad from winning interest group
```

**Key Features**:
- Ads selected **on-device** (no user data leaves browser)
- Interest groups expire after 30 days
- Publisher sites earn revenue without tracking users

**Use Cases**:
- Cart abandonment remarketing
- Product view retargeting
- Cross-sell/upsell campaigns

#### 3. Topics API

**Replaces**: Interest-based targeting (contextual alternative)

**How It Works**:
```
User browses web → Browser infers topics ("Travel", "Fitness")
         ↓
Publisher requests topics → Browser shares 3 recent topics
         ↓
Ad platform shows relevant ads based on topics
```

**Key Features**:
- 469 predefined topics (curated by Chrome)
- Topics rotate weekly
- 5% random topic injection (differential privacy)

**Use Cases**:
- Prospecting campaigns
- Awareness/consideration targeting
- Lookalike audience replacements

---

## Part 2: Local Testing Setup

### Prerequisites

- Chrome browser version **115+** (check: `chrome://version`)
- Developer Tools access
- Test website with conversion tracking

### Step 1: Enable Privacy Sandbox in Chrome

#### Method A: Chrome Flags (Recommended for Testing)

1. Navigate to `chrome://flags/`

2. Enable these flags:

   **Privacy Sandbox Ads APIs**
   ```
   chrome://flags/#privacy-sandbox-ads-apis
   Status: Enabled
   ```

   **Attribution Reporting Debug Mode**
   ```
   chrome://flags/#attribution-reporting-debug-mode
   Status: Enabled
   ```

   **Privacy Sandbox Enrollment Overrides**
   ```
   chrome://flags/#privacy-sandbox-enrollment-overrides
   Status: Enabled
   ```
   (Bypasses production enrollment requirement for local testing)

3. **Restart Chrome**

#### Method B: Command Line Flags (Advanced)

```bash
# Launch Chrome with Privacy Sandbox enabled
chrome.exe --enable-features="PrivacySandboxAdsAPIsOverride,AttributionReportingCrossAppWeb,ConversionMeasurement"
```

### Step 2: Verify APIs Are Active

Open DevTools Console and run:

```javascript
// Check Attribution Reporting API
if ('Attribution' in window) {
  console.log('✅ Attribution Reporting API available');
} else {
  console.log('❌ Attribution Reporting API not available');
}

// Check Protected Audience API
if ('joinAdInterestGroup' in navigator) {
  console.log('✅ Protected Audience API available');
} else {
  console.log('❌ Protected Audience API not available');
}

// Check Topics API
if (document.browsingTopics) {
  console.log('✅ Topics API available');
  document.browsingTopics().then(topics => {
    console.log('User topics:', topics);
  });
} else {
  console.log('❌ Topics API not available');
}
```

**Expected Output** (all three enabled):
```
✅ Attribution Reporting API available
✅ Protected Audience API available
✅ Topics API available
User topics: [{configVersion: "chrome.1", modelVersion: "1", taxonomyVersion: "1", topic: 249, ...}]
```

### Step 3: Test Attribution Reporting

#### A. Register Source Event (Ad Click)

Add to your ad/landing page:

```html
<!-- Attribution source (ad click link) -->
<a href="https://yourstore.com/product"
   attributionsrc="https://adtech.example/.well-known/attribution-reporting/register-source">
  Shop Now
</a>
```

**Or via JavaScript**:

```javascript
// Register attribution source programmatically
fetch('https://adtech.example/.well-known/attribution-reporting/register-source', {
  method: 'POST',
  keepalive: true,
  headers: {
    'Attribution-Reporting-Eligible': 'event-source'
  }
});
```

#### B. Register Trigger Event (Conversion)

Add to your thank-you/confirmation page:

```html
<!-- Attribution trigger (conversion pixel) -->
<img src="https://adtech.example/.well-known/attribution-reporting/register-trigger"
     attributionsrc
     width="1"
     height="1"
     style="display:none" />
```

**Or via JavaScript**:

```javascript
// Register conversion trigger
fetch('https://adtech.example/.well-known/attribution-reporting/register-trigger', {
  method: 'POST',
  keepalive: true,
  headers: {
    'Attribution-Reporting-Eligible': 'trigger'
  },
  body: JSON.stringify({
    'event_trigger_data': [{
      'trigger_data': '1',  // Conversion type (1=purchase)
      'priority': '100',
      'deduplication_key': 'ORDER_12345'
    }]
  })
});
```

#### C. View Attribution Reports

1. Navigate to: `chrome://attribution-internals/`

2. Tabs available:
   - **Sources**: Ad clicks/views registered
   - **Triggers**: Conversions registered
   - **Reports**: Matched attributions (sources → triggers)
   - **Errors**: Failed registrations

3. **Example Report**:
   ```json
   {
     "attribution_destination": "https://yourstore.com",
     "source_event_id": "123456789",
     "trigger_data": "1",
     "report_time": "1702915200",
     "priority": "100"
   }
   ```

**Notes**:
- Reports delayed 2-30 days in production (privacy protection)
- Debug mode sends reports immediately for testing
- Check **Errors** tab if reports not appearing

---

## Part 3: A/B Testing Methodology

### Objective

Establish baseline accuracy before full Privacy Sandbox rollout.

### Test Design: Cookie vs Privacy Sandbox

**Setup**:
- **Control Group** (50% traffic): Continue using third-party cookies
- **Test Group** (50% traffic): Privacy Sandbox APIs only
- **Duration**: 4 weeks minimum (capture full attribution windows)

**Traffic Allocation**:

```javascript
// Split users into control vs test group
const testGroup = Math.random() < 0.5;

if (testGroup) {
  // Privacy Sandbox only: Block third-party cookies
  document.cookie = "_ga=; Max-Age=0; path=/; SameSite=None; Secure";
  document.cookie = "_gcl_au=; Max-Age=0; path=/; SameSite=None; Secure";
  
  // Enable Attribution Reporting
  // (see Step 3 above)
} else {
  // Control: Standard cookie-based tracking
  // (existing GA4/Google Ads setup)
}
```

### Metrics to Compare

| Metric | Control (Cookies) | Test (Privacy Sandbox) | Variance Tolerance |
|--------|-------------------|------------------------|-------------------|
| Total Conversions | Baseline | Should be 85-95% | <15% loss acceptable |
| Click-to-conversion rate | Baseline | Should be within 5% | <5% variance |
| Attribution window | 28 days | 7-28 days (configurable) | Expected some compression |
| Cross-device tracking | Full | Limited (device-level only) | 15-20% loss expected |
| View-through attribution | Full | Limited (aggregate only) | 30-50% loss expected |

### Industry Benchmarks (MiQ Testing, Oct 2024)

**Results from 6-month Privacy Sandbox trial**:

| Measurement Type | Cookie Accuracy | Privacy Sandbox Accuracy | Delta |
|------------------|----------------|-------------------------|-------|
| Event-level attribution | 88.6% | 84.9% | -4.2% |
| Aggregate attribution | 90.1% | 92.0% | +2.1% |
| Combined approach | 88.6% | 88.6% | 0% |

**Key Finding**: Event-level + aggregate combined achieves **parity with cookies**.

**Additional Insights**:
- Privacy Sandbox captured **+3.7% conversions** that cookies missed (Safari users)
- False positive rate: **<1%** (differential privacy noise)
- Attribution delay: **2-7 days** in production (vs instant with cookies)

### Validation Query (BigQuery)

Compare cookie vs Privacy Sandbox conversion attribution:

```sql
WITH conversions AS (
  SELECT
    user_pseudo_id,
    event_timestamp,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'transaction_id') AS transaction_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'attribution_source_type') AS source_type,
    (SELECT value.double_value FROM UNNEST(event_params) WHERE key = 'value') AS value
  FROM `project.dataset.events_*`
  WHERE event_name = 'purchase'
    AND _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
)
SELECT
  source_type,
  COUNT(DISTINCT transaction_id) AS conversion_count,
  SUM(value) AS total_revenue,
  COUNT(DISTINCT user_pseudo_id) AS unique_purchasers,
  ROUND(AVG(value), 2) AS avg_order_value
FROM conversions
GROUP BY source_type
ORDER BY conversion_count DESC;
```

**Expected Output**:
```
source_type         | conversion_count | total_revenue | unique_purchasers
--------------------|------------------|---------------|------------------
COOKIE              | 450              | $12,350       | 412
PRIVACY_SANDBOX     | 392              | $10,890       | 365
UNATTRIBUTED        | 23               | $620          | 22
```

**Analysis**:
- Privacy Sandbox: 87% conversion capture vs cookies (within acceptable 85-95% range)
- Unattributed: 5% (acceptable, likely Safari + ad blocker users)
- Revenue parity: 88% (expected due to slightly lower AOV in Privacy Sandbox group)

---

## Part 4: GA4 Integration

### Prerequisites

- GA4 property created (G-XXXXXXXXX)
- BigQuery export enabled
- Attribution Reporting API active in Chrome (see Part 2)

### Step 1: Update GA4 Config Tag (GTM)

1. In GTM, open your **GA4 Configuration** tag

2. Add new **Field to Set**:
   ```
   Field Name: allow_privacy_sandbox
   Value: true
   ```

3. **Save** and **Publish** container

**What this does**:
- Enables GA4 to receive Attribution Reporting API reports
- GA4 automatically registers conversions as ARA triggers
- Reports appear in standard GA4 UI + BigQuery export

### Step 2: Configure Conversions

In GA4 UI:

1. Navigate to **Admin** → **Events**
2. Mark events as conversions:
   - `purchase`
   - `sign_up`
   - `add_to_cart` (if using for remarketing)

**What this does**:
- GA4 registers these events with Attribution Reporting API
- Browser sends attribution reports when these events fire
- No additional code changes needed

### Step 3: Verify in BigQuery

Privacy Sandbox attributions appear in `events_*` table with new parameter:

```sql
SELECT
  event_name,
  (SELECT value.string_value FROM UNNEST(event_params) 
   WHERE key = 'attribution_source_type') AS attribution_source,
  COUNT(*) AS event_count
FROM `project.dataset.events_*`
WHERE event_date = CURRENT_DATE()
  AND event_name IN ('purchase', 'sign_up')
GROUP BY event_name, attribution_source;
```

**Expected Output**:
```
event_name | attribution_source | event_count
-----------|--------------------|-----------
purchase   | COOKIE             | 142
purchase   | PRIVACY_SANDBOX    | 38
sign_up    | COOKIE             | 256
sign_up    | PRIVACY_SANDBOX    | 67
```

### Step 4: GA4 UI Reports

Privacy Sandbox conversions appear in:

- **Reports** → **Acquisition** → **Traffic acquisition**
  - Source/Medium breakdown includes Privacy Sandbox attributions

- **Advertising** → **Attribution** → **Conversion paths**
  - Shows touchpoint sequences (limited for Privacy Sandbox due to privacy)

- **Explore** → Create custom exploration:
  - Dimension: `Attribution source type` (custom dimension)
  - Metric: `Conversions`, `Revenue`

**Note**: Event-level reports delayed 2-7 days; aggregate reports near real-time.

---

## Part 5: Troubleshooting

### Issue: Attribution Internals Shows No Sources/Triggers

**Symptoms**: `chrome://attribution-internals/` empty despite implementing source/trigger code.

**Causes**:
1. Privacy Sandbox flags not enabled (see Part 2, Step 1)
2. `attributionsrc` attribute missing or misspelled
3. HTTPS required (API blocked on HTTP)
4. Cross-origin issues (source and trigger domains must match `attribution_destination`)

**Solution**:

1. Verify flags enabled:
   ```javascript
   console.log('ARA available:', 'Attribution' in window);
   ```

2. Check Network tab for attribution requests:
   - Filter by `.well-known/attribution-reporting`
   - Should see 200 OK responses

3. Check Console for errors:
   - "Attribution Reporting: Cross-origin attribution not allowed"
   - "Attribution Reporting: HTTPS required"

### Issue: GA4 Not Receiving Privacy Sandbox Conversions

**Symptoms**: BigQuery shows `attribution_source_type = NULL` or missing.

**Causes**:
1. `allow_privacy_sandbox: true` not set in GA4 Config tag
2. Events not marked as conversions in GA4 UI
3. GA4 Measurement ID mismatch

**Solution**:

1. Verify GTM configuration:
   - GA4 Config tag → Fields to Set → `allow_privacy_sandbox = true`

2. Verify events marked as conversions:
   - GA4 UI → Admin → Events → Toggle "Mark as conversion"

3. Test with GA4 DebugView:
   - Add `?debug_mode=true` to URL
   - Check if events appear in DebugView
   - Verify `attribution_source_type` parameter present

### Issue: Conversion Count Much Lower Than Expected

**Symptoms**: Privacy Sandbox conversions <50% of cookie-based.

**Expected**: 85-95% of cookie-based conversions.

**Causes**:
1. Attribution window too short (default 7 days vs cookies 28 days)
2. Cross-device conversions lost (Privacy Sandbox is device-level only)
3. Test implementation issue

**Solution**:

1. **Extend attribution window** in source registration:
   ```json
   {
     "destination": "https://yoursite.com",
     "source_event_id": "123",
     "expiry": "2592000"  // 30 days in seconds (vs default 604800 = 7 days)
   }
   ```

2. **Accept cross-device loss**:
   - 15-20% of conversions are cross-device (industry avg)
   - Privacy Sandbox cannot track cross-device by design
   - Compensate with server-side measurement (see `docs/advanced/server-side/`)

3. **Validate test group assignment**:
   - Ensure 50/50 traffic split
   - Check for browser compatibility (Chrome 115+ only)

---

## Part 6: Production Readiness Checklist

### Before Deprecation (Now - Q2 2025)

- [ ] **Complete local testing** (Parts 2-3 of this guide)
- [ ] **A/B test shows <15% conversion loss** (acceptable threshold)
- [ ] **GA4 integration validated** (BigQuery export shows Privacy Sandbox data)
- [ ] **Server-side GTM implemented** (compensates for client-side signal loss)
- [ ] **Consent Mode v2 deployed** (GDPR compliance, see `consent-mode/`)
- [ ] **Privacy policy updated** (disclose Privacy Sandbox usage)

### During Rollout (Q2-Q4 2025)

- [ ] **Monitor attribution parity** (weekly checks, should stay 85-95%)
- [ ] **Adjust attribution windows** if needed (extend from 7 to 28 days)
- [ ] **Update ad creatives** for on-device auctions (Protected Audience)
- [ ] **Retrain ML models** with Privacy Sandbox data (Topics API)

### Post-Deprecation (2026+)

- [ ] **Phase out cookie-based measurement** (no longer functional)
- [ ] **Optimize for aggregate reports** (event-level limited to critical conversions)
- [ ] **Invest in first-party data** (customer accounts, CRM integration)

---

## Resources & References

### Official Documentation

- [Privacy Sandbox Developer Guide](https://developers.google.com/privacy-sandbox)
- [Attribution Reporting API Explainer](https://github.com/WICG/attribution-reporting-api)
- [Protected Audience API Explainer](https://github.com/WICG/turtledove)
- [Topics API Explainer](https://github.com/patcg-individual-drafts/topics)

### Testing Tools

- [Privacy Sandbox Demo](https://arapi-home.web.app/) - Interactive Attribution Reporting demo
- [Chrome Attribution Internals](chrome://attribution-internals/) - View local reports
- [Privacy Sandbox Timeline](https://privacysandbox.google.com/timeline) - Rollout schedule

### Industry Research

- **MiQ (Oct 2024)**: "Testing Chrome's Attribution Reporting API: 84.9% accuracy vs cookies"
- **Salesforce (May 2024)**: "Prepare for Google Chrome Privacy Sandbox Initiative"
- **Google (Jul 2025)**: "Privacy Sandbox Measurement Testing Guide"

### Support

- [Privacy Sandbox FAQ](https://privacysandbox.google.com/faq)
- [GitHub Issues](https://github.com/GoogleChromeLabs/privacy-sandbox-dev-support)
- [Web.dev Community](https://web.dev/tags/privacy/)

---

**Questions?** Open a GitHub issue or contact via Upwork for implementation assistance.
