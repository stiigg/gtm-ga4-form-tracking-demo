/**
 * Google Consent Mode v2 - Baseline Configuration
 * 
 * CRITICAL: Load this BEFORE GTM container snippet in <head>
 * 
 * Purpose: Sets default consent state to GDPR-compliant 'denied' until
 * user interacts with Cookie Consent Platform (CMP).
 * 
 * Mandatory since March 2024 for EEA/UK targeting.
 * Affects Google Ads conversion modeling and GA4 behavioral modeling.
 * 
 * Integration: Works with OneTrust, Cookiebot, Complianz, or custom CMP.
 */

window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}

// Set default consent state (GDPR-safe: all denied)
gtag('consent', 'default', {
  'ad_storage': 'denied',           // Google Ads cookies
  'ad_user_data': 'denied',         // User data for ads (NEW in v2)
  'ad_personalization': 'denied',   // Personalized ads (NEW in v2)
  'analytics_storage': 'denied',    // GA4 cookies
  'functionality_storage': 'denied', // Functional cookies
  'personalization_storage': 'denied', // Personalization cookies
  'security_storage': 'granted',    // Always granted (security essentials)
  'wait_for_update': 500            // Wait 500ms for CMP to load
});

/**
 * Helper function: CMP should call this when user updates consent
 * 
 * Example usage:
 *   // User accepts analytics only
 *   window.updateConsent({ analytics: true, ads: false });
 *   
 *   // User accepts all
 *   window.updateConsent({ analytics: true, ads: true });
 */
window.updateConsent = function(consent) {
  gtag('consent', 'update', {
    'ad_storage': consent.ads ? 'granted' : 'denied',
    'ad_user_data': consent.ads ? 'granted' : 'denied',
    'ad_personalization': consent.ads ? 'granted' : 'denied',
    'analytics_storage': consent.analytics ? 'granted' : 'denied',
    'functionality_storage': consent.functional ? 'granted' : 'denied',
    'personalization_storage': consent.personalization ? 'granted' : 'denied'
  });
  
  console.log('[Consent Mode v2] Consent updated:', consent);
};

/**
 * Region-specific defaults (optional advanced implementation)
 * 
 * For EEA/UK: Start denied, require explicit consent
 * For other regions: Can start granted (no GDPR requirement)
 */
function getRegionCode() {
  // Simple IP geolocation would go here
  // Or use CMP's built-in region detection
  return 'unknown';
}

const region = getRegionCode();
const isEEAorUK = ['DE', 'FR', 'GB', 'IT', 'ES', 'NL'].includes(region);

if (!isEEAorUK && region !== 'unknown') {
  // Non-EEA regions can default to granted
  gtag('consent', 'default', {
    'analytics_storage': 'granted',
    'ad_storage': 'granted',
    'ad_user_data': 'granted',
    'ad_personalization': 'granted'
  });
}

/**
 * Debugging: Check consent state in console
 */
if (window.location.search.includes('consent_debug=1')) {
  gtag('get', 'G-XXXXXXXXX', 'consent', (consent) => {
    console.table(consent);
  });
}
