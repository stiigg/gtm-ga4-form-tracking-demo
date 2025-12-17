# Webhook Security Best Practices

## Overview

Based on research from:
- Invicti Webhook Security Best Practices (2025)
- OWASP API Security Top 10
- Event-Driven Architecture Security Patterns (Texas A&M, 2025)

## 8 Critical Security Practices

### 1. HTTPS Only ✅

**Requirement**: All webhook endpoints MUST use HTTPS (TLS 1.3 preferred)

**Why**: Prevents man-in-the-middle attacks and eavesdropping

**Implementation**:
```javascript
// Reject HTTP requests
app.use((req, res, next) => {
    if (req.protocol !== 'https' && process.env.NODE_ENV === 'production') {
        return res.status(403).send('HTTPS required');
    }
    next();
});
```

---

### 2. HMAC Signature Verification ✅

**Requirement**: Verify cryptographic signature on every webhook

**Why**: Prevents spoofed webhooks from attackers

**Implementation**:
```javascript
function verifyHMAC(req, secret) {
    const signature = req.headers['x-webhook-signature'];
    const body = req.rawBody;
    
    const hash = crypto
        .createHmac('sha256', secret)
        .update(body)
        .digest('hex');
    
    // Use constant-time comparison
    return crypto.timingSafeEqual(
        Buffer.from(signature),
        Buffer.from(hash)
    );
}

app.post('/webhook', (req, res) => {
    if (!verifyHMAC(req, WEBHOOK_SECRET)) {
        return res.status(401).json({error: 'Invalid signature'});
    }
    // Process webhook...
});
```

**Platform-Specific**:

**Shopify**:
```javascript
const hmac = req.headers['x-shopify-hmac-sha256'];
const hash = crypto.createHmac('sha256', SHOPIFY_SECRET)
    .update(req.rawBody, 'utf8')
    .digest('base64');
```

**Stripe**:
```javascript
const signature = req.headers['stripe-signature'];
const event = stripe.webhooks.constructEvent(
    req.rawBody,
    signature,
    STRIPE_WEBHOOK_SECRET
);
```

---

### 3. Timestamp Validation ✅

**Requirement**: Reject webhooks older than 5 minutes

**Why**: Prevents replay attacks (attacker re-sends old valid webhook)

**Implementation**:
```javascript
function validateTimestamp(webhookTimestamp) {
    const TOLERANCE_SECONDS = 300; // 5 minutes
    const now = Date.now() / 1000;
    const age = now - webhookTimestamp;
    
    if (age > TOLERANCE_SECONDS) {
        console.log(`❌ Webhook too old: ${age} seconds`);
        return false;
    }
    
    if (age < -30) {
        console.log(`❌ Webhook from future: ${age} seconds`);
        return false;
    }
    
    return true;
}

app.post('/webhook', (req, res) => {
    if (!validateTimestamp(req.body.timestamp)) {
        return res.status(400).json({error: 'Webhook expired'});
    }
    // Process webhook...
});
```

---

### 4. IP Address Allowlisting ✅

**Requirement**: Maintain allowlist of webhook source IPs

**Why**: Additional security layer (defense in depth)

**Implementation**:
```javascript
const ALLOWED_IPS = [
    '23.227.38.32/27',   // Shopify
    '3.18.12.63/32',     // Stripe
    // Add platform IPs
];

function isAllowedIP(clientIP) {
    return ALLOWED_IPS.some(range => ipInRange(clientIP, range));
}

app.use('/webhooks/*', (req, res, next) => {
    const clientIP = req.headers['x-forwarded-for']?.split(',')[0] || req.ip;
    
    if (!isAllowedIP(clientIP)) {
        console.log(`❌ Blocked unauthorized IP: ${clientIP}`);
        return res.status(403).json({error: 'Forbidden'});
    }
    
    next();
});
```

**Warning**: Don't rely on reverse DNS lookups (easily spoofed)

---

### 5. Minimal PII Exposure ✅

**Requirement**: Hash PII before storage/transmission

**Why**: GDPR/privacy compliance, reduces breach impact

**Implementation**:
```javascript
function sanitizeWebhookData(payload) {
    return {
        order_id: payload.id,
        
        // Hash PII immediately
        customer_email_hash: sha256(payload.email),
        customer_phone_hash: sha256(payload.phone),
        
        // Keep non-sensitive data
        value: payload.total,
        currency: payload.currency,
        
        // NEVER store plaintext PII
        // ❌ email: payload.email
        // ❌ phone: payload.phone
    };
}
```

**For Meta CAPI** (requires hashed data):
```javascript
user_data: {
    em: sha256(email),      // REQUIRED to be hashed
    ph: sha256(phone),      // REQUIRED to be hashed
    fn: sha256(firstName),  // REQUIRED to be hashed
    // ...
}
```

---

### 6. Comprehensive Logging ✅

**Requirement**: Log metadata, NOT sensitive payloads

**Why**: Debugging without exposing customer data

**Implementation**:
```javascript
function logWebhook(req, status, duration) {
    const logEntry = {
        timestamp: new Date().toISOString(),
        endpoint: req.path,
        status: status,
        processing_time_ms: duration,
        signature_valid: req.signature_valid,
        
        // ✅ Log these
        event_type: req.body.event_type,
        order_id: req.body.order_id,
        event_id: req.body.event_id,
        
        // ❌ NEVER log these
        // customer_email: req.body.email,
        // customer_phone: req.body.phone,
        // payment_details: req.body.payment
    };
    
    console.log(JSON.stringify(logEntry));
}
```

---

### 7. Rate Limiting ✅

**Requirement**: Limit requests per source to prevent abuse

**Why**: Protects against DDoS and resource exhaustion

**Implementation**:
```javascript
const rateLimit = require('express-rate-limit');

const webhookLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 100, // 100 requests per minute per source
    message: 'Too many webhook requests',
    keyGenerator: (req) => {
        // Rate limit by source domain or IP
        return req.headers['x-shopify-shop-domain'] || req.ip;
    }
});

app.use('/webhooks/', webhookLimiter);
```

**Anomaly Detection**:
```javascript
let webhookCounts = {};

function detectAnomaly(source, eventType) {
    const key = `${source}_${eventType}`;
    const now = Date.now();
    
    if (!webhookCounts[key]) {
        webhookCounts[key] = {count: 0, windowStart: now};
    }
    
    const window = webhookCounts[key];
    
    // Reset window every 5 minutes
    if (now - window.windowStart > 300000) {
        window.count = 0;
        window.windowStart = now;
    }
    
    window.count++;
    
    // Alert if >10x normal rate
    if (window.count > 500) {
        console.log(`🚨 ANOMALY: ${key} - ${window.count} events in 5 min`);
        sendAlert({type: 'webhook_anomaly', source, count: window.count});
    }
}
```

---

### 8. Fail Securely ✅

**Requirement**: If validation fails, reject immediately without processing

**Why**: Security-first error handling

**Implementation**:
```javascript
app.post('/webhook', async (req, res) => {
    try {
        // Security validations FIRST (fail fast)
        if (!verifySignature(req)) {
            logSecurityEvent('invalid_signature', req);
            return res.status(401).json({error: 'Invalid signature'});
        }
        
        if (!validateTimestamp(req.body.timestamp)) {
            return res.status(400).json({error: 'Invalid timestamp'});
        }
        
        if (!isAllowedIP(req.ip)) {
            logSecurityEvent('unauthorized_ip', req);
            return res.status(403).json({error: 'Forbidden'});
        }
        
        // ALL security checks passed - process webhook
        await processWebhook(req.body);
        res.status(200).json({success: true});
        
    } catch (error) {
        // Log error internally
        console.error('Webhook error:', error);
        
        // Generic error to client (no details)
        res.status(500).json({error: 'Processing failed'});
    }
});
```

---

## Security Checklist

Before deploying:

- [ ] HTTPS endpoint configured (TLS 1.3)
- [ ] HMAC signature verification implemented
- [ ] Timestamp validation (5-minute window)
- [ ] IP allowlisting configured
- [ ] PII hashing before storage/transmission
- [ ] Logging excludes sensitive data
- [ ] Rate limiting configured
- [ ] Error handling doesn't expose internals
- [ ] Environment variables for secrets (not hardcoded)
- [ ] Webhook timeout <5 seconds (respond quickly)

## Common Vulnerabilities

### ❌ Hardcoded Secrets
```javascript
// DON'T DO THIS
const WEBHOOK_SECRET = 'sk_live_abc123';

// DO THIS
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET;
```

### ❌ Exposing Error Details
```javascript
// DON'T DO THIS
catch (error) {
    res.status(500).json({error: error.message}); // Leaks internals
}

// DO THIS
catch (error) {
    console.error('Internal error:', error);
    res.status(500).json({error: 'Processing failed'}); // Generic
}
```

### ❌ Logging Sensitive Data
```javascript
// DON'T DO THIS
console.log('Webhook received:', JSON.stringify(req.body)); // Logs emails, phones, etc.

// DO THIS
console.log('Webhook received:', {
    event_type: req.body.event_type,
    order_id: req.body.order_id
    // Omit PII
});
```

## Testing Security

### Test Invalid Signature
```bash
curl -X POST https://your-server.com/webhook \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Signature: invalid_signature" \
  -d '{"test": "data"}'

# Expected: 401 Unauthorized
```

### Test Expired Timestamp
```bash
curl -X POST https://your-server.com/webhook \
  -H "Content-Type: application/json" \
  -d '{"timestamp": 1234567890}'

# Expected: 400 Bad Request
```

### Test Rate Limiting
```bash
for i in {1..150}; do
  curl -X POST https://your-server.com/webhook &
done

# Expected: Some requests return 429 Too Many Requests
```

## Monitoring

### Security Metrics to Track

```javascript
const securityMetrics = {
    invalid_signatures: Counter,
    expired_timestamps: Counter,
    unauthorized_ips: Counter,
    rate_limit_hits: Counter,
    anomaly_detections: Counter
};
```

### Alert Thresholds

- Invalid signatures: >5/hour → Potential attack
- Unauthorized IPs: >10/hour → Investigate
- Rate limit hits: >50/hour → Possible DDoS
- Anomaly detections: >1/day → Review patterns

## Resources

- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [Invicti Webhook Security](https://www.invicti.com/blog/web-security/webhook-security-best-practices/)
- [Shopify Webhook Verification](https://shopify.dev/docs/apps/webhooks/configuration/https)
- [Stripe Webhook Security](https://stripe.com/docs/webhooks/best-practices)

## License

MIT - Free for commercial use
