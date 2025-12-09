const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();
  
  console.log('Testing ecommerce demo page...');
  
  // Navigate to GitHub Pages demo
  await page.goto('https://stiigg.github.io/gtm-ga4-form-tracking-demo/ecommerce.html', {
    waitUntil: 'networkidle2',
    timeout: 30000
  });
  
  // Wait for dataLayer to initialize
  await page.waitForFunction(() => window.dataLayer && window.dataLayer.length > 0);
  
  // Extract all dataLayer events
  const dataLayerEvents = await page.evaluate(() => {
    return window.dataLayer.map(obj => ({
      event: obj.event,
      ecommerce: obj.ecommerce ? {
        currency: obj.ecommerce.currency,
        value: obj.ecommerce.value,
        items: obj.ecommerce.items,
        transaction_id: obj.ecommerce.transaction_id
      } : undefined
    }));
  });
  
  console.log(`Found ${dataLayerEvents.length} dataLayer events`);
  
  // Required eCommerce events
  const requiredEvents = [
    'view_item_list',
    'view_item',
    'add_to_cart',
    'begin_checkout',
    'purchase'
  ];
  
  let allTestsPassed = true;
  
  // Validate each required event exists
  requiredEvents.forEach(eventName => {
    const found = dataLayerEvents.filter(obj => obj.event === eventName);
    if (found.length === 0) {
      console.error(`❌ FAIL: Required event "${eventName}" not found`);
      allTestsPassed = false;
    } else {
      console.log(`✅ PASS: Event "${eventName}" found (${found.length} times)`);
      
      // Validate ecommerce object structure
      const event = found[0];
      if (event.ecommerce) {
        if (!event.ecommerce.currency) {
          console.error(`❌ FAIL: Event "${eventName}" missing currency`);
          allTestsPassed = false;
        }
        
        if (eventName === 'purchase' && !event.ecommerce.transaction_id) {
          console.error(`❌ FAIL: Purchase event missing transaction_id`);
          allTestsPassed = false;
        }
        
        if (event.ecommerce.items && event.ecommerce.items.length > 0) {
          const item = event.ecommerce.items[0];
          if (!item.item_id || !item.item_name) {
            console.error(`❌ FAIL: Event "${eventName}" items missing required fields`);
            allTestsPassed = false;
          }
        }
      }
    }
  });
  
  await browser.close();
  
  if (allTestsPassed) {
    console.log('\n✅ All GA4 eCommerce events validated successfully');
    process.exit(0);
  } else {
    console.log('\n❌ Some tests failed');
    process.exit(1);
  }
})();
