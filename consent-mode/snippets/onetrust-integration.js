(function() {
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}

  function syncConsentFromOneTrust(eventLabel) {
    var activeGroups = window.OnetrustActiveGroups || '';

    gtag('consent', 'update', {
      'ad_storage': activeGroups.includes('C0004') ? 'granted' : 'denied',
      'ad_user_data': activeGroups.includes('C0004') ? 'granted' : 'denied',
      'ad_personalization': activeGroups.includes('C0004') ? 'granted' : 'denied',
      'analytics_storage': activeGroups.includes('C0002') ? 'granted' : 'denied'
    });

    console.log('[Consent V2][OneTrust] Consent synced (' + (eventLabel || 'initial') + ')');
  }

  if (window.OneTrust && typeof window.OnetrustActiveGroups !== 'undefined') {
    syncConsentFromOneTrust('page load');
  }

  window.addEventListener('OneTrustGroupsUpdated', function() {
    syncConsentFromOneTrust('OneTrustGroupsUpdated');
  });
})();
