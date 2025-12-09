---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# HubSpot Connector Setup (Looker Studio)

**Time:** 10 minutes

1. Open Looker Studio → **Create** → **Data Source**.
2. Search for **HubSpot** connector (Supermetrics/Coupler ok). Click **Authorize**.
3. Log in with client HubSpot account or Private App token.
4. Select required objects: Contacts, Deals, Companies, Engagements.
5. Under **Fields**, include custom properties needed for reporting (lifecycle stage, lead source, owner).
6. Set **Time zone** to client HQ timezone.
7. Name the data source `HubSpot - [Client] - [Environment]`.
8. Click **Connect** → verify sample rows populate.
9. In report, add a table with `create_date` and `lifecycle_stage` to confirm values.
10. Document connector owner and billing account in `config/connector-pricing.md`.
