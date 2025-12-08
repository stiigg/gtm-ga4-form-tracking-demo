# BigQuery GA4 Export Setup

1. In GA4 Admin → **BigQuery Linking** → Click **Link**.
2. Select the correct Google Cloud project (client-owned preferred).
3. Choose **Daily** export; enable **Streaming** only if required.
4. Confirm dataset location (match client's data residency requirements).
5. Naming convention: dataset `ga4_[property_name]`.
6. Verify export after 24 hours: check `events_YYYYMMDD` table populated.
7. Grant BigQuery access to Looker Studio service account if using direct connector.
8. Set up cost monitoring on the project to avoid surprise charges.
9. Document project ID and dataset in `CONFIGURATION.md` and client folder.
