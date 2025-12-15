# Stape.io Server-Side GTM Setup Guide (10 Minutes)

## Overview

Stape.io is a **managed GTM server container** service - the easiest way to implement server-side tracking without DevOps knowledge.

**Why Stape?**
- No infrastructure management
- 10-minute setup (vs 4+ hours DIY)
- Auto-scaling included
- Built-in monitoring
- Cost: $20-50/month

**When to use Stape vs DIY**:
- ✅ Stape: Client needs fast deployment, no DevOps resources
- ✅ DIY (Cloud Run/Lambda): Client has DevOps team, wants lower cost at scale

---

## Prerequisites

- ✅ Google Tag Manager account (web container already set up)
- ✅ Stape.io account (free trial available)
- ✅ Domain with DNS access (for custom subdomain)
- ✅ Meta/GA4 credentials ready

---

## Step 1: Create Stape Server Container (2 minutes)

### 1.1 Sign up for Stape.io

1. Go to [stape.io](https://stape.io)
2. Click "Start Free Trial"
3. Create account (email + password)

### 1.2 Create Server Container

1. Dashboard → "Add Container"
2. Select region (choose closest to your traffic):
   - **US East**: North American traffic
   - **EU West**: European traffic
   - **Asia Pacific**: Asian traffic
3. Choose plan:
   - **Starter**: $20/month (100K requests)
   - **Standard**: $30/month (500K requests)
   - **Pro**: $50/month (1M requests)
4. Click "Create Container"

**Result**: You'll get a container URL like `https://xyz123.stape.io`

---

## Step 2: Configure Custom Domain (3 minutes)

### Why Custom Domain?

Using `yourdomain.com` instead of `stape.io` improves:
- Cookie persistence (same-site context)
- Ad blocker evasion (first-party domain)
- Browser trust (no 3rd-party flags)

### 2.1 Choose Subdomain

Pick a subdomain for your server container:
- Good: `analytics.yourdomain.com`
- Good: `track.yourdomain.com`
- Good: `data.yourdomain.com`
- Avoid: `gtm.yourdomain.com` (too obvious for ad blockers)

### 2.2 Add DNS CNAME Record

**In your DNS provider** (Cloudflare, GoDaddy, etc.):

```
Type: CNAME
Name: analytics (or your chosen subdomain)
Value: xyz123.stape.io (your Stape container URL)
TTL: 300 (5 minutes)
```

**Example for Cloudflare**:
```
analytics.yourdomain.com → CNAME → xyz123.stape.io
```

### 2.3 Verify in Stape

1. Stape Dashboard → Your Container → Settings
2. Click "Custom Domain"
3. Enter: `analytics.yourdomain.com`
4. Click "Verify"
5. Wait 1-5 minutes for DNS propagation
6. Status should show: ✅ "Connected"

**Result**: Your server container now responds at `https://analytics.yourdomain.com`

---

## Step 3: Configure Web GTM Container (3 minutes)

### 3.1 Update GTM Web Container Settings

1. Go to [tagmanager.google.com](https://tagmanager.google.com)
2. Select your **web container** (GTM-XXXXXX)
3. Admin → Container Settings
4. Scroll to "Server Container URLs"
5. Add: `https://analytics.yourdomain.com`
6. Save

### 3.2 Create Server-Side Client Tag

**In your web GTM container**:

1. Tags → New
2. Tag Configuration → **Google Tag** (or GA4 Configuration)
3. Configuration Settings:
   - Measurement ID: `G-XXXXXXXXXX`
   - **Server Container URL**: `https://analytics.yourdomain.com`
4. Triggering: All Pages
5. Save
6. **Publish** web container

**What this does**: Sends GA4 events to your server container instead of directly to Google

---

## Step 4: Configure Server GTM Container (2 minutes)

### 4.1 Access Server Container

1. Stape Dashboard → Your Container
2. Click "Open in GTM"
3. This opens the **server-side GTM interface** (looks similar to web GTM)

### 4.2 Add GA4 Client

**Clients** receive data from your website:

1. Clients → New
2. Client Type: **GA4**
3. Default settings are fine
4. Save

### 4.3 Add GA4 Tag

**Tags** forward data to Google Analytics:

1. Tags → New
2. Tag Configuration: **Google Analytics: GA4**
3. Settings:
   - Measurement ID: `G-XXXXXXXXXX`
   - (Leave other defaults)
4. Triggering: All GA4 requests
5. Save

### 4.4 Add Meta Conversions API Tag (Optional)

1. Tags → New
2. Tag Configuration: Search "Meta" in Community Gallery
3. Install **"Meta Conversions API"** by Stape
4. Settings:
   - Pixel ID: `1234567890123456`
   - Access Token: `your_meta_token`
   - Event Name Mapping: (auto-detect)
5. Triggering: All events
6. Save

### 4.5 Publish Server Container

1. Submit → Publish
2. Version Name: "Initial server-side setup"
3. Publish

---

## Step 5: Test Implementation (2 minutes)

### 5.1 Test with Preview Mode

**In server GTM**:
1. Preview button (top right)
2. Enter your website URL
3. Click "Connect"

**In your website**:
1. Navigate around, trigger events
2. Check Preview console
3. Verify:
   - ✅ Clients receiving requests
   - ✅ Tags firing successfully
   - ✅ No errors in console

### 5.2 Verify in GA4

1. GA4 → Admin → DebugView
2. Navigate your site
3. Look for events in DebugView
4. Verify `page_view`, `session_start` etc. appearing

### 5.3 Verify in Meta Events Manager (if configured)

1. Meta Events Manager → Your Pixel
2. Test Events tab
3. Look for "Server" label on events
4. Verify Event Match Quality score

---

## Complete Setup Checklist

- [ ] Stape container created
- [ ] Custom domain configured (DNS CNAME)
- [ ] Web GTM container updated with server URL
- [ ] Server container published with:
  - [ ] GA4 Client
  - [ ] GA4 Tag
  - [ ] Meta CAPI Tag (optional)
- [ ] Testing verified:
  - [ ] Preview mode working
  - [ ] GA4 receiving events
  - [ ] Meta showing "Server" events (if configured)

---

## Cost Breakdown

### Stape.io Plans

| Plan | Cost/Month | Requests | Best For |
|------|------------|----------|----------|
| Starter | $20 | 100K | Small stores (<500 orders/mo) |
| Standard | $30 | 500K | Medium stores (500-2K orders/mo) |
| Pro | $50 | 1M | Large stores (>2K orders/mo) |

### How to Estimate Requests

**Formula**: Monthly pageviews × 3 (events per page) = request count

Example:
- 20K pageviews/month
- × 3 events per page = 60K requests
- **Plan needed**: Starter ($20/month)

---

## Troubleshooting

### Issue: Custom Domain Not Connecting

**Symptoms**: Stape shows "DNS verification failed"

**Solutions**:
1. Wait 5-10 minutes (DNS propagation)
2. Check CNAME record:
   ```bash
   dig analytics.yourdomain.com CNAME
   # Should return: xyz123.stape.io
   ```
3. If using Cloudflare: Turn OFF proxy (orange cloud → gray cloud)
4. Try without HTTPS first, enable after connection works

### Issue: GA4 Events Not Appearing

**Symptoms**: GA4 DebugView empty

**Solutions**:
1. Check web GTM container has server URL configured
2. Verify server container is published
3. Check Preview mode for errors
4. Verify Measurement ID matches in both web and server containers

### Issue: Meta Events Show Low Match Quality

**Symptoms**: Event Match Quality <6.0

**Solutions**:
1. Add more user data parameters (em, ph, fn, ln)
2. Ensure fbp/fbc cookies captured client-side
3. Use server-side webhook (Shopify/WooCommerce) for complete customer data

---

## Advanced: Add Webhook Forwarding

For **complete server-side tracking** (bypassing client-side entirely for conversions):

### Shopify Webhook to Stape

1. Stape Dashboard → Webhooks
2. Create Webhook Endpoint
3. Copy webhook URL: `https://analytics.yourdomain.com/webhook/shopify`
4. In Shopify Admin → Settings → Notifications → Webhooks:
   - Event: Order payment
   - URL: `https://analytics.yourdomain.com/webhook/shopify`
   - Format: JSON

5. In Server GTM:
   - Create Webhook Client
   - Create transformation to map Shopify data → GA4/Meta format
   - Create GA4 + Meta tags triggered by webhook

**Result**: Orders fire server-side without any browser involvement

---

## Monitoring

### Stape Dashboard Metrics

Check weekly:
- Request count (are you approaching limit?)
- Error rate (should be <1%)
- Response time (should be <200ms)

### GTM Server Container Stats

Check in server GTM:
- Admin → Container Info → Analytics
- Look for:
  - Tag firing rate (should be >99%)
  - Client errors (should be minimal)

---

## Maintenance

### Monthly Tasks (5 minutes)
- Check Stape request count (upgrade if approaching limit)
- Review error logs
- Verify custom domain still connected

### Quarterly Tasks (30 minutes)
- Review tag configurations
- Check for GTM updates/new features
- Validate test transactions still working
- Compare conversion counts: before vs current

---

## Migration from Stape to Self-Hosted (Future)

If you want to migrate to Cloud Run/Lambda later:

1. Export server GTM container
2. Deploy to Cloud Run using exported config
3. Update DNS CNAME to point to Cloud Run URL
4. Test thoroughly
5. Switch traffic

No data loss during migration if done correctly.

---

## Support Resources

- [Stape Documentation](https://stape.io/docs)
- [Stape Community](https://stape.io/community)
- [GTM Server-Side Docs](https://developers.google.com/tag-platform/tag-manager/server-side)

---

## License

MIT - Free for commercial use
