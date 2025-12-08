# GA4 DebugView Not Showing Events

1. **Debug Mode**: Enable debug mode via GTM preview or `gtm_debug=x` URL param.
2. **Time Lag**: Wait up to 60 seconds; DebugView can delay during peak hours.
3. **Filters**: Check GA4 data filters (Internal/Developer) not excluding your IP.
4. **Tag Delivery**: Verify GA4 Configuration tag fires on all pages.
5. **Network Errors**: Open Network tab → filter for `collect` requests; ensure 200 responses.
6. **Ad Blockers**: Disable blockers or use Chrome Incognito.
7. **Measurement ID**: Confirm correct Measurement ID in GTM vs GA4 property.
8. **Cross-Domain**: If using gtag, ensure `transport_url` not blocked; otherwise rely on GTM.
