---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# LinkedIn Ads → Porter Metrics → Looker Studio Setup

**Time: 15 minutes**  
**Cost: $19/month (client pays)**  
**Client needs: LinkedIn Campaign Manager access**

## Step 1: Create Porter Account (5 min)
1. Go to portermetrics.com
2. Sign up with client email (they should own this account)
3. Select "LinkedIn Ads" connector
4. Choose "$19/month" plan (or bill client separately)
5. Payment method → Client credit card

## Step 2: Connect LinkedIn (3 min)
1. Porter dashboard → "Add Data Source"
2. Select "LinkedIn Ads"
3. Click "Authorize" → redirects to LinkedIn login
4. Log in with client LinkedIn Campaign Manager credentials
5. Accept permissions
6. Porter shows "Connected" with green checkmark

## Step 3: Configure Data Pull (2 min)
1. Select campaigns to sync (usually "All")
2. Date range: "Last 90 days" (can extend to 365 if needed)
3. Refresh frequency: "Daily" (happens at 3am UTC)
4. Metrics to include:
   - ✓ Impressions
   - ✓ Clicks
   - ✓ Spend
   - ✓ Conversions (if LinkedIn Insight Tag installed)
   - ✓ CTR (calculated metric)

## Step 4: Connect to Looker Studio (5 min)
1. Open Looker Studio
2. "Create" → "Data Source"
3. Search "Porter Metrics"
4. Authorize with Porter credentials
5. Select LinkedIn Ads data source
6. Click "Connect"
7. Verify columns appear: campaign_name, impressions, clicks, spend, date

## Step 5: Validation (5 min)
1. In Looker Studio, create simple table:
   - Dimension: campaign_name
   - Metrics: impressions, clicks, spend
   - Date range: Last 7 days
2. Open LinkedIn Campaign Manager
3. Compare total spend for last 7 days
4. Numbers should match exactly (±$0.01 for rounding)
5. If mismatch: Check timezone settings, refresh timing

## Troubleshooting
- **"No data appearing"**: Wait 24 hours for first sync
- **"Authorization failed"**: Client needs Campaign Manager role (not just View)
- **"Conversion count = 0"**: LinkedIn Insight Tag not installed on client site
- **"Spend mismatch"**: Check currency settings (USD vs EUR vs GBP)

## What to Tell Client
"I've connected your LinkedIn Ads to the dashboard via Porter Metrics ($19/month, billed to you). Data refreshes daily at 3am UTC, so yesterday's numbers appear this morning. The dashboard shows all active campaigns automatically—no need to update anything when you launch new campaigns."
