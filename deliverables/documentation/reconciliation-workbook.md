---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Reconciliation Workbook (Client-Ready Template)

Use this workbook to document and reconcile cross-platform metrics (GA4, HubSpot, LinkedIn Ads, Instantly). Each section mirrors a sheet in the original Excel template so it can be copied into Google Sheets or Excel without binaries.

## Sheet 1 — Executive Summary
| Date Range | Platform | Metric | Value | Notes |
|------------|----------|--------|-------|-------|
| 2025-01-01 to 2025-01-31 | GA4 | Leads | 450 | Example placeholder |
| 2025-01-01 to 2025-01-31 | HubSpot | Form Submissions | 387 | Example placeholder |
| 2025-01-01 to 2025-01-31 | LinkedIn Ads | Conversions | 112 | Example placeholder |

## Sheet 2 — Variance Analysis
| Metric | GA4 | HubSpot | Variance % | Status |
|--------|-----|---------|------------|--------|
| Form Submissions | 450 | 387 | 14% | ❌ Investigate |
| Deals Created | 78 | 75 | 4% | ✓ Within Range |

Variance guidance lives in `/config/expected-variance-ranges.md`.

## Sheet 3 — Investigation Notes
Use this log to track what you checked and what you found.

| Date | Owner | Issue | Check Performed | Result | Next Step |
|------|-------|-------|-----------------|--------|-----------|
| 2025-02-10 | Analyst | GA4 higher than HubSpot | Confirmed GA4 30-day lookback vs HubSpot first-touch | Expected 5–8% | Documented in workbook |

## Sheet 4 — Raw Pulls (Copy/Paste)
Paste raw exports or connector outputs here before aggregations. Keep one tab per platform if needed.

## Usage
1. Make a copy for each client.
2. Fill the tables above in Google Sheets or Excel (structure avoids binary files in repo).
3. Link this workbook in client documentation and delivery packages.
