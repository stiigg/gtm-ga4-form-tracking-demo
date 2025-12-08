# GTM/GA4 Multi-Platform Dashboard - Production Repository

## What This Repository Is For

This is my **production toolkit** for building multi-platform marketing dashboards for clients. Everything here is client-ready, battle-tested, and actively maintained.

**If you're a potential client**: This repo shows my standard implementation. Your project will use these exact templates, customized for your platforms.

**If you're a freelancer/developer**: You're welcome to fork and adapt this for your own projects (MIT licensed).

## What's Included

### Client-Ready Templates (`/client-templates/`)
- Reconciliation workbook (explains variance across platforms; Markdown tables ready for Sheets/Excel import)
- UTM parameter validation template (prevents tagging errors; copy-friendly for data validation lists)
- GTM container export (my standard setup)
- Project kickoff checklists (what I ask every client)

### Production Code (`/snippets/`)
- dataLayer implementations (form tracking, e-commerce)
- Looker Studio calculated fields (conversion rates, variance %)
- BigQuery validation queries (SQL to compare GA4 vs CRM data)
- GTM variable configurations (copy-paste for each project)

### Standard Operating Procedures (`/sops/`)
- HubSpot connector setup (step-by-step)
- LinkedIn Ads via Porter Metrics ($19/month)
- Instantly.ai Google Sheets integration
- Looker Studio dashboard cloning process

### Troubleshooting Database (`/troubleshooting-database/`)
- GTM events not firing (15 common fixes)
- Variance out of acceptable range (investigation checklist)
- API quota exceeded (HubSpot, GA4 limits)
- Connector refresh failures

### Delivery Package (`/delivery-package/`)
- Client user guide (non-technical)
- Maintenance checklist (what client does monthly)
- Video walkthrough script template
- Handoff documentation

## Live Demo

**Working Example**: https://stiigg.github.io/gtm-ga4-form-tracking-demo/  
**Looker Studio Template**: [Link to copyable dashboard - Coming Soon]

## Technology Stack

**Platforms Integrated**:
- Google Analytics 4 (GA4) - Event tracking
- Google Tag Manager (GTM) - Tag management
- HubSpot CRM - Contacts, deals, lifecycle stages
- LinkedIn Ads - Campaign performance (via Porter Metrics)
- Instantly.ai - Email outreach metrics (via Google Sheets)

**Dashboard Platform**: Looker Studio (formerly Google Data Studio)  
**Data Warehouse** (advanced clients): BigQuery with daily GA4 export

## Typical Project Timeline

| Phase | Duration | What Happens |
|-------|----------|---------------|
| Kickoff call | 30 min | Collect requirements, credentials, scope confirmation |
| Connector setup | Day 1 | Configure GA4, HubSpot, LinkedIn, Instantly connections |
| Dashboard build | Day 2 | Build Looker Studio pages, filters, calculated fields |
| Validation | Day 2-3 | Cross-platform number comparison, reconciliation |
| Client preview | Day 3 | Share dashboard link, collect feedback |
| Revision round | Day 4 | Implement requested changes |
| Final delivery | Day 5 | Documentation, video walkthrough, handoff |

**Total**: 3-5 business days from credentials to final delivery

## Current Pricing

**Base Package** ($50 Upwork special):
- 4-platform integration (GA4, HubSpot, LinkedIn, Instantly)
- Single-page overview dashboard
- Reconciliation workbook with variance documentation
- One revision round
- Video walkthrough + user guide

**Add-Ons** (see `/pricing-templates/addons-menu.md`):
- Additional platforms: $40 each
- Platform deep-dive pages: $20 per page
- Custom calculated fields: $15 each
- Monthly monitoring: $100/month

## Using This Repository for Your Projects

### For Client Projects
1. Clone this repo to your local machine
2. Copy `/client-templates/` folder for each new project
3. Follow SOPs in `/sops/` folder for connector setup
4. Use `/snippets/` code in client websites
5. Deliver `/delivery-package/` documentation with dashboard

### For Learning/Portfolio
- Fork the repository
- Deploy live demo to your own GitHub Pages
- Customize for your use cases
- Link in your Upwork/freelance profiles

## Configuration Required

**Important**: This demo uses placeholder IDs. See [CONFIGURATION.md](CONFIGURATION.md) for:
- How to get your own GTM Container ID
- GA4 Measurement ID setup
- Connector API key configuration

## Support & Inquiries

**Hire me for dashboard work**:  
- Upwork: [your-upwork-profile]  
- Email: [your-email]  
- Portfolio: [your-website]

**Technical questions about this repo**:  
- Open a GitHub Issue
- Or discussion in Discussions tab

**Response time**: 24-48 hours on weekdays

## License

MIT License - You're free to use this in your own client projects, with attribution appreciated but not required.

---

**Last Updated**: December 2025  
**Maintained by**: [Your Name]  
**Production Status**: ✅ Actively used in 10+ client projects
