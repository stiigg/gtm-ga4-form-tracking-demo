---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Looker Studio Data Not Refreshing

1. **Check Connector Status**: Open data source → see if errors appear at top.
2. **Refresh Window**: Free connectors refresh every 12-24 hours; wait if within window.
3. **Credentials**: Re-authenticate connectors after password/API token changes.
4. **Data Limits**: Reduce date range to avoid hitting API quotas (see `config/platform-api-limits.md`).
5. **Blended Data**: If using blends, ensure join keys exist on both sides for new dates.
6. **Cache**: Clear report cache: Resource → Manage added data sources → Refresh Fields.
7. **Alerts**: Set email alerts for connector failures where supported (Supermetrics/Porter).
