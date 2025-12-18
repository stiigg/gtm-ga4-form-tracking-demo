// Client-side + server-side deduplication pattern
// Generate once, then reuse across channels
const event_id = `${eventName}_${instance_id}`;

window.dataLayer = window.dataLayer || [];
window.dataLayer.push({
  event: eventName,
  form_id: 'contact_us',
  instance_id: instance_id,
  event_id: event_id,      // Dedup key
  tracking_source: 'client'
});
