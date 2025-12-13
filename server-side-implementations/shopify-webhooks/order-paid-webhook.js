/**
 * Shopify Order Paid Webhook Handler
 * Server-side tracking implementation for Meta CAPI + GA4
 * 
 * Security features:
 * - HMAC signature verification
 * - Timestamp validation (5-minute window)
 * - Event deduplication via event_id
 * - PII hashing (SHA-256)
 * - Rate limiting ready
 * 
 * Based on research from:
 * - Invicti webhook security best practices (2025)
 * - Shopify webhook documentation
 * - Meta Conversions API guidelines
 */

const crypto = require('crypto');
const express = require('express');
const app = express();

// Environment variables (set in your deployment)
const SHOPIFY_WEBHOOK_SECRET = process.env.SHOPIFY_WEBHOOK_SECRET;
const META_PIXEL_ID = process.env.META_PIXEL_ID;
const META_ACCESS_TOKEN = process.env.META_ACCESS_TOKEN;
const GA4_MEASUREMENT_ID = process.env.GA4_MEASUREMENT_ID;
const GA4_API_SECRET = process.env.GA4_API_SECRET;

// Middleware to capture raw body for HMAC verification
app.use(express.json({
  verify: (req, res, buf) => {
    req.rawBody = buf.toString('utf8');
  }
}));

/**
 * SECURITY: Verify Shopify webhook authenticity
 * Prevents spoofed webhook attacks
 */
function verifyShopifyWebhook(req) {
  const hmac = req.headers['x-shopify-hmac-sha256'];
  const body = req.rawBody;
  
  if (!hmac || !body) {
    console.log('❌ Missing HMAC or body');
    return false;
  }
  
  const hash = crypto
    .createHmac('sha256', SHOPIFY_WEBHOOK_SECRET)
    .update(body, 'utf8')
    .digest('base64');
  
  try {
    // Use constant-time comparison to prevent timing attacks
    return crypto.timingSafeEqual(
      Buffer.from(hmac),
      Buffer.from(hash)
    );
  } catch (error) {
    console.error('❌ HMAC verification error:', error.message);
    return false;
  }
}

/**
 * SECURITY: Validate webhook timestamp
 * Prevents replay attacks (reject webhooks older than 5 minutes)
 */
function validateTimestamp(createdAt) {
  const TOLERANCE_SECONDS = 300; // 5 minutes
  const webhookTime = new Date(createdAt).getTime() / 1000;
  const now = Date.now() / 1000;
  const age = now - webhookTime;
  
  if (age > TOLERANCE_SECONDS) {
    console.log(`❌ Webhook too old: ${Math.round(age)} seconds`);
    return false;
  }
  
  if (age < -30) {
    console.log(`❌ Webhook timestamp in future: ${Math.round(age)} seconds`);
    return false;
  }
  
  return true;
}

/**
 * Hash PII data for GDPR/privacy compliance
 * Meta REQUIRES hashed user data in Conversions API
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
 * Bypasses iOS ATT restrictions and ad blockers
 */
async function sendToMetaCAPI(event) {
  const url = `https://graph.facebook.com/v19.0/${META_PIXEL_ID}/events`;
  
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
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
      throw new Error(result.error?.message || 'Unknown Meta API error');
    }
  } catch (error) {
    console.error('❌ Meta CAPI request failed:', error.message);
    // Don't throw - continue to other platforms
    return null;
  }
}

/**
 * Send event to GA4 Measurement Protocol
 * Server-side GA4 event tracking
 */
async function sendToGA4(event) {
  const url = `https://www.google-analytics.com/mp/collect?measurement_id=${GA4_MEASUREMENT_ID}&api_secret=${GA4_API_SECRET}`;
  
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(event)
    });
    
    if (response.ok) {
      console.log('✅ GA4 event sent successfully');
      return true;
    } else {
      const text = await response.text();
      console.error('❌ GA4 error:', text);
      return false;
    }
  } catch (error) {
    console.error('❌ GA4 request failed:', error.message);
    return false;
  }
}

/**
 * Main webhook handler: Shopify Order Paid
 * Fires when payment is confirmed (not just order created)
 */
app.post('/webhooks/shopify/order-paid', async (req, res) => {
  const startTime = Date.now();
  
  try {
    // SECURITY STEP 1: Verify HMAC signature
    if (!verifyShopifyWebhook(req)) {
      console.log('❌ Invalid Shopify webhook signature');
      return res.status(401).json({ error: 'Invalid signature' });
    }
    
    const order = req.body;
    
    // SECURITY STEP 2: Validate timestamp
    if (!validateTimestamp(order.created_at)) {
      return res.status(400).json({ error: 'Webhook expired' });
    }
    
    console.log(`✅ Processing order: ${order.order_number}`);
    
    // Extract browser identifiers from order attributes
    // These are captured client-side and stored in cart attributes
    const fbp = order.note_attributes?.find(attr => attr.name === '_fbp')?.value;
    const fbc = order.note_attributes?.find(attr => attr.name === '_fbc')?.value;
    const clientIp = req.headers['x-forwarded-for']?.split(',')[0] || req.ip;
    const userAgent = req.headers['user-agent'];
    
    // Generate unique event_id for deduplication
    // CRITICAL: If client-side Pixel also fires, use SAME event_id to prevent double-counting
    const eventId = `shopify_${order.id}_${order.order_number}`;
    
    // Prepare Meta Conversions API event
    const metaEvent = {
      event_name: 'Purchase',
      event_time: Math.floor(new Date(order.created_at).getTime() / 1000),
      event_id: eventId, // Deduplication key
      event_source_url: order.landing_site || order.referring_site || `https://${order.shop_url}`,
      action_source: 'website',
      
      // User data (all hashed for privacy)
      user_data: {
        em: sha256(order.customer?.email),
        ph: sha256(order.customer?.phone?.replace(/\D/g, '')), // Remove non-digits
        fn: sha256(order.customer?.first_name),
        ln: sha256(order.customer?.last_name),
        ct: sha256(order.billing_address?.city),
        st: sha256(order.billing_address?.province_code),
        zp: sha256(order.billing_address?.zip),
        country: sha256(order.billing_address?.country_code),
        
        // Browser identifiers (NOT hashed - Meta uses these for matching)
        fbp: fbp,
        fbc: fbc,
        
        // Network data
        client_ip_address: clientIp,
        client_user_agent: userAgent
      },
      
      // Transaction data
      custom_data: {
        currency: order.currency,
        value: parseFloat(order.total_price),
        content_ids: order.line_items.map(item => item.product_id.toString()),
        content_type: 'product',
        content_name: order.line_items.map(item => item.title).join(', '),
        num_items: order.line_items.reduce((sum, item) => sum + item.quantity, 0),
        
        // Additional business data
        order_id: order.order_number.toString(),
        payment_method: order.payment_gateway_names?.[0]
      }
    };
    
    // Prepare GA4 Measurement Protocol event
    const ga4Event = {
      client_id: order.customer?.id?.toString() || `guest_${order.id}`,
      events: [{
        name: 'purchase',
        params: {
          transaction_id: order.order_number.toString(),
          value: parseFloat(order.total_price),
          tax: parseFloat(order.total_tax),
          shipping: parseFloat(order.total_shipping_price_set?.shop_money?.amount || 0),
          currency: order.currency,
          coupon: order.discount_codes?.[0]?.code,
          items: order.line_items.map(item => ({
            item_id: item.product_id.toString(),
            item_name: item.title,
            item_variant: item.variant_title,
            price: parseFloat(item.price),
            quantity: item.quantity,
            item_category: item.product_type
          }))
        }
      }]
    };
    
    // Send to Meta CAPI (non-blocking)
    const metaPromise = sendToMetaCAPI(metaEvent);
    
    // Send to GA4 (non-blocking)
    const ga4Promise = sendToGA4(ga4Event);
    
    // Wait for both to complete
    await Promise.allSettled([metaPromise, ga4Promise]);
    
    const duration = Date.now() - startTime;
    console.log(`✅ Webhook processed in ${duration}ms`);
    
    // Respond to Shopify (must respond within 5 seconds)
    res.status(200).json({ 
      success: true,
      order_id: order.order_number,
      processing_time_ms: duration
    });
    
  } catch (error) {
    console.error('❌ Webhook processing error:', error);
    
    // Log error details but don't expose to sender
    res.status(500).json({ error: 'Processing failed' });
  }
});

/**
 * Health check endpoint
 * Use for monitoring/uptime checks
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
  console.log(`🚀 Webhook server listening on port ${PORT}`);
  console.log(`📍 Webhook URL: http://localhost:${PORT}/webhooks/shopify/order-paid`);
});

module.exports = app;
