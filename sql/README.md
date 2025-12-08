# BigQuery SQL Query Library

## Setup Requirements
1. Enable BigQuery Export in GA4 Property Settings
2. Wait 24-48 hours for initial data export
3. Replace `PROJECT_ID` and `DATASET` placeholders in queries
4. Grant BigQuery Data Viewer role to analysis users

## Query Categories

### Revenue Analysis
- `ecommerce-analysis-queries.sql` → Revenue reconciliation, product performance
- Compare GA4 tracked revenue against source-of-truth (Shopify, WooCommerce orders table)

### Funnel Analysis
- View → Add to Cart → Checkout → Purchase progression
- Identify highest drop-off points requiring UX optimization

### Customer Segmentation
- Cart abandonment by traffic source (organic, paid, email)
- Customer lifetime value calculations
- New vs returning customer behavior

## Cost Management
**Important**: BigQuery charges by data scanned
- Each query on 30 days of data ≈ 10-50 MB scanned
- Free tier: 1 TB/month scanned
- Estimated cost for typical ecommerce site: $0-20/month

**Optimization Tips**:
- Always use `_TABLE_SUFFIX` partitioning in WHERE clause
- Select only needed columns (avoid `SELECT *`)
- Use `LIMIT` for exploratory queries
