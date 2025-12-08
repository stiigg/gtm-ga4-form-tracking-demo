# Technical Requirements Check

Run this before building to avoid mid-project blockers.

## Tagging Prerequisites
- [ ] GTM installed on all pages (head + body snippets present)
- [ ] GA4 Configuration tag published or prepared
- [ ] dataLayer available for custom pushes

## Platform Availability
- [ ] HubSpot objects accessible (Contacts/Deals)
- [ ] LinkedIn Ads account active with at least one campaign
- [ ] Instantly campaigns active with webhook access

## Data Warehouse (optional)
- [ ] BigQuery project + billing active
- [ ] GA4 export enabled and dataset reachable
- [ ] Service account for scheduled queries

## Security
- [ ] Confirm who owns credentials and billing
- [ ] Access will be revoked after delivery if requested
- [ ] Ensure PII handling documented (form fields sanitized)
