/**
 * Webflow → GoHighLevel Server-Side Tracking
 * Webhook handler for lead form submissions
 * 
 * Flow:
 * 1. User fills form on Webflow landing page
 * 2. GoHighLevel captures submission
 * 3. GHL fires webhook to this server
 * 4. Server forwards to Meta CAPI + GA4 + Google Ads
 * 
 * Based on:
 * - GoHighLevel webhook documentation
 * - Webflow form tracking best practices
 * - Meta CAPI deduplication requirements
 */

const crypto = require('crypto');
const express = require('express');
const app = express();

// Environment variables
const GHL_WEBHOOK_SECRET = process.env.GHL_WEBHOOK_SECRET; // Optional: for signature verification
const META_PIXEL_ID = process.env.META_PIXEL_ID;
const META_ACCESS_TOKEN = process.env.META_ACCESS_TOKEN;
const GA4_MEASUREMENT_ID = process.env.GA4_MEASUREMENT_ID;
const GA4_API_SECRET = process.env.GA4_API_SECRET;
const GOOGLE_ADS_CONVERSION_ID = process.env.GOOGLE_ADS_CONVERSION_ID;
const GOOGLE_ADS_CONVERSION_LABEL = process.env.GOOGLE_ADS_CONVERSION_LABEL;

app.use(express.json());

/**
 * Hash PII for privacy compliance
 */
function sha256(data) {
    if (!data) return null;
    return crypto
        .createHash('sha256')
        .update(data.toLowerCase().trim())
        .digest('hex');
}

/**
 * Send event to Meta Conversions API
 */
async function sendToMetaCAPI(event) {
    const url = `https://graph.facebook.com/v19.0/${META_PIXEL_ID}/events`;
    
    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({
                data: [event],
                access_token: META_ACCESS_TOKEN
            })
        });
        
        const result = await response.json();
        
        if (response.ok) {
            console.log('✅ Meta CAPI event sent:', result);
            return result;
        } else {
            console.error('❌ Meta CAPI error:', result);
            return null;
        }
    } catch (error) {
        console.error('❌ Meta CAPI request failed:', error.message);
        return null;
    }
}

/**
 * Send event to GA4 Measurement Protocol
 */
async function sendToGA4(event) {
    const url = `https://www.google-analytics.com/mp/collect?measurement_id=${GA4_MEASUREMENT_ID}&api_secret=${GA4_API_SECRET}`;
    
    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(event)
        });
        
        if (response.ok) {
            console.log('✅ GA4 event sent successfully');
            return true;
        } else {
            console.error('❌ GA4 error:', await response.text());
            return false;
        }
    } catch (error) {
        console.error('❌ GA4 request failed:', error.message);
        return false;
    }
}

/**
 * Send conversion to Google Ads
 */
async function sendToGoogleAds(conversionData) {
    // Google Ads Conversion API requires OAuth2
    // Alternative: Use GTM server container to forward
    // This is a simplified example
    
    console.log('📊 Google Ads conversion data prepared:', conversionData);
    // In production: Integrate with Google Ads API or GTM server container
    return true;
}

/**
 * GoHighLevel webhook handler
 * Receives form submission data from GHL
 */
app.post('/webhooks/ghl/form-submission', async (req, res) => {
    const startTime = Date.now();
    
    try {
        const payload = req.body;
        
        console.log('📥 GHL webhook received:', JSON.stringify(payload, null, 2));
        
        // Extract contact data
        const contact = payload.contact || {};
        const formId = payload.form_id || payload.formId;
        const submittedAt = payload.submitted_at || payload.submittedAt || new Date().toISOString();
        
        // UTM parameters (captured by GHL)
        const utmSource = payload.utm_source || contact.source;
        const utmMedium = payload.utm_medium;
        const utmCampaign = payload.utm_campaign;
        const gclid = payload.gclid; // Google Click ID
        const fbclid = payload.fbclid; // Facebook Click ID
        
        // Generate unique event_id for deduplication
        const eventId = `ghl_${contact.id || Date.now()}_${formId}`;
        
        // Prepare Meta Conversions API event
        const metaEvent = {
            event_name: 'Lead',
            event_time: Math.floor(new Date(submittedAt).getTime() / 1000),
            event_id: eventId,
            event_source_url: payload.page_url || payload.landing_page_url,
            action_source: 'website',
            user_data: {
                em: sha256(contact.email),
                ph: sha256(contact.phone?.replace(/\D/g, '')),
                fn: sha256(contact.firstName || contact.first_name),
                ln: sha256(contact.lastName || contact.last_name),
                ct: sha256(contact.city),
                st: sha256(contact.state),
                zp: sha256(contact.postalCode || contact.postal_code),
                country: sha256(contact.country),
                // Browser identifiers if available
                fbp: payload.fbp || contact.fbp,
                fbc: fbclid ? `fb.1.${Date.now()}.${fbclid}` : (payload.fbc || contact.fbc)
            },
            custom_data: {
                form_id: formId,
                lead_source: utmSource,
                campaign: utmCampaign,
                medium: utmMedium
            }
        };
        
        // Prepare GA4 event
        const ga4Event = {
            client_id: contact.id || `ghl_${Date.now()}`,
            events: [{
                name: 'generate_lead',
                params: {
                    form_id: formId,
                    lead_type: 'webflow_to_ghl',
                    campaign: utmCampaign,
                    source: utmSource,
                    medium: utmMedium,
                    value: payload.lead_value || 50 // Default lead value
                }
            }]
        };
        
        // Prepare Google Ads conversion (if gclid present)
        const googleAdsData = gclid ? {
            conversion_action: `${GOOGLE_ADS_CONVERSION_ID}/${GOOGLE_ADS_CONVERSION_LABEL}`,
            gclid: gclid,
            conversion_value: payload.lead_value || 50,
            currency_code: 'USD',
            conversion_time: submittedAt
        } : null;
        
        // Send to all platforms (parallel)
        const results = await Promise.allSettled([
            sendToMetaCAPI(metaEvent),
            sendToGA4(ga4Event),
            googleAdsData ? sendToGoogleAds(googleAdsData) : Promise.resolve(null)
        ]);
        
        const duration = Date.now() - startTime;
        console.log(`✅ Webhook processed in ${duration}ms`);
        
        // Log results
        results.forEach((result, index) => {
            const platform = ['Meta CAPI', 'GA4', 'Google Ads'][index];
            if (result.status === 'fulfilled') {
                console.log(`✅ ${platform}: Success`);
            } else {
                console.error(`❌ ${platform}: Failed -`, result.reason);
            }
        });
        
        // Respond to GHL
        res.status(200).json({
            success: true,
            contact_id: contact.id,
            event_id: eventId,
            processing_time_ms: duration
        });
        
    } catch (error) {
        console.error('❌ Webhook processing error:', error);
        res.status(500).json({error: 'Processing failed'});
    }
});

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 GHL webhook server listening on port ${PORT}`);
    console.log(`📍 Webhook URL: http://localhost:${PORT}/webhooks/ghl/form-submission`);
});

module.exports = app;
