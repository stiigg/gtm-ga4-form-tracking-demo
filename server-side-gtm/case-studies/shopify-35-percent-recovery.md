# Health & Beauty Shopify Store - 35% Conversion Recovery

## Challenge
- 42% iOS/Safari traffic constrained by ITP cookie limits
- Meta Pixel missing 38% of purchase events
- Returning customer attribution broken
- Duplicate purchases inflating revenue by 25%

## Solution Implemented
- Server-side GTM via Stape ($40/month hosting)
- Meta Conversions API with event_id deduplication
- Shopify webhook integration (orders/create)
- Extended cookie lifespan to 2 years

## Results
- Purchase tracking accuracy: 68% → 95% (+27 pp)
- Meta ROAS improved: 2.6x → 3.1x (+19%)
- Duplicate purchases eliminated (25% revenue inflation fixed)
- Monthly recovered attribution: $8,400
- **ROI: 210x first month** ($8,400 benefit / $40 cost)

## Lessons Learned
- Deduplication must be enabled from day 1 to avoid inflated revenue
- Stape logs are invaluable for webhook validation
- Client-side event_id generation must be consistent across themes
