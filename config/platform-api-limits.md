# Platform API Limits

## HubSpot
- 100 requests / 10 seconds per app (sliding window)
- Batch endpoints count per object; avoid loops in Looker Studio community connector

## Google Analytics 4
- Quota: 25,000 requests/day per property via Data API
- Concurrency: 10 requests/user at a time
- Sampling: avoid >10 dimensions + 10 metrics per call

## LinkedIn Ads (Porter Metrics)
- API quota handled by connector; refresh once daily at 03:00 UTC
- Avoid hitting rate limits by limiting date range to 365 days

## Instantly
- Webhook retries: 5 attempts with exponential backoff
- Sheets sync: 60 requests/minute recommended limit

## General Guidance
- Use caching where possible (BigQuery or Sheets staging)
- Add backoff + jitter when polling APIs
- Document quota ownership (client vs your credentials)
