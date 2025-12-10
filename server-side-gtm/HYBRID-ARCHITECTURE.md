# Hybrid Client/Server Architecture (Recommended)

## Why Pure Server-Side Usually Fails

**What documentation promises:**
- Move ALL tracking server-side
- Bypass ALL ad blockers
- Perfect attribution

**What production reveals:**
- Server loses browser context (viewport, screen resolution, timezone)
- Server can't detect scroll depth, element visibility
- Server misses UTM parameters (unless manually forwarded)
- Server attribution actually WORSE than client-side for some stores

## The Hybrid Solution

### Client-Side Responsibilities
1. **Page context events:**
   - `page_view` with viewport, screen size
   - `scroll` (if tracking engagement)
   - `file_download`, `outbound_click`
   - Auto-captured UTM parameters

2. **Cookie management:**
   - Write `_ga` cookie
   - Store attribution in localStorage
   - Manage consent mode

### Server-Side Responsibilities
1. **Conversion events (bypass ad blockers):**
   - `purchase` (from webhook)
   - `add_to_cart` (from webhook)
   - `begin_checkout` (from webhook)

2. **Enhanced conversions:**
   - SHA256 hashed email/phone
   - Server-to-server Meta CAPI
   - Google Enhanced Conversions

3. **Data enrichment:**
   - Customer Lifetime Value lookup
   - Product inventory status
   - Real-time pricing updates

## Implementation Pattern

### Client GTM Container

**Tag 1: GA4 Configuration** (ALL pages)
```
Tag Type: GA4 Configuration
Measurement ID: G-XXXXXXXXX
Server Container URL: https://track.yourstore.com
Cookie Strategy: First-party (auto)
```

**Tag 2: Page View Tracking** (ALL pages)
```
Tag Type: GA4 Event
Event Name: page_view
Send to: GA4 Configuration Tag (client-side)

// Include automatically:
- page_location
- page_title  
- screen_resolution
- viewport_size
```

**Tag 3: Forward Attribution to Server** (ALL pages, fires once per session)
```
Tag Type: Custom HTML

<script>
// Store UTM + referrer for server container
var attribution = {
  utm_source: {{URL - utm_source}},
  utm_medium: {{URL - utm_medium}},
  utm_campaign: {{URL - utm_campaign}},
  gclid: {{URL - gclid}},
  fbclid: {{URL - fbclid}},
  original_referrer: {{Referrer}}
};

// Send to server container
fetch('https://track.yourstore.com/attribution', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify(attribution)
});

// Also store locally for backup
sessionStorage.setItem('attribution', JSON.stringify(attribution));
</script>

Trigger: Page View (fire once per session)
```

### Server GTM Container

**Tag 1: GA4 Purchase Event** (webhook trigger)
```
Tag Type: GA4 Event
Event Name: purchase
Server Container: This container
Event Parameters:
  - transaction_id: {{Event Parameter - order_id}}
  - value: {{Event Parameter - total_price}}
  - currency: {{Event Parameter - currency}}
  - items: {{Event Parameter - line_items}}
  
  // Attribution from stored session data
  - utm_source: {{Session Storage - attribution.utm_source}}
  - utm_medium: {{Session Storage - attribution.utm_medium}}
  
Trigger: Shopify Order Created (webhook)
```

**Tag 2: Meta CAPI Purchase** (webhook trigger)
```
Tag Type: Facebook Conversions API Tag (community template)
Event Name: Purchase
Access Token: {{Meta CAPI Token}}
Pixel ID: {{Facebook Pixel ID}}

Event ID: {{Event Parameter - order_id}}_client_web
// CRITICAL: Must match client-side event_id

Event Parameters:
  - value: {{Event Parameter - total_price}}
  - currency: {{Event Parameter - currency}}
  - content_ids: {{Event Parameter - product_ids}}
  
User Data:
  - em: {{Event Parameter - customer_email_hashed}}
  - ph: {{Event Parameter - customer_phone_hashed}}
  - client_ip_address: {{HTTP Header - X-Forwarded-For}}
  - client_user_agent: {{HTTP Header - User-Agent}}
```

## Traffic Split Expected

**Typical hybrid deployment:**
- 60-70% events from client container (pageviews, clicks)
- 30-40% events from server container (conversions, webhooks)
- 100% purchases tracked by BOTH (deduplicated)

## Validation Checklist

### Client-Side Working
- [ ] GA4 DebugView shows page_view events with device info
- [ ] Scroll depth tracked (if enabled)
- [ ] UTM parameters visible in DebugView event details

### Server-Side Working
- [ ] Stape logs show webhook delivery 100% success rate
- [ ] GA4 DebugView shows purchase events from server (different client_id)
- [ ] Purchase has UTM attribution (forwarded from client)

### Deduplication Working
- [ ] BigQuery shows exactly 1 purchase per transaction_id
- [ ] Meta Events Manager shows "Deduplicated" status on server purchases
- [ ] Total conversion count matches order system (not doubled)

## Cost-Benefit Analysis

**Client-only setup:**
- Implementation: 4-6 hours
- Monthly cost: $0
- Ad blocker loss: 30-40%

**Server-only setup (not recommended):**
- Implementation: 16-24 hours (troubleshooting complexity)
- Monthly cost: $40-180
- Attribution quality: Often worse (missing context)

**Hybrid setup (recommended):**
- Implementation: 8-12 hours
- Monthly cost: $40-180  
- Ad blocker mitigation: 25-30% recovered
- Attribution quality: Better than either alone

## When to Use Pure Server-Side

**Only if:**
- Headless commerce (no browser JavaScript)
- Native mobile app (not webview)
- API-only integration (no frontend)
- Server-side rendering (SSR) framework that can inject browser context

**For 95% of Shopify stores: Use hybrid architecture**
