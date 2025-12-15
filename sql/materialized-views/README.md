# BigQuery Materialized Views for GA4

Pre-computed aggregations that dramatically reduce query costs and execution time for dashboards and reports.

## What Are Materialized Views?

**Materialized Views (MVs)** are BigQuery objects that cache the results of a query and automatically refresh as new data arrives.

**Key Benefits**:
- **50-70% cost reduction** for repeated queries[1][2]
- **80-95% faster execution** (seconds vs minutes)[1]
- **Automatic refresh** as new GA4 data streams in
- **Query optimizer integration** (BigQuery automatically uses MVs when beneficial)

## Files in This Directory

### 1. `daily_event_summary_mv.sql`

**Purpose**: Daily aggregation of all GA4 events with user/session counts.

**Pre-aggregates**:
- Event counts by date/event name
- Unique users and sessions
- Engagement metrics (time, platform)
- Geographic distribution

**Use Case**: Powers executive dashboards, KPI scorecards, traffic reports.

**Cost Savings Example**:
- Without MV: Dashboard queries 100x/day × 45MB = 4.5GB/day = **$8.25/month**
- With MV: Dashboard queries 100x/day × 10MB = 1GB/day = **$1.84/month**
- **Savings: $6.41/month (78%)**

### 2. `ecommerce_product_performance_mv.sql`

**Purpose**: Product-level revenue, quantity, and conversion metrics.

**Pre-aggregates**:
- Revenue by item_id/item_name
- Quantity sold, unique purchasers
- Average price, revenue per transaction
- Traffic source attribution

**Use Case**: Product performance dashboards, inventory planning, pricing analysis.

**Cost Savings Example**:
- Without MV: Product reports 50x/day × 12MB = 600MB/day = **$4.50/month**
- With MV: Product reports 50x/day × 0.6MB = 30MB/day = **$0.23/month**
- **Savings: $4.27/month (95%)**

## When to Use Materialized Views

### ✅ Good Use Cases

1. **Repeated Dashboard Queries**
   - Query runs >10 times/day
   - Same date range and aggregation logic
   - Example: Executive KPI dashboard

2. **Complex Aggregations**
   - Queries scan >1GB per execution
   - Multiple JOIN operations
   - Example: Multi-dimensional product analysis

3. **Real-Time Reporting**
   - GA4 streaming export enabled
   - Need fresh data every 15-60 minutes
   - Example: Live event monitoring dashboard

4. **High-Cardinality Grouping**
   - GROUP BY on item_id, user_pseudo_id
   - Millions of unique values
   - Example: Per-product revenue reporting

### ❌ Avoid MVs For

1. **Ad-Hoc Analysis**
   - Query runs once or infrequently
   - Changing logic each time
   - Better: Use standard queries

2. **Narrow Date Ranges**
   - Only querying last 24 hours
   - Scanning <100MB
   - Better: Direct table query

3. **Raw Event-Level Data**
   - Need individual event_timestamp values
   - Exploring data, not aggregating
   - Better: Query events_* directly

## Deployment Instructions

### Step 1: Review and Customize

1. Open each `.sql` file
2. Replace placeholders:
   - `demo-tracking-project` → Your GCP project ID
   - `analytics_398765432` → Your GA4 dataset ID
3. Adjust `refresh_interval_minutes` if needed:
   - **Hourly (60)**: Default for reporting dashboards
   - **30 minutes**: E-commerce real-time needs
   - **15 minutes**: High-frequency monitoring (costs more)

### Step 2: Deploy via BigQuery Console

1. Navigate to [BigQuery Console](https://console.cloud.google.com/bigquery)
2. Select your GA4 dataset
3. Click **+ Compose query**
4. Paste contents of `daily_event_summary_mv.sql`
5. Click **Run** (creates MV, takes 2-5 minutes)
6. Repeat for `ecommerce_product_performance_mv.sql`

### Step 3: Deploy via `bq` CLI

```bash
# Set project
export GCP_PROJECT="your-project-id"

# Deploy daily event summary MV
bq query \
  --project_id=$GCP_PROJECT \
  --use_legacy_sql=false \
  < sql/materialized-views/daily_event_summary_mv.sql

# Deploy ecommerce performance MV
bq query \
  --project_id=$GCP_PROJECT \
  --use_legacy_sql=false \
  < sql/materialized-views/ecommerce_product_performance_mv.sql
```

### Step 4: Verify Creation

```sql
-- Check materialized views exist
SELECT
  table_name,
  table_type,
  creation_time,
  last_modified_time
FROM `your-project.analytics_398765432.INFORMATION_SCHEMA.TABLES`
WHERE table_type = 'MATERIALIZED VIEW'
ORDER BY table_name;
```

Expected output:
```
table_name                           | table_type         | creation_time       
-------------------------------------|--------------------|-----------------
daily_event_summary_mv               | MATERIALIZED VIEW  | 2024-12-15 10:30:00
ecommerce_product_performance_mv     | MATERIALIZED VIEW  | 2024-12-15 10:32:00
```

## Using Materialized Views

### Automatic Query Rewriting

BigQuery automatically uses MVs when beneficial, even if you query the base table:

```sql
-- You write this:
SELECT event_name, COUNT(*)
FROM `project.dataset.events_*`
WHERE event_date = '2024-12-15'
GROUP BY event_name;

-- BigQuery executes this (automatically):
SELECT event_name, event_count
FROM `project.dataset.daily_event_summary_mv`
WHERE event_date = '2024-12-15';
```

**Result**: 70% cost reduction without changing your queries!

### Manual MV Querying

For guaranteed MV usage, query directly:

```sql
-- Dashboard query: Event counts last 7 days
SELECT
  event_name,
  SUM(event_count) AS total_events,
  SUM(unique_users) AS total_users
FROM `project.dataset.daily_event_summary_mv`
WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY event_name
ORDER BY total_events DESC;
```

```sql
-- Product performance: Top 10 by revenue
SELECT
  item_name,
  item_brand,
  SUM(total_item_revenue_usd) AS revenue,
  SUM(total_quantity_sold) AS units_sold
FROM `project.dataset.ecommerce_product_performance_mv`
WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY item_name, item_brand
ORDER BY revenue DESC
LIMIT 10;
```

## Monitoring & Maintenance

### Check Refresh Status

```sql
SELECT
  table_name,
  last_refresh_time,
  refresh_watermark,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), last_refresh_time, MINUTE) AS minutes_since_refresh
FROM `project.dataset.INFORMATION_SCHEMA.MATERIALIZED_VIEWS`
ORDER BY table_name;
```

**Healthy MVs**:
- `minutes_since_refresh` < refresh_interval_minutes
- `refresh_watermark` within 1 hour of current time

**Warning Signs**:
- `minutes_since_refresh` > 2x refresh_interval: Refresh backlog
- `refresh_watermark` >24 hours old: Refresh failures

### Force Manual Refresh

```sql
-- Trigger immediate refresh (rarely needed)
CALL BQ.REFRESH_MATERIALIZED_VIEW(
  'project.dataset.daily_event_summary_mv'
);
```

**When to use**:
- After bulk data backfill
- Testing new MV after creation
- Investigating data discrepancies

### Drop and Recreate

If you need to change MV schema:

```sql
-- 1. Drop existing MV
DROP MATERIALIZED VIEW `project.dataset.daily_event_summary_mv`;

-- 2. Edit SQL file with new schema

-- 3. Re-run CREATE statement
-- (Paste contents of daily_event_summary_mv.sql)
```

**Note**: Dropping MV doesn't affect base table; only cached results are lost.

## Cost Analysis

### MV Storage Costs

Materialized views consume storage (priced at $0.02/GB/month):

**Example**:
- `daily_event_summary_mv`: 500MB = **$0.01/month**
- `ecommerce_product_performance_mv`: 200MB = **$0.004/month**
- **Total storage cost**: $0.014/month

### MV Refresh Costs

Each refresh scans base table to update MV:

**Example** (daily_event_summary_mv with hourly refresh):
- Scans last 1 day of events: ~50MB
- Refreshes 24x/day: 50MB × 24 = 1.2GB/day
- Monthly refresh cost: 1.2GB × 30 × $5/TB = **$0.18/month**

### Net Savings Calculation

**Scenario**: Executive dashboard queried 100x/day

| Metric | Without MV | With MV | Savings |
|--------|-----------|---------|--------|
| Query cost/day | $0.275 | $0.061 | 78% |
| Storage cost/month | $0 | $0.01 | -$0.01 |
| Refresh cost/month | $0 | $0.18 | -$0.18 |
| **Net monthly cost** | **$8.25** | **$2.02** | **$6.23 (76%)** |

**ROI**: MVs pay for themselves after ~1 day of dashboard usage.

## Integration with Looker Studio

### Step 1: Add MV as Data Source

1. In Looker Studio, click **+ Add data**
2. Select **BigQuery**
3. Choose **Custom Query**:
   ```sql
   SELECT * FROM `project.dataset.daily_event_summary_mv`
   WHERE event_date >= @DS_START_DATE
     AND event_date <= @DS_END_DATE
   ```
4. Enable **Date Range** parameters

### Step 2: Create Calculated Fields

**Bounce Rate**:
```
COUNTD(CASE WHEN engaged_events = 0 THEN user_pseudo_id END) / COUNTD(user_pseudo_id)
```

**Events Per Session**:
```
SUM(event_count) / SUM(unique_sessions)
```

**Engagement Rate**:
```
SUM(engaged_events) / SUM(event_count)
```

### Step 3: Set Refresh Schedule

- Dashboard refresh: **Every 1 hour** (aligns with MV refresh)
- Cache duration: **30 minutes**
- Result: Near real-time dashboard with 70% lower BigQuery costs

## Troubleshooting

### Issue: MV Not Being Used by Query Optimizer

**Symptoms**: Query still scans full events_* table despite MV existing.

**Causes**:
1. Query uses columns not in MV
2. Query date range exceeds MV partition range
3. MV refresh is stale (>24 hours old)

**Solution**:
```sql
-- Force MV usage by querying it directly
SELECT * FROM `project.dataset.daily_event_summary_mv`
WHERE ...
```

### Issue: MV Refresh Failures

**Symptoms**: `last_refresh_time` not updating.

**Causes**:
1. Base table schema changed
2. Insufficient BigQuery quota
3. MV query references dropped table

**Solution**:
1. Check BigQuery logs for errors:
   ```sql
   SELECT * FROM `project.region-us.INFORMATION_SCHEMA.JOBS`
   WHERE job_type = 'MATERIALIZED_VIEW_REFRESH'
     AND state = 'DONE'
     AND error_result IS NOT NULL
   ORDER BY creation_time DESC
   LIMIT 10;
   ```

2. Drop and recreate MV if schema incompatible

### Issue: Revenue Discrepancies

**Symptoms**: MV revenue doesn't match order system.

**Validation**:
Run validation queries in each MV file to compare vs base table.

**Common Causes**:
1. Duplicate transaction_ids in GA4 (see TROUBLESHOOTING.md)
2. Time zone mismatches (GA4 uses UTC)
3. Refunds not accounted for

**Solution**: Run revenue reconciliation query (see `sql/data-quality-monitoring/`)

## Best Practices

### ✅ Do

- **Partition MVs** by date for faster refresh and querying
- **Cluster on high-cardinality columns** (event_name, item_id)
- **Set appropriate refresh intervals** (balance freshness vs cost)
- **Monitor refresh lag** (should be <1 hour typically)
- **Use MVs for dashboard data sources** (query directly, not base table)

### ❌ Don't

- **Over-refresh**: 15-minute intervals cost 4x more than hourly
- **Include raw event_timestamp**: Defeats aggregation purpose
- **Create MVs for one-time queries**: Use only for repeated reports
- **Ignore validation**: Run validation queries monthly to catch drift

## References

1. [Google Cloud: Materialized Views Best Practices](https://cloud.google.com/bigquery/docs/materialized-views-use)
2. [OWOX: BigQuery Materialized Views Guide](https://www.owox.com/blog/articles/bigquery-materialized-views)
3. [Google Cloud Blog: Modernizing Materialized Views](https://cloud.google.com/blog/products/data-analytics/bigquery-materialized-views-now-ga)
4. [BigQuery Docs: Create Materialized Views](https://cloud.google.com/bigquery/docs/materialized-views-create)

---

**Questions or issues?** Open a GitHub issue or refer to `TROUBLESHOOTING.md` for common MV problems.
