---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Looker Studio Dashboard Setup Guide

This guide shows how to connect your GA4 BigQuery export to Looker Studio and build dashboards.

## Prerequisites

- ✅ GTM container published with GA4 tags
- ✅ GA4 receiving events (check DebugView)
- ✅ BigQuery export enabled in GA4
- ✅ At least 24-48 hours of data collected
- ✅ BigQuery dataset contains `events_YYYYMMDD` tables

---

## Part 1: Verify BigQuery Data

Before building dashboards, confirm data is flowing correctly.

### Check Tables Exist

```
-- List all event tables in your dataset
SELECT table_name, 
       TIMESTAMP_MILLIS(creation_time) as created_at,
       row_count,
       size_bytes / POW(10,9) as size_gb
FROM `gtm-ga4-analytics.analytics_514638991.__TABLES__`
WHERE table_name LIKE 'events_%'
ORDER BY table_name DESC
LIMIT 10;
```

**Expected output:**
```
table_name          | created_at           | row_count | size_gb
events_20251207     | 2025-12-07 01:30:00 | 1,247     | 0.012
events_20251206     | 2025-12-06 01:30:00 | 892       | 0.009
...
```

### Test Form Submission Query

```
-- Quick test: Count form submissions
SELECT COUNT(*) as form_submissions
FROM `gtm-ga4-analytics.analytics_514638991.events_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY))
  AND event_name = 'generate_lead';
```

If this returns 0, troubleshoot:
1. Check GTM Preview - is `generate_lead` event firing?
2. Check GA4 DebugView - is event reaching GA4?
3. Wait 24-48 hours after first event for BigQuery export

---

## Part 2: Create Looker Studio Data Sources

### Option A: Use Pre-built SQL Queries (Recommended)

This method is faster and more cost-efficient.

#### 1. Form Submissions Data Source

1. Go to [lookerstudio.google.com](https://lookerstudio.google.com)
2. Click **Create** → **Data source**
3. Select **BigQuery** connector
4. Choose **Custom Query**
5. Select your project: `gtm-ga4-analytics`
6. Paste this query:

```
-- Form submissions with all parameters
SELECT
  PARSE_DATE('%Y%m%d', event_date) as submission_date,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id') as form_id,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_type') as form_type,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_location') as form_location,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_topic') as form_topic,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_plan') as form_plan,
  COUNT(*) as submissions,
  COUNT(DISTINCT user_pseudo_id) as unique_users
FROM `gtm-ga4-analytics.analytics_514638991.events_*`
WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
  AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
  AND event_name = 'generate_lead'
GROUP BY submission_date, form_id, form_type, form_location, form_topic, form_plan;
```

7. Click **Add** → **Add to Report**
8. Name: `Form Submissions - GA4 BigQuery`

#### 2. E-commerce Funnel Data Source

Repeat steps 1-3, then paste:

```
-- E-commerce funnel metrics
WITH user_events AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) as event_date,
    user_pseudo_id,
    event_name,
    event_timestamp
  FROM `gtm-ga4-analytics.analytics_514638991.events_*`
  WHERE _TABLE_SUFFIX BETWEEN FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
    AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
    AND event_name IN ('view_item_list', 'view_item', 'add_to_cart', 'begin_checkout', 'purchase')
)
SELECT
  event_date,
  COUNTIF(event_name = 'view_item_list') as view_list_count,
  COUNTIF(event_name = 'view_item') as view_item_count,
  COUNTIF(event_name = 'add_to_cart') as add_cart_count,
  COUNTIF(event_name = 'begin_checkout') as checkout_count,
  COUNTIF(event_name = 'purchase') as purchase_count
FROM user_events
GROUP BY event_date
ORDER BY event_date DESC;
```

### Option B: Direct Table Connection (Not Recommended)

Connecting directly to `events_*` tables is expensive and slow. Only use for exploration.

---

## Part 3: Build Form Tracking Dashboard

### Dashboard Layout

```
┌────────────────────────────────────────────────────────┐
│  Form Submission Dashboard - Last 30 Days              │
├─────────────┬─────────────┬─────────────┬─────────────┤
│ Total       │ Unique      │ Conv Rate   │ Avg Daily   │
│ Submissions │ Users       │ (%)         │ Submissions │
│    247      │    193      │    3.2%     │    8.2      │
├──────────────────────────────────────────────────────────┤
│          Submissions Over Time (Line Chart)             │
│  ┌──────────────────────────────────────────────────┐  │
│  │                                            /\     │  │
│  │                               /\          /  \    │  │
│  │                    /\        /  \        /    \   │  │
│  │         /\        /  \      /    \      /      \  │  │
│  │    ────/──\──────/────\────/──────\────/────────  │  │
│  └──────────────────────────────────────────────────┘  │
├──────────────────────┬───────────────────────────────────┤
│ By Topic (Pie Chart) │ By Plan (Bar Chart)               │
│  ┌──────────────┐    │  ┌────────────────────────────┐  │
│  │ Sales: 45%   │    │  │ ████████████ Basic (60%)   │  │
│  │ Support: 35% │    │  │ ████████ Pro (40%)         │  │
│  │ Partner: 20% │    │  │                            │  │
│  └──────────────┘    │  └────────────────────────────┘  │
└──────────────────────┴───────────────────────────────────┘
```

### Step-by-Step Build

#### 1. Create Scorecards

1. Click **Add a chart** → **Scorecard**
2. Drag to top-left corner
3. **Data source:** Form Submissions - GA4 BigQuery
4. **Metric:** `submissions`
5. **Scorecard label:** Total Submissions
6. **Style** → Number format: `#,##0`

Repeat for:
- **Unique Users:** metric = `unique_users`
- **Conversion Rate:** Add calculated field:
  - Field name: `conversion_rate`
  - Formula: `submissions / unique_users * 100`
  - Format: `0.0%`

#### 2. Add Time Series Chart

1. **Add a chart** → **Time series**
2. **Date range dimension:** `submission_date`
3. **Metric:** `submissions`
4. **Style:**
   - Line thickness: 2
   - Show data labels: Yes
   - Color: #667eea (your brand color)

#### 3. Add Pie Chart (By Topic)

1. **Add a chart** → **Pie chart**
2. **Dimension:** `form_topic`
3. **Metric:** `submissions`
4. **Style:**
   - Show slice labels: Yes
   - Show percentages: Yes

#### 4. Add Bar Chart (By Plan)

1. **Add a chart** → **Bar chart**
2. **Dimension:** `form_plan`
3. **Metric:** `submissions`
4. **Sort:** Descending by `submissions`

#### 5. Add Data Table (Detail View)

1. **Add a chart** → **Table**
2. **Dimensions:** 
   - `submission_date`
   - `form_topic`
   - `form_plan`
3. **Metrics:**
   - `submissions`
   - `unique_users`
4. **Interactions:**
   - Enable sorting
   - Enable filtering
   - Rows per page: 10

---

## Part 4: E-commerce Funnel Dashboard

### Funnel Visualization

1. **Add a chart** → **Funnel chart** (if available)
2. **Stages:**
   - Stage 1: `view_list_count` (Viewed Products)
   - Stage 2: `view_item_count` (Viewed Details)
   - Stage 3: `add_cart_count` (Added to Cart)
   - Stage 4: `checkout_count` (Started Checkout)
   - Stage 5: `purchase_count` (Purchased)

**If funnel chart not available**, use **Bar chart** with stages as dimension.

### Conversion Rate Scorecards

Add calculated fields for conversion rates:

```
list_to_item_rate = view_item_count / view_list_count * 100
item_to_cart_rate = add_cart_count / view_item_count * 100
cart_to_checkout_rate = checkout_count / add_cart_count * 100
checkout_to_purchase_rate = purchase_count / checkout_count * 100
```

---

## Part 5: Performance Optimization

### Enable Data Caching

1. In Looker Studio, click **Resource** → **Manage added data sources**
2. Select your BigQuery data source
3. **Data freshness:** 12 hours (recommended)
   - This caches query results for 12 hours
   - Reduces BigQuery costs by 90%+
   - Acceptable for most analytics use cases

### Create Scheduled Queries (Advanced)

For frequently-used dashboards, create materialized views:

```
-- Create materialized form submissions table
CREATE OR REPLACE TABLE `gtm-ga4-analytics.reporting.form_submissions_daily`
PARTITION BY submission_date
AS
SELECT
  PARSE_DATE('%Y%m%d', event_date) as submission_date,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_id') as form_id,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_topic') as form_topic,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'form_plan') as form_plan,
  COUNT(*) as submissions,
  COUNT(DISTINCT user_pseudo_id) as unique_users
FROM `gtm-ga4-analytics.analytics_514638991.events_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
  AND event_name = 'generate_lead'
GROUP BY submission_date, form_id, form_topic, form_plan;
```

**Schedule this query:**
1. In BigQuery, save query
2. Click **Schedule** → **Create new scheduled query**
3. Repeat: Daily at 2:00 AM
4. Update Looker Studio to use `reporting.form_submissions_daily` table

**Benefits:**
- ⚡ Instant dashboard loading (queries pre-computed table)
- 💰 95% cost reduction
- 🔄 Always fresh (runs daily)

---

## Part 6: Sharing & Collaboration

### Share Dashboard

1. Click **Share** (top-right)
2. Add emails or get shareable link
3. Permission levels:
   - **View:** Can only view dashboard
   - **Edit:** Can modify dashboard
   - **Owner:** Full control

### Embed in Website

1. Click **File** → **Embed report**
2. Copy iframe code
3. Paste in your HTML:

```
<iframe width="800" height="600" 
  src="https://lookerstudio.google.com/embed/reporting/YOUR_REPORT_ID" 
  frameborder="0" style="border:0" allowfullscreen>
</iframe>
```

---

## Troubleshooting

### Issue: "Configuration error: BigQuery error"

**Cause:** Insufficient permissions or dataset doesn't exist

**Solution:**
1. Verify dataset exists in BigQuery console
2. Check you have `bigquery.dataViewer` role minimum
3. Confirm project ID and dataset name are correct in query

### Issue: Dashboard loads slowly (>10 seconds)

**Causes:**
- Direct table connections (not custom queries)
- No data caching enabled
- Complex calculations in Looker Studio

**Solutions:**
1. Switch to custom query data sources
2. Enable 12-hour data freshness caching
3. Move calculations to BigQuery (use calculated fields in query)
4. Create materialized views for frequently-accessed data

### Issue: "No data available"

**Checklist:**
1. Does BigQuery table have data? (Run test query)
2. Is date range filter too restrictive?
3. Are dimension/metric combinations valid?
4. Wait 24-48 hours after enabling BigQuery export

---

## Cost Monitoring

### Estimate Looker Studio Costs

```
-- Check BigQuery bytes scanned by Looker Studio
SELECT
  user_email,
  DATE(creation_time) as query_date,
  COUNT(*) as query_count,
  SUM(total_bytes_processed) / POW(10,12) as TB_scanned,
  SUM(total_bytes_processed) / POW(10,12) * 6.25 as estimated_cost_usd
FROM `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND user_email LIKE '%datastudio%'  -- Looker Studio queries
GROUP BY user_email, query_date
ORDER BY query_date DESC;
```

**Typical costs with optimization:**
- Form tracking dashboard: ~$0.01 - 0.05 per day
- E-commerce dashboard: ~$0.02 - 0.10 per day
- With caching enabled: ~$0.001 - 0.01 per day

---

## Next Steps

- [ ] Build custom dashboards for specific business needs
- [ ] Set up email reports (File → Schedule email delivery)
- [ ] Create user segments in GA4 and visualize in Looker Studio
- [ ] Implement conversion funnel analysis
- [ ] Add traffic source breakdown dashboards

**Questions?** See [GTM-CONFIG.md](GTM-CONFIG.md) and [sql/](sql/) directory for more query examples.
