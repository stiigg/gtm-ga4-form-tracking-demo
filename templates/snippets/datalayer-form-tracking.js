// PRODUCTION FORM TRACKING - COPY THIS TO CLIENT SITE
// Update: form_id, form_type, form_location per client

(function() {
  var form = document.getElementById('YOUR_FORM_ID');
  if (!form) return;

  // Generate unique instance ID once per form load (SPA-ready)
  var instance_id = Date.now() + '_' + Math.random().toString(16).slice(2);

  form.addEventListener('submit', function(e) {
    e.preventDefault();

    // Anti-double-fire guard
    if (window.formSubmitted) return;
    window.formSubmitted = true;

    // Collect form data
    var formData = new FormData(form);
    var formFields = {};
    formData.forEach(function(value, key) {
      formFields[key] = value;
    });

    // Push to dataLayer
    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push({
      event: 'form_submission_success',
      form_id: 'REPLACE_WITH_CLIENT_FORM_ID',      // e.g., 'contact_us', 'demo_request'
      instance_id: instance_id,                    // Unique per form load (enables multi-step correlation)
      form_type: 'REPLACE_WITH_TYPE',              // e.g., 'lead', 'support', 'sales'
      form_location: 'REPLACE_WITH_LOCATION',      // e.g., 'homepage', 'pricing_page'
      form_fields: formFields                      // Actual form field values
    });

    // Submit form after dataLayer push
    setTimeout(function() {
      form.submit();
    }, 500);
  });
})();
