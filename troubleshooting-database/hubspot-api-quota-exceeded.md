---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# HubSpot API Quota Exceeded

1. **Identify Offending App**: HubSpot → Settings → Integrations → API Usage; note which app is over limit.
2. **Throttle Requests**: Reduce sync frequency in connector (Supermetrics/Porter) to hourly/daily.
3. **Batch Requests**: Use bulk endpoints where possible to minimize calls.
4. **Prioritize Metrics**: Limit Looker Studio queries to required fields to cut volume.
5. **Schedule Windows**: Run heavy jobs during off-peak hours to avoid stacking with other apps.
6. **Request Increase**: If needed, contact HubSpot support with use case; document in client notes.
7. **Communicate**: Inform client of delay and expected recovery time; update reconciliation workbook.
