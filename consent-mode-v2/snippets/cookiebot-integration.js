(function() {
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}

  function syncConsentFromCookiebot(eventLabel) {
    if (!window.Cookiebot || !Cookiebot.consent) {
      console.warn('[Consent V2][Cookiebot] Cookiebot unavailable when trying to sync consent');
      return;
    }

    var consents = Cookiebot.consent;
    gtag('consent', 'update', {
      'ad_storage': consents.marketing ? 'granted' : 'denied',
      'ad_user_data': consents.marketing ? 'granted' : 'denied',
      'ad_personalization': consents.marketing ? 'granted' : 'denied',
      'analytics_storage': consents.statistics ? 'granted' : 'denied'
    });

    console.log('[Consent V2][Cookiebot] Consent synced (' + (eventLabel || 'initial') + ')');
  }

  if (window.Cookiebot && Cookiebot.consent) {
    syncConsentFromCookiebot('page load');
  }

  window.addEventListener('CookiebotOnAccept', function() {
    syncConsentFromCookiebot('accept');
  });

  window.addEventListener('CookiebotOnDecline', function() {
    syncConsentFromCookiebot('decline');
  });
})();
