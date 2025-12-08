# eCommerce Platform Implementation Guide

## Platform-Specific Considerations

| Platform | Implementation Method | Checkout Access | Technical Difficulty | Best For |
|----------|----------------------|-----------------|---------------------|----------|
| Shopify | Liquid templates | Plus tier only | Medium | Fast deployment, standard stores |
| Shopify Plus | Full checkout.liquid access | Yes | Medium-High | Custom checkout flows |
| WooCommerce | PHP hooks in functions.php | Yes | Medium | WordPress sites, full control |
| Magento | PHTML templates + observers | Yes | High | Enterprise, complex catalogs |
| BigCommerce | Stencil handlebars templates | Limited | Medium | Scalable, B2B features |
| Custom PHP/JS | Direct dataLayer implementation | Yes | Low | Complete flexibility |

## Common Implementation Challenges

### Challenge 1: Transaction ID Deduplication
**Problem**: Purchase event fires multiple times when user refreshes thank-you page
**Solution**: 
- Shopify: Check `{% if first_time_accessed %}` flag
- WooCommerce: Use `get_post_meta()` to track fired events
- Client-side: GTM Custom JavaScript variable checking sessionStorage

### Challenge 2: Currency Formatting
**Problem**: European stores use comma decimals (99,99) breaking numeric value parameters
**Solution**: Always use `money_without_currency` filters and parse with `parseFloat()`

### Challenge 3: Missing SKUs
**Problem**: Products without SKU cause item_id to be empty
**Solution**: Fallback logic: SKU → Product ID → Variant ID

### Challenge 4: AJAX Add-to-Cart
**Problem**: Standard page submission events don't fire on AJAX cart updates
**Solution**: Hook into platform-specific AJAX success callbacks
- Shopify: `theme.js` cart update functions
- WooCommerce: `added_to_cart` jQuery event
- Magento: `customer-data.reload` event listener
