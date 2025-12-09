---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Expected Variance Ranges

Use these ranges when clients ask why numbers differ across platforms. Document any deviations in the reconciliation workbook.

| Comparison | Expected Variance | Notes |
|------------|------------------|-------|
| GA4 events vs HubSpot forms | 0-5% | Attribution windows + bot filtering
| GA4 revenue vs LinkedIn spend | 0-2% | Currency rounding + refresh timing
| HubSpot contacts vs deals created | 0-10% | Deduplication + lifecycle timing
| GA4 vs Instantly sends | 0-5% | Webhook retries + timezone alignment

**If variance > 10%:** run the checklist in `troubleshooting-database/variance-out-of-range.md`.
