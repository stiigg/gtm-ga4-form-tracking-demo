---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Cross-Domain Tracking Setup Guide

## When You Need This
- Main store on `shop.example.com`, checkout on `checkout.example.com`
- Multiple brand sites sharing a central cart
- Third-party payment processors (Stripe, PayPal) returning to confirmation page
- Affiliate tracking across partner domains

## GTM Configuration Steps

### 1. GA4 Configuration Tag Settings
```
Fields to Set:
- linker → domains: checkout.example.com,payment.example.com
- cookie_domain: auto
- cookie_flags: samesite=none;secure
```

### 2. Create Linker Variable
**Variable Type**: GTM Variable - URL (Auto-Link Domains)
**Name**: `Cross-Domain Linker`
**Domains**: `checkout.example.com`, `payment.example.com`
**Use Hash as Delimiter**: ✓ Checked
**Decorate Forms**: ✓ Checked

### 3. Validation Checklist
- [ ] GA4 debug mode shows consistent `user_id` across domains
- [ ] URL contains `_gl=` parameter when navigating between domains
- [ ] Cookie `_ga` has same value on both domains (check DevTools → Application → Cookies)
- [ ] GTM Preview Mode shows Configuration tag firing on both domains
- [ ] User journey in GA4 Realtime report doesn't show separate sessions

## Common Failure Modes

### Issue 1: _gl Parameter Stripped
**Symptoms**: Parameter visible in network tab but removed before page load
**Causes**:
- Payment processor sanitizes URL parameters
- Server-side redirects without preserving query strings
- Ad blockers removing tracking parameters

**Solution**: 
- Contact payment processor for allowlist request
- Use POST method with hidden form field for `_gl` value
- Implement server-side cookie reading/writing

### Issue 2: Cookies Not Shared
**Symptoms**: Different `_ga` cookie values on subdomains
**Cause**: `cookie_domain` not set to parent domain

**Solution**:
```
// GTM Custom HTML tag - Fire on All Pages
<script>
gtag('config', 'G-XXXXXXXXXX', {
  'cookie_domain': '.example.com',  // Note the leading dot
  'cookie_flags': 'SameSite=None;Secure'
});
</script>
```

### Issue 3: Session Break on Protocol Change
**Symptoms**: HTTP → HTTPS transition creates new session
**Solution**: Ensure both domains use HTTPS exclusively

## Testing Methodology

### Manual Test Flow
1. Open GTM Preview on Domain A
2. Add product to cart
3. Note `_ga` cookie value (DevTools → Application)
4. Click checkout (navigates to Domain B)
5. Verify `_gl` parameter in URL
6. Check `_ga` cookie matches Domain A value
7. Complete purchase
8. Check GA4 Realtime: should show single user journey

### Automated Testing Script
See `/qa-checklists/cross-domain-test.js` for Puppeteer script
