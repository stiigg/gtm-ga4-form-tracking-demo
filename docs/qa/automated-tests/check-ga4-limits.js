const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();
  
  console.log('Checking GA4 parameter limits...');
  
  await page.goto('https://stiigg.github.io/gtm-ga4-form-tracking-demo/ecommerce.html', {
    waitUntil: 'networkidle2'
  });
  
  await page.waitForFunction(() => window.dataLayer && window.dataLayer.length > 0);
  
  const validation = await page.evaluate(() => {
    const events = window.dataLayer.filter(obj => obj.event);
    const issues = [];
    
    events.forEach(event => {
      // Check event name length (max 40 characters)
      if (event.event.length > 40) {
        issues.push(`Event name "${event.event}" exceeds 40 characters`);
      }
      
      // Check parameter count (max 25 custom parameters)
      const paramCount = Object.keys(event).length - 1; // -1 for 'event' key
      if (paramCount > 25) {
        issues.push(`Event "${event.event}" has ${paramCount} parameters (max 25)`);
      }
      
      // Check parameter name lengths (max 40 characters)
      Object.keys(event).forEach(key => {
        if (key.length > 40) {
          issues.push(`Parameter "${key}" exceeds 40 characters`);
        }
      });
      
      // Check parameter value lengths (max 100 characters)
      Object.entries(event).forEach(([key, value]) => {
        if (typeof value === 'string' && value.length > 100 && key !== 'event') {
          issues.push(`Parameter "${key}" value exceeds 100 characters in event "${event.event}"`);
        }
      });
      
      // Check item array size (max 200 items)
      if (event.ecommerce && event.ecommerce.items && event.ecommerce.items.length > 200) {
        issues.push(`Event "${event.event}" has ${event.ecommerce.items.length} items (max 200)`);
      }
    });
    
    return issues;
  });
  
  await browser.close();
  
  if (validation.length === 0) {
    console.log('✅ All GA4 parameter limits validated');
    process.exit(0);
  } else {
    console.log('❌ GA4 parameter limit violations found:');
    validation.forEach(issue => console.log(`  - ${issue}`));
    process.exit(1);
  }
})();
