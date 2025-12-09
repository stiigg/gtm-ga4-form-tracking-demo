---
**Document Status:** Pre-client validation  
**Last Updated:** December 9, 2024  
**Client Projects Referenced:** 0 (theoretical scenarios)  
**Methodology Source:** Industry research + clinical QA adaptation  
---

# Consent Mode V2 Debugging Runbook

## Quick Triage (First 5 Minutes)

### Get GTM Access
Ask client for:
- GTM Container ID
- GTM account access (Publish or greater)
- Website URL where issue occurs
- CMP provider name (if known)

### Initial Assessment Questions
Copy-paste this into client chat:

"""
To diagnose your Consent Mode v2 issue, I need:

1. What symptoms are you seeing?
   - [ ] Google Ads audiences not building
   - [ ] GA4 conversion drop after March 2024
   - [ ] Tag Assistant showing consent errors
   - [ ] Other: _____________

2. When did this start?
   - [ ] After CMP installation
   - [ ] After GTM changes
   - [ ] After March 2024 deadline
   - [ ] Unknown

3. What CMP are you using?
   - [ ] Cookiebot
   - [ ] OneTrust
   - [ ] CookieYes
   - [ ] Usercentrics
   - [ ] Custom/Other: _____________
"""

---

## Phase 1: GTM Preview Diagnostic (15 mins)

### Step 1: Open GTM Preview
```
1. Log into GTM → workspace → Preview
2. Enter client's website URL
3. Wait for Tag Assistant to connect
```

### Step 2: Check Consent Tab
**This is THE critical diagnostic step**

Open Preview → Switch to "Consent" tab

**What you're looking for:**

✅ **Healthy Implementation:**
```
Timeline shows:
   consent_default (FIRST EVENT)[1]
      ├─ ad_storage: denied
      ├─ analytics_storage: denied
      ├─ ad_user_data: denied          ← V2 parameter
      └─ ad_personalization: denied    ← V2 parameter
  
   pageview tags WAIT (do not fire yet)[2]
  
   User clicks "Accept All"[3]
  
   consent_update[4]
      ├─ ad_storage: granted
      ├─ analytics_storage: granted
      ├─ ad_user_data: granted
      └─ ad_personalization: granted
  
   NOW tags fire with consent[5]
```

❌ **Broken Patterns You'll See:**

**Pattern A: No consent_default**
```
Timeline shows:
   pageview[1]
   GA4 config tag fires[2]
   Much later: consent_update appears[3]
  
Problem: Tags fired before consent established
Fix: → Go to Fix #1 below
```

**Pattern B: Missing V2 parameters**
```
consent_default shows:
  ├─ ad_storage: denied
  └─ analytics_storage: denied
  (Missing ad_user_data and ad_personalization)
  
Problem: V1 only, not V2 compliant
Fix: → Go to Fix #2 below
```

**Pattern C: consent_default fires too late**
```
Timeline shows:
   pageview[1]
   Multiple tags fire[2]
   consent_default appears (too late)[3]
  
Problem: GTM loaded before consent script
Fix: → Go to Fix #3 below
```

**Pattern D: No consent events at all**
```
Timeline shows:
   pageview[1]
   tags fire normally[2]
  (No consent tab data)
  
Problem: No Consent Mode implementation
Fix: → Go to Fix #4 (full implementation)
```

### Step 3: Screenshot for Documentation
Take screenshot of:
- Consent tab timeline (before fix)
- Tags tab showing what fired when
- Summary view showing tag counts

**Save to**: `/consent-mode-v2/client-diagnostics/[client-name]-before.png`

---

## Phase 2: Root Cause Analysis (10 mins)

### Check GTM Configuration

**Navigate to**: GTM workspace → Tags

**Search for**: "consent"

**What to look for:**

1. **Is there a Consent Initialization tag?**
   - Found: Check its configuration → Go to Section A
   - Not found: Need to create one → Go to Fix #4

2. **Do tags have consent requirements?**
   - Click any GA4 tag → Advanced Settings → Consent Settings
   - Should show: "Require additional consent for tag to fire"
   - Should list: analytics_storage, ad_storage, etc.

### Check CMP Integration

**Method 1: Check page source**
```
// Open client website → DevTools → Console
// Run this command:

console.log(window.dataLayer);

// Look for objects containing "consent"
// Should see entries like:
// {event: "consent", ...}
```

**Method 2: Check for CMP global variables**
```
// Common CMP detection:

// Cookiebot:
console.log(window.Cookiebot);

// OneTrust:
console.log(window.OneTrust);

// CookieYes:
console.log(window.CookieYes);

// If undefined: CMP not loaded or different provider
```

### Check for Script Conflicts

**Look for multiple consent implementations:**

```
// Search page source (Ctrl+F) for:
"gtag('consent'"

// If you find this OUTSIDE of GTM:
// → Problem: Hard-coded consent conflicting with GTM
// → Fix: Remove hard-coded version or disable GTM version
```

---

## Phase 3: Implementation Fixes

### Fix #1: CMP Fires Too Late (Most Common)

**Problem**: CMP script loads async, GTM fires tags before consent established

**Solution**: Add consent defaults in GTM Consent Initialization

**Step-by-step:**

1. **Create Consent Initialization Tag**
   ```
   GTM → Tags → New
   Tag name: "Consent Mode - Default State (V2)"
   Tag type: Custom HTML
   ```

2. **Add this code** (copy from `/snippets/consent-init-generic.html`):
   ```
   <script>
   window.dataLayer = window.dataLayer || [];
   function gtag(){dataLayer.push(arguments);}
   
   // Set default consent (V2 compliant)
   gtag('consent', 'default', {
     'ad_storage': 'denied',
     'ad_user_data': 'denied',
     'ad_personalization': 'denied',
     'analytics_storage': 'denied',
     'wait_for_update': 500
   });
   
   console.log('[Consent V2] Defaults set');
   </script>
   ```

3. **Set trigger**:
   ```
   Triggering: Consent Initialization - All Pages
   ```

4. **Verify trigger priority**:
   ```
   GTM → Triggers → Consent Initialization
   Check: "Fire before page tags"
   Tag firing priority: Should be HIGHER than other tags
   ```

5. **Test in Preview**:
   - Refresh Preview
   - Check Consent tab
   - consent_default should now appear FIRST

**Save this to your runbook**: Record which specific CMP required this fix

---

### Fix #2: Missing V2 Parameters

**Problem**: Implementation only has v1 parameters (ad_storage, analytics_storage)

**Find the consent code** (could be in GTM tag or page source):

**Before (V1 only):**
```
gtag('consent', 'default', {
  'ad_storage': 'denied',
  'analytics_storage': 'denied'
});
```

**After (V2 compliant):**
```
gtag('consent', 'default', {
  'ad_storage': 'denied',
  'analytics_storage': 'denied',
  'ad_user_data': 'denied',        // ADD THIS
  'ad_personalization': 'denied'   // ADD THIS
});
```

**Where to make this change:**
- If in GTM: Edit the Custom HTML tag
- If in page source: Tell client's dev team to update
- If in CMP settings: Update CMP configuration (see CMP-specific guides below)

---

### Fix #3: Wrong Event Structure

**Problem**: dataLayer using custom event names instead of consent API

**Wrong implementation:**
```
// DON'T DO THIS:
dataLayer.push({
  'event': 'cookieConsent',
  'consent': 'granted'
});
```

**Correct implementation:**
```
// DO THIS:
gtag('consent', 'update', {
  'ad_storage': 'granted',
  'analytics_storage': 'granted',
  'ad_user_data': 'granted',
  'ad_personalization': 'granted'
});
```

**How to fix in GTM:**
1. Find the tag pushing custom event
2. Replace with Custom HTML tag using gtag() syntax above
3. Keep same trigger (when user accepts)

---

### Fix #4: No Consent Mode Implementation (Full Setup)

**Use when**: Client has CMP but no GTM Consent Mode integration

**Full implementation checklist:**

**Step 1: Create default consent tag**
- Use code from Fix #1
- Trigger: Consent Initialization - All Pages

**Step 2: Create consent update tags (one per user action)**

Tag: "Consent Update - Accept All"
```
<script>
function gtag(){dataLayer.push(arguments);}
gtag('consent', 'update', {
  'ad_storage': 'granted',
  'ad_user_data': 'granted',
  'ad_personalization': 'granted',
  'analytics_storage': 'granted'
});
console.log('[Consent V2] User accepted all');
</script>
```
Trigger: Custom Event → event equals "cookie_consent_all"
(Adjust event name based on CMP)

Tag: "Consent Update - Reject All"
```
<script>
function gtag(){dataLayer.push(arguments);}
gtag('consent', 'update', {
  'ad_storage': 'denied',
  'ad_user_data': 'denied',
  'ad_personalization': 'denied',
  'analytics_storage': 'denied'
});
console.log('[Consent V2] User rejected all');
</script>
```

**Step 3: Add consent requirements to existing tags**

For EVERY GA4 and Google Ads tag:
```
Tag → Advanced Settings → Consent Settings
→ Enable "Require additional consent for tag to fire"
→ Add required consent types:
  - analytics_storage (for GA4)
  - ad_storage (for Ads)
  - ad_user_data (for Ads)
  - ad_personalization (for Ads)
```

**Step 4: Test sequence**
- Preview mode
- Check: consent_default fires first
- Interact with banner
- Check: consent_update fires
- Check: Tags fire AFTER consent_update

---

## Phase 4: CMP-Specific Configurations

### Cookiebot Integration

**Identify Cookiebot:**
```
// Check if Cookiebot is loaded:
typeof Cookiebot !== 'undefined'
```

**Cookiebot triggers consent events automatically**

**What you need in GTM:**

1. **Built-in Cookiebot Consent Mode Template** (recommended):
   ```
   GTM → Tags → New → Tag Configuration
   → Search "Cookiebot"
   → Select "Cookiebot - Google Consent Mode"
   → Trigger: Consent Initialization
   ```

2. **Manual implementation** (if template doesn't work):
   ```
   // Consent default (in Consent Init tag):
   window.dataLayer = window.dataLayer || [];
   function gtag(){dataLayer.push(arguments);}
   gtag('consent', 'default', {
     'ad_storage': 'denied',
     'analytics_storage': 'denied',
     'ad_user_data': 'denied',
     'ad_personalization': 'denied'
   });
   
   // Consent update (separate tag, trigger on Cookiebot consent given):
   // Trigger: Custom Event → event = "CookiebotOnAccept"
   ```

**Cookiebot-specific triggers to create:**
- Event: `CookiebotOnAccept` → User accepted
- Event: `CookiebotOnDecline` → User declined

---

### OneTrust Integration

**Detect OneTrust:**
```
typeof OneTrust !== 'undefined'
```

**OneTrust dataLayer events:**
```
// OneTrust pushes these events:
'OneTrustGroupsUpdated'  // When consent changes
```

**GTM Setup:**

1. **Default consent** (Consent Init tag):
   ```
   gtag('consent', 'default', {
     'ad_storage': 'denied',
     'analytics_storage': 'denied',
     'ad_user_data': 'denied',
     'ad_personalization': 'denied'
   });
   ```

2. **Update consent** (Custom HTML tag):
   ```
   <script>
   function gtag(){dataLayer.push(arguments);}
   
   // Map OneTrust categories to consent types:
   var otActiveGroups = window.OnetrustActiveGroups || '';
   
   gtag('consent', 'update', {
     'ad_storage': otActiveGroups.includes('C0004') ? 'granted' : 'denied',
     'analytics_storage': otActiveGroups.includes('C0002') ? 'granted' : 'denied',
     'ad_user_data': otActiveGroups.includes('C0004') ? 'granted' : 'denied',
     'ad_personalization': otActiveGroups.includes('C0004') ? 'granted' : 'denied'
   });
   </script>
   ```
   Trigger: Custom Event → `OneTrustGroupsUpdated`

**OneTrust category mapping** (client-specific, verify in their OneTrust dashboard):
- C0001: Strictly Necessary
- C0002: Performance (Analytics)
- C0003: Functional
- C0004: Targeting (Advertising)

---

### CookieYes Integration

**Detect CookieYes:**
```
typeof CookieYes !== 'undefined'
```

**CookieYes events:**
```
cookieyes_consent_update
```

**GTM Setup** (use generic setup from Fix #4, trigger on CookieYes event)

---

### Custom CMP / Unknown Provider

**When client says**: "We built our own consent banner"

**Your diagnostic process:**

1. **Find the consent banner code in page source**
   - Search for: "cookie", "consent", "banner"
   - Look for JavaScript that shows/hides banner

2. **Identify what happens on user click**
   ```
   // In DevTools Console, monitor dataLayer:
   console.log(window.dataLayer);
   
   // Click "Accept" on banner
   // Watch console for new dataLayer entries
   ```

3. **Find the event name**
   - Look for: `{event: 'something', ...}`
   - Note the event name (you'll use this as GTM trigger)

4. **Check if they set cookies**
   ```
   // Check for consent cookie:
   document.cookie.split(';').forEach(c => console.log(c));
   
   // Look for cookie names containing:
   // 'consent', 'cookie', 'gdpr', 'privacy'
   ```

5. **Ask client/dev team**:
   ```
   "What JavaScript event fires when user accepts cookies?
   What cookie name stores the consent choice?"
   ```

6. **Build custom integration** using Fix #4 template with custom event name

---

## Phase 5: Validation & Testing

### Test All User Scenarios

**Scenario 1: User does nothing (default state)**
```
Expected behavior:
- consent_default = denied for all
- Tags with analytics_storage requirement: DO NOT FIRE
- Tags without consent requirements: Fire normally
```

**Scenario 2: User accepts all**
```
Expected behavior:
- consent_update = granted for all
- All tags fire
```

**Scenario 3: User rejects all**
```
Expected behavior:
- consent_update = denied for all
- Only tags without consent requirements fire
```

**Scenario 4: Granular consent** (if CMP supports):
```
User accepts: Analytics only
Expected behavior:
- analytics_storage = granted
- ad_storage = denied
- GA4 tags fire
- Google Ads tags DO NOT fire
```

### Validation Checklist

**In GTM Preview:**
- [ ] Consent tab shows consent_default first
- [ ] All 4 V2 parameters present (ad_storage, analytics_storage, ad_user_data, ad_personalization)
- [ ] User interaction triggers consent_update
- [ ] Tags respect consent requirements
- [ ] No tags fire before consent_update (except non-consent tags)

**In GA4 DebugView:**
- [ ] Navigate to GA4 → Configure → DebugView
- [ ] See events coming in
- [ ] Check event parameters include consent state
- [ ] Conversions tracked with proper consent

**In Google Ads:**
- [ ] Check remarketing tags fire only with ad_storage granted
- [ ] Verify audience list starts building (takes 24-48 hours)

**Take "After" Screenshots:**
- Consent tab showing proper sequence
- Tags tab showing consent-gated firing
- Save to: `/consent-mode-v2/client-diagnostics/[client-name]-after.png`

---

## Phase 6: Client Documentation

**Copy template from**: `/consent-mode-v2/templates/client-delivery-doc.md`

**Customize and send client:**

```
# Consent Mode V2 Implementation Summary

Client: [Name]
Date: [Date]
Implementation time: [X hours]

## What Was Fixed

### Issue Identified
[Screenshot of "before" state]
- Problem: [Describe in non-technical terms]
- Impact: [e.g., "40% of conversions not tracked", "Ads audiences not building"]

### Solution Implemented
- Created Consent Initialization trigger in GTM
- Added Consent Mode V2 parameters (ad_user_data, ad_personalization)
- Configured [CMP name] integration
- Set consent requirements on all tracking tags

### Verification
[Screenshot of "after" state]
- ✅ Consent signals fire before tags
- ✅ All 4 V2 parameters configured
- ✅ Tags respect user consent choices
- ✅ EU compliance requirements met

## GTM Changes Made

Modified tags:
1. Created: "Consent Mode - Default State (V2)"
2. Created: "Consent Update - Accept All"
3. Created: "Consent Update - Reject All"
4. Modified: [List existing tags that had consent settings added]

## Testing Performed

- [X] Default state (user doesn't interact)
- [X] Accept all cookies
- [X] Reject all cookies
- [X] GA4 events tracked with consent
- [X] Google Ads tags fire with proper consent

## Monthly Verification Steps (For Your Team)

1. Open GTM → Preview mode
2. Check Consent tab
3. Verify consent_default appears first
4. Test banner interaction
5. Confirm tags fire after consent

Expected timeline: 5 minutes/month

## Support

If consent behavior changes after:
- CMP updates
- GTM container changes
- Website code changes

Contact: [Your details]
Typical diagnostic time: 15-30 minutes
```

---

## Production Toolkit Structure

**What you're actually building:**

```
/consent-mode-v2/
├── DEBUGGING-RUNBOOK.md          ← What you just read (your field manual)
├── /snippets/                     ← Code you'll copy-paste during debugging
│   ├── consent-init-generic.html
│   ├── consent-update-accept.html
│   ├── consent-update-reject.html
│   ├── cookiebot-integration.js
│   ├── onetrust-integration.js
│   └── custom-cmp-template.js
├── /client-diagnostics/           ← Store client screenshots here
│   └── [client-name]-before.png
│   └── [client-name]-after.png
├── /templates/                    ← Copy-paste client deliverables
│   ├── client-delivery-doc.md
│   ├── testing-checklist.md
│   └── monthly-verification.md
└── /cmp-configs/                  ← CMP-specific notes
    ├── cookiebot-notes.md
    ├── onetrust-notes.md
    └── custom-cmp-template.md
```

This is your **production library** — not a portfolio piece. When you're on a call with a client and they say "our consent isn't working," you open `/consent-mode-v2/DEBUGGING-RUNBOOK.md` and follow the diagnostic steps.

Would you like me to generate the actual code files for the `/snippets/` directory next? These will be production-ready templates you can literally copy-paste into client GTM containers.
