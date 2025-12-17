(function() {
  // Replace `custom_consent_event` with the event your CMP pushes to dataLayer
  var CMP_EVENT_NAME = 'custom_consent_event';

  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}

  function syncConsentFromCustomPayload(payload, eventLabel) {
    // Map your CMP payload to Google Consent Mode fields
    // Example payload shape: { marketing: true, analytics: false }
    var marketingGranted = !!(payload && payload.marketing);
    var analyticsGranted = !!(payload && payload.analytics);

    gtag('consent', 'update', {
      'ad_storage': marketingGranted ? 'granted' : 'denied',
      'ad_user_data': marketingGranted ? 'granted' : 'denied',
      'ad_personalization': marketingGranted ? 'granted' : 'denied',
      'analytics_storage': analyticsGranted ? 'granted' : 'denied'
    });

    console.log('[Consent V2][Custom CMP] Consent synced (' + (eventLabel || 'custom event') + ')');
  }

  window.addEventListener('message', function(event) {
    // Optionally listen for postMessage from iframed CMP
    if (event.data && event.data.type === CMP_EVENT_NAME) {
      syncConsentFromCustomPayload(event.data.payload, 'postMessage');
    }
  });

  // Data Layer listener
  window.dataLayer.push({
    'event': 'cmp_listener_init'
  });

  // Listen to dataLayer pushes from CMP
  var originalPush = window.dataLayer.push;
  window.dataLayer.push = function() {
    var args = Array.prototype.slice.call(arguments);
    for (var i = 0; i < args.length; i++) {
      var item = args[i];
      if (item && item.event === CMP_EVENT_NAME) {
        syncConsentFromCustomPayload(item, CMP_EVENT_NAME);
      }
    }
    return originalPush.apply(window.dataLayer, args);
  };
})();
