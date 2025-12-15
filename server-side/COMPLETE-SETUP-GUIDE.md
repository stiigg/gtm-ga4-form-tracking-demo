# Complete Server-Side GTM Setup Guide

## Prerequisites

- Existing web GTM container (GTM-XXXXXX)
- GA4 Property (G-XXXXXXXXXX)
- Custom domain access (for CNAME setup)
- GCP account OR Stape.io subscription

## Step 1: Create Server Container

### Option A: Google Cloud Platform (Self-Hosted)

1. Go to [Google Tag Manager](https://tagmanager.google.com)
2. Create new container → Select **Server** type
3. Note your Container ID (GTM-XXXXXX)
4. Follow [GCP deployment guide](https://developers.google.com/tag-platform/tag-manager/server-side/script-user-guide)

**Estimated monthly cost:** $10-50 (based on traffic)

### Option B: Stape.io (Managed Service)

1. Sign up at [Stape.io](https://stape.io)
2. Create new server container
3. Connect to your GTM server container ID
4. Note your tagging server URL: `https://your-subdomain.stape.io`

**Cost:** $20-100/month (includes hosting + management)

## Step 2: Configure Custom Domain (CRITICAL)

**Why needed:** Without custom domain, browsers treat server calls as third-party (defeats purpose).

### DNS Configuration

Add CNAME record in your DNS:

```
Type: CNAME
Name: track (or analytics, gtm, etc.)
Value: your-server-container-url.cloudfunctions.net (GCP)
       OR your-subdomain.stape.io (Stape)
TTL: 3600
```

**Result:** `https://track.yourdomain.com` routes to server container

**Verification:** Visit `https://track.yourdomain.com/healthz` (should return 200 OK)

## Step 3: Update Web Container

### Add Server URL to GA4 Config Tag

In your web GTM container:

**Tag: GA4 Configuration**
- Tag Type: Google Analytics: GA4 Configuration
- Measurement ID: `G-XXXXXXXXXX`
- Fields to Set:
  - `transport_url`: `https://track.yourdomain.com`
  - `first_party_collection`: `true`

**Trigger:** All Pages

**Save and publish**

## Step 4: Configure Server Container

### Create GA4 Client

**In server container:**
1. Clients → New → GA4 Client
2. Leave default settings
3. Save

### Create GA4 Tag

1. Tags → New → GA4 (Server-Side)
2. Configuration:
   - Measurement ID: `G-XXXXXXXXXX`
   - Event Name: `{{Event Name}}` (variable)
3. Trigger: All Events
4. Save and publish

## Step 5: Test Configuration

### Verification Checklist

✅ **Test 1: Traffic Routing**
1. Open browser DevTools → Network tab
2. Visit your site
3. Search for requests to `track.yourdomain.com`
4. Should see POST requests with `v=2` parameter

✅ **Test 2: GA4 DebugView**
1. Enable debug mode: `https://yourdomain.com?debug_mode=true`
2. Open GA4 → Configure → DebugView
3. Should see events with `traffic_type: server_side`

✅ **Test 3: Server Container Preview**
1. In server GTM, click Preview
2. Enter your server URL
3. Should see incoming requests in real-time

## Common Issues

### Issue: No Requests to Server Container

**Diagnosis:**
- Check browser console for errors
- Verify transport_url is correct in GA4 config
- Confirm CNAME DNS propagation (use `nslookup track.yourdomain.com`)

**Solution:**
- Clear GTM cache (wait 15 minutes after publish)
- Test in incognito mode
- Verify no ad blockers active during testing

### Issue: Events Not Appearing in GA4

**Diagnosis:**
- Check server container preview mode
- Verify GA4 tag is firing in server container
- Check Measurement ID is correct

**Solution:**
- Review server container debug logs
- Ensure GA4 property is not in test mode
- Verify data retention settings in GA4

## Performance Monitoring

### Key Metrics to Track

After 7 days, compare:

| Metric | Client-Side | Server-Side | Expected Change |
|--------|-------------|-------------|-----------------|
| Total Events | Baseline | +20-35% | ✅ Ad blocker recovery |
| iOS Safari Events | Baseline | +30-40% | ✅ ITP bypass |
| Consent Granted Rate | Baseline | Similar | ⚠️ Monitor |
| GA4 Processing Lag | ~1-2 min | ~30-60 sec | ✅ Faster |

## Next Steps

1. [Configure Meta CAPI](conversions-api/META-CAPI-SETUP.md)
2. [Set up event deduplication](DEDUPLICATION-GUIDE.md)
3. [Enable custom enrichment](CUSTOM-ENRICHMENT.md)
