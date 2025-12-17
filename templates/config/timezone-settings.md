---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Timezone Settings

Document timezone alignment before reconciliation to avoid false variance.

| Platform | Setting | Where to Configure | Notes |
|----------|---------|--------------------|-------|
| GA4 | Property time zone | Admin → Property Settings | Match client HQ timezone
| HubSpot | Account time zone | Settings → Account Defaults | Affects report timestamps
| LinkedIn Ads | Account time zone | Campaign Manager → Settings | Cannot change after creation
| Instantly | Campaign timezone | Campaign Settings | Ensure Sheets export matches GA4
| Looker Studio | Data source timezone | Data Source → *Data freshness* | Align with source system |

**Process:**
1. Capture client HQ timezone during kickoff.
2. Align GA4 + HubSpot first; then connectors and Looker Studio.
3. Document any exceptions in the reconciliation workbook.
