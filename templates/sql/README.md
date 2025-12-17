# BigQuery SQL Analysis Queries

Production-ready SQL queries for GA4 data analysis in BigQuery.

## Prerequisites

1. **GA4 BigQuery Export enabled**: Admin → Data Settings → BigQuery Linking
2. **Project and dataset IDs**: Replace placeholders in queries
3. **Source system data**: For reconciliation, connect Shopify/WooCommerce to BigQuery

## Query Descriptions

### revenue-reconciliation.sql
**Purpose:** Validate GA4 tracking accuracy vs source of truth  
**Use case:** Weekly data quality checks, identify tracking gaps  
**Runtime:** ~10 seconds for 7 days of data  
**Cost:** ~$0.05 per run (depends on data volume)

**Key Metrics:**
- Revenue variance between GA4 and orders
- Transaction count discrepancies
- Duplicate event detection

### product-affinity-analysis.sql
**Purpose:** Identify products frequently purchased together  
**Use case:** Cross-sell recommendations, bundle creation  
**Runtime:** ~30 seconds for 90 days of data  
**Cost:** ~$0.15 per run

**Key Metrics:**
- Co-purchase frequency
- Affinity lift (statistical correlation)
- Average bundle value

### customer-lifetime-value.sql
**Purpose:** Calculate per-user CLV and segment customers  
**Use case:** Retention strategy, marketing spend allocation  
**Runtime:** ~45 seconds for 365 days of data  
**Cost:** ~$0.25 per run

**Key Metrics:**
- Lifetime value per customer
- Purchase frequency
- RFM-based segmentation

## Usage Examples

### Running in BigQuery Console

```
-- 1. Open BigQuery console
-- 2. Copy query content
-- 3. Replace placeholders:
--    YOUR_PROJECT → your-project-id
--    analytics_XXXXX → your GA4 dataset (e.g., analytics_123456789)
--    shopify_dataset → your order data dataset
-- 4. Click "Run"
```

### Scheduling Queries

```
-- Create scheduled query for daily reconciliation
-- BigQuery Console → Scheduled Queries → Create

-- Schedule: Daily at 9 AM
-- Destination: reconciliation_results table
-- Notification: Email on failure
```

### Exporting Results

```
# Export to CSV via bq CLI
bq query --format=csv --use_legacy_sql=false \
  "$(cat sql/revenue-reconciliation.sql)" \
  > revenue_report_$(date +%Y%m%d).csv
```

## Customization Guide

### Adjusting Date Ranges

```
-- Change from 7 days to 30 days
DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)  -- Original
DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) -- Modified
```

### Adding Custom Dimensions

```
-- Add traffic source to revenue query
, traffic_source.source AS traffic_source
, traffic_source.medium AS traffic_medium

-- Then add to GROUP BY
GROUP BY date, traffic_source, traffic_medium
```

### Filtering by Product Category

```
-- Add WHERE clause after UNNEST
WHERE items.item_category = 'software'
```

## Performance Optimization

### Partitioning Strategy
GA4 tables are partitioned by `_TABLE_SUFFIX` (date). Always filter by date for cost efficiency:

```
-- Good (scans only 7 days)
WHERE _TABLE_SUFFIX BETWEEN '20241201' AND '20241207'

-- Bad (scans entire dataset)
WHERE PARSE_DATE('%Y%m%d', event_date) > '2024-12-01'
```

### Cost Estimation
```
-- Check bytes scanned before running
SELECT
  SUM(size_bytes) / POW(10, 9) AS gb_to_scan
FROM `YOUR_PROJECT.analytics_XXXXX.__TABLES__`
WHERE table_id BETWEEN 'events_20241201' AND 'events_20241207';

-- Cost = GB scanned × $0.006/GB
```

## Troubleshooting

### Error: "Cannot access table"
**Solution:** Grant BigQuery Data Viewer role to your account

### Error: "Resources exceeded during query execution"
**Solution:** Add date filters, reduce query complexity, or upgrade BigQuery slot allocation

### No results returned
**Solution:** Verify GA4 BigQuery export is working (check table update timestamp)

## Additional Resources

- [GA4 BigQuery Export Schema](https://support.google.com/analytics/answer/7029846)
- [BigQuery SQL Reference](https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax)
- [GA4 eCommerce Events](https://developers.google.com/analytics/devguides/collection/ga4/ecommerce)
