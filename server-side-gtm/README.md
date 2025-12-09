# Server-Side GTM for eCommerce: Complete Implementation Toolkit

## Critical Problem This Solves

Your eCommerce store is losing 30-40% of conversion data due to:
- Browser ad blockers (used by 30% of users)
- iOS Safari Intelligent Tracking Prevention (7-day cookie expiration)
- Firefox Enhanced Tracking Protection
- Chrome's ongoing third-party cookie deprecation

**Business Impact Example:**
$200K annual revenue store → $60-80K invisible to attribution
→ Marketing decisions based on incomplete data
→ 15-25% lower ROAS on Meta/Google Ads

## What is Server-Side Tagging?

[Include visual diagram: Browser → Client GTM → Server GTM → GA4/Meta/Google Ads]

**Traditional (Client-Side):**
JavaScript in user's browser sends data directly to Google/Facebook
- ❌ 30-40% blocked by privacy tools
- ❌ Cookies expire in 7 days (Safari)
- ❌ No control over data before sharing

**Server-Side:**
Your server receives data first, then forwards to analytics platforms
- ✅ 90-95% capture rate
- ✅ Cookies persist 2 years
- ✅ Filter PII, enrich data before sending

## Repository Contents

### Platform-Specific Guides
- [Shopify + Stape Setup](platform-implementations/shopify-stape-setup.md) - **START HERE** (most common)
- [WooCommerce + GCP Self-Hosted](platform-implementations/woocommerce-gcp-setup.md)
- [Magento 2 Server-Side](platform-implementations/magento-observer-setup.md)

### Infrastructure Options
- [Google Cloud Run Deployment](infrastructure/google-cloud-run-setup.md)
- [Stape Managed Hosting](infrastructure/stape-managed-comparison.md)
- [Cost Comparison Calculator](infrastructure/cost-comparison.xlsx)

### Conversions API Integrations
- [Meta (Facebook) CAPI](conversions-api/meta-capi-complete-setup.md)
- [Deduplication Logic](conversions-api/meta-capi-deduplication-logic.md) - **CRITICAL**
- [Google Enhanced Conversions](conversions-api/google-enhanced-conversions.md)

### Testing & Validation
- [Complete QA Checklist](testing-validation/sgtm-qa-complete-checklist.md)
- [Revenue Reconciliation Queries](testing-validation/revenue-reconciliation-sgtm.sql)
- [Debugging Guide](testing-validation/debugging-common-issues.md)

## Quick Start

**If you're a business owner:** Read [Cost-Benefit Calculator](COST-BENEFIT-CALCULATOR.md) first

**If you're implementing for Shopify:** Start with [Shopify + Stape Guide](platform-implementations/shopify-stape-setup.md)

**If you're technical/self-hosting:** Start with [Google Cloud Run Setup](infrastructure/google-cloud-run-setup.md)

## When Should You Implement Server-Side?

### ✅ Strong Indicators
- Monthly revenue >$50K
- Ad spend >$5K/month (Meta + Google)
- iOS/Safari traffic >30%
- Using Facebook/Meta Ads (CAPI required for accuracy)
- Multi-session purchase cycle

### ⚠️ Maybe Wait
- Monthly revenue <$10K
- Ad spend <$2K/month
- 100% B2B with known customer list (privacy less critical)

### Cost-Benefit Examples

**Scenario 1: $30K/month Shopify Store**
- Current tracking: 65% accuracy
- With sGTM: 92% accuracy (+27%)
- Monthly benefit: $8,400 recovered attribution
- Stape cost: $40/month
- **ROI: 210x**

**Scenario 2: $200K/month WooCommerce**
- Self-hosted GCP: $180/month
- Recovered attribution: ~$50K/month
- **ROI: 278x**

[See full calculator →](COST-BENEFIT-CALCULATOR.md)
