---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# UTM Parameters Template (Dropdown-Ready)

Use these tables as validation sources in Google Sheets or Excel Data Validation. Copy each column into its own sheet or range to enable dropdowns for consistent tagging.

## Sheet 1 — Standard UTM Fields
| Parameter | Example Value | Notes |
|-----------|---------------|-------|
| utm_source | linkedin | Required |
| utm_medium | cpc | Required |
| utm_campaign | q1_brand_awareness | Required |
| utm_content | ad_variation_a | Optional |
| utm_term | sales_automation | Optional |

## Sheet 2 — Approved Sources
| utm_source |
|------------|
| linkedin |
| google |
| meta |
| email |
| newsletter |
| referral |

## Sheet 3 — Approved Mediums
| utm_medium |
|------------|
| cpc |
| paid_social |
| email |
| organic |
| referral |

## Sheet 4 — Campaign Naming Pattern
Use this pattern for validation or conditional formatting.

```
[quarter]_[goal]_[offer]
# Examples: q1_brand_awareness, q2_leadgen_demo, q3_retention_onboarding
```

## Usage
1. Copy each table into a Google Sheet and apply Data Validation → List from range.
2. Share with marketing teams to enforce consistent tagging.
3. Keep this markdown as the source of truth in git (no binary files required).
