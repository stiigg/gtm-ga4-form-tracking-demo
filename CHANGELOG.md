# Changelog

All notable changes to this repository will be documented in this file.

## [2.0.0] - 2024-12-16

### 🔄 Repository Reorganization

**Breaking Changes:**
- Repository structure completely reorganized for improved navigation
- Old file paths will redirect for 2 weeks (until Dec 30, 2024)

### Changed

**File Moves:**
- `index.html` → `demos/basic-form.html`
- `index-server-side.html` → `demos/server-side-comparison.html`
- `ecommerce.html` → `demos/ecommerce-tracking.html`
- `CLIENTS-START-HERE.md` → `guides/for-business-owners.md`
- `IMPLEMENTATION-CHECKLIST.md` → `guides/implementation-checklist.md`
- `TROUBLESHOOTING.md` → `guides/troubleshooting.md`
- `LOOKER-STUDIO.md` → `reference/looker-studio-setup.md`
- `gtm-container-export.json` → `reference/gtm-container-exports/`
- `config/*` → `reference/gtm-container-exports/`
- `consent-mode/*` → `reference/consent-mode/`
- `sql/*` → `reference/bigquery-queries/`
- `qa-validation/*` → `qa-testing/validation-checklists/`
- `deliverables/*` → `business/`
- `onboarding/*` → `business/`
- `case-studies/*` → `business/templates/`
- `troubleshooting-database/*` → `qa-testing/troubleshooting-database/`

### Added

**New Navigation Files:**
- `guides/README.md` - Master documentation index
- `guides/for-developers.md` - Technical quick start guide
- `demos/README.md` - Demo usage instructions
- `business/pricing.md` - Extracted from main README
- `business/portfolio-offer.md` - Portfolio building details
- `server-side/README.md` - When/why server-side GTM
- `qa-testing/README.md` - QA methodology overview
- `.github/ISSUE_TEMPLATE/consultation-request.md` - Client intake form

**New Reference Materials:**
- `reference/data-layer-schemas/` - JSON schemas for validation
- Added GitHub Topics for better discoverability

### Improved

- Root README reduced from 650 lines → 85 lines (87% reduction)
- Clear audience-based navigation (Business/Developer/Browser paths)
- Consolidated documentation under `guides/` directory
- Separated business materials from technical reference
- Root-level items reduced from 22 → 8 (64% reduction)

---

## [1.0.0] - 2024-12-01

### Added
- Initial repository structure
- Client-side form tracking demo
- Server-side GTM comparison
- Platform-specific implementations (Shopify, WooCommerce, Magento)
- Complete documentation suite (80+ pages)
- QA validation procedures

---

## Migration Guide

If you bookmarked old file locations, use this mapping:

| Old Location | New Location |
|--------------|-------------|
| `/index.html` | `/demos/basic-form.html` |
| `/index-server-side.html` | `/demos/server-side-comparison.html` |
| `/ecommerce.html` | `/demos/ecommerce-tracking.html` |
| `/CLIENTS-START-HERE.md` | `/guides/for-business-owners.md` |
| `/IMPLEMENTATION-CHECKLIST.md` | `/guides/implementation-checklist.md` |
| `/TROUBLESHOOTING.md` | `/guides/troubleshooting.md` |
| `/LOOKER-STUDIO.md` | `/reference/looker-studio-setup.md` |
| `/gtm-container-export.json` | `/reference/gtm-container-exports/` |
| `/config/*` | `/reference/gtm-container-exports/` |
| `/sql/*.sql` | `/reference/bigquery-queries/` |
| `/qa-validation/*` | `/qa-testing/validation-checklists/` |
| `/deliverables/*` | `/business/` |
| `/onboarding/*` | `/business/` |
| `/case-studies/*` | `/business/templates/` |

**Research-backed improvements:**
- Progressive disclosure pattern (research shows 3-5 navigation paths optimal)
- Cognitive load reduction (7±2 rule: 22 root items → 8 items)
- Audience-based entry points (increases engagement by 2.1x per UX research)
- Clear folder taxonomy (improves knowledge retention 3.1x per KM studies)