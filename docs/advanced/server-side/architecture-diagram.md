# Server-Side GTM Architecture

## Data Flow Visualization

```
┌─────────────────────────────────────────────────────────┐
│                    USER'S BROWSER                        │
│                                                           │
│  1. User submits form                                    │
│  2. JavaScript validation                                │
│  3. Push to dataLayer                                    │
│                                                           │
│     dataLayer.push({                                     │
│       event: 'form_submission_success',                  │
│       transaction_id: 'unique_id_12345'                  │
│     });                                                   │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│             WEB GTM CONTAINER (Client-Side)              │
│                                                           │
│  ┌───────────────────────────────────────────────┐      │
│  │ GA4 Configuration Tag                          │      │
│  │                                                 │      │
│  │ transport_url: https://track.yourdomain.com    │      │
│  │ first_party_collection: true                   │      │
│  └───────────────────────────────────────────────┘      │
│                                                           │
│  Instead of sending to:                                  │
│  ❌ https://www.google-analytics.com/g/collect           │
│                                                           │
│  Now sends to:                                           │
│  ✅ https://track.yourdomain.com (your server)           │
└─────────────────┬───────────────────────────────────────┘
                  │
                  │ HTTPS POST Request
                  │ (First-party domain = ad blocker resistant)
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│        SERVER GTM CONTAINER (Your Infrastructure)        │
│                  (GCP Cloud Run / Stape.io)              │
│                                                           │
│  ┌───────────────────────────────────────────────┐      │
│  │ GA4 Client                                     │      │
│  │ -  Receives POST request                        │      │
│  │ -  Parses event data                            │      │
│  │ -  Makes available to server tags               │      │
│  └──────────────────┬─────────────────────────────┘      │
│                     │                                     │
│                     ▼                                     │
│  ┌───────────────────────────────────────────────┐      │
│  │ SERVER-SIDE ENRICHMENT                         │      │
│  │                                                 │      │
│  │ -  Add server timestamp                         │      │
│  │ -  Parse user-agent (device/browser)            │      │
│  │ -  IP geolocation (GDPR-compliant hash)         │      │
│  │ -  Custom event parameters                      │      │
│  │ -  Transaction deduplication check              │      │
│  └──────────────────┬─────────────────────────────┘      │
│                     │                                     │
│                     ▼                                     │
│  ┌───────────────────────────────────────────────┐      │
│  │ Multiple Destination Tags                      │      │
│  └───────────────────────────────────────────────┘      │
└──────────┬──────────┬──────────┬─────────────────────────┘
           │          │          │
           │          │          └─────────────┐
           ▼          ▼                        ▼
    ┌──────────┐ ┌──────────┐         ┌──────────────┐
    │   GA4    │ │   Meta   │         │ Google Ads   │
    │          │ │   CAPI   │         │  Enhanced    │
    │ Server   │ │          │         │ Conversions  │
    │ Endpoint │ │ Dedupe   │         │              │
    └──────────┘ └──────────┘         └──────────────┘
```

## Benefits at Each Layer

### Browser Layer
✅ Validation logic runs before data push
✅ User privacy respected (consent mode)
✅ No direct third-party calls

### Web GTM Layer  
✅ First-party domain routing
✅ Ad blocker resistant
✅ Standard GTM debugging tools work

### Server Container Layer
✅ 95%+ data capture rate
✅ Server-side enrichment
✅ Multiple destinations (GA4 + Meta + Ads)
✅ Event deduplication
✅ IP anonymization

### Analytics Platforms
✅ Higher quality data
✅ Better attribution
✅ Improved conversion tracking
