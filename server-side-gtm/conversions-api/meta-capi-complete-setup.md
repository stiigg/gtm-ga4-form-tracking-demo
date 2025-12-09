# Meta Conversions API: Complete Server-Side Setup

This guide walks through configuring Meta CAPI inside a server-side GTM container with proper deduplication and validation.

## 1) Business Manager Prerequisites
- Admin access to **Meta Business Manager** and Pixel
- Generate a **System User Access Token** with `ads_management` + `business_management`
- Note your **Pixel ID** and **Test Event Code** for validation

## 2) Event Parameter Mapping: GA4 → Meta CAPI

| GA4 Parameter | Meta Parameter | Transformation | Required? |
|---------------|----------------|----------------|-----------|
| event_name | event_name | Map to Meta standard | ✅ Yes |
| event_timestamp | event_time | Convert to Unix seconds | ✅ Yes |
| user_data.email | user_data.em | SHA-256 hash | ⚠️ Recommended |
| user_data.phone | user_data.ph | E.164 format + SHA-256 | ⚠️ Recommended |
| ecommerce.value | custom_data.value | Forward directly | ✅ Yes |
| ecommerce.currency | custom_data.currency | Forward directly | ✅ Yes |
| ecommerce.items[].item_id | custom_data.content_ids | Extract to array | ✅ Yes |
| client_ip_address | user_data.client_ip_address | Forward from request | ✅ Yes |
| user_agent | user_data.client_user_agent | Forward from request | ✅ Yes |

**PII Hashing Example:**
```javascript
// Custom JavaScript variable in GTM Server
function() {
  const email = {{Event Parameter - email}};
  if (!email) return undefined;
  
  // SHA-256 hashing
  const crypto = require('crypto');
  return crypto.createHash('sha256')
    .update(email.toLowerCase().trim())
    .digest('hex');
}
```

## 3) Deduplication with Pixel
- Pass the same **`event_id`** from the client (web pixel) into the server event.
- In Meta Events Manager, enable **CAPI + Pixel** deduplication.
- Confirm both events show the same `event_id` in the Test Events debugger.

## 4) Server-Side Tag Configuration
1. Add the **Meta Conversions API** template from the GTM Community Template Gallery.
2. Set **Pixel ID** and **Access Token** (store token in GTM variable or Stape secret).
3. Map parameters per the table above; include `event_id` for deduplication.
4. Send **client IP** and **user agent** from incoming request headers for better matching.
5. Optionally enable **Event Match Quality** logging to validate hashing.

## 5) Validation Procedures
- **Meta Test Events**: Send test traffic and confirm deduplicated events (Pixel + CAPI) with green check.
- **GA4 vs Meta counts**: Compare purchase counts over 24 hours; expect 90-95% alignment when deduping correctly.
- **BigQuery duplicate check**: Run the query in `../testing-validation/deduplication-audit-query.sql` to ensure a single purchase per transaction.

## Common Pitfalls
- Missing `event_id` sync between client/server → duplicate purchases.
- Not hashing email/phone → lower match quality scores.
- Blocking CORS/headers on Shopify webhooks → missing IP/user agent data.

## Next Actions
- Finish Shopify setup via [Shopify + Stape guide](../platform-implementations/shopify-stape-setup.md).
- Configure Google Enhanced Conversions in parallel to improve Google Ads matching.
