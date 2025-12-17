/**
 * E-commerce Event Tracking Tests
 * Tests purchase deduplication and event structure
 */

const puppeteer = require('puppeteer');

describe('E-commerce Event Tracking', () => {
  let browser;
  let page;
  
  beforeAll(async () => {
    browser = await puppeteer.launch({
      headless: 'new',
      args: ['--no-sandbox']
    });
  });
  
  afterAll(async () => {
    await browser.close();
  });
  
  beforeEach(async () => {
    page = await browser.newPage();
    await page.goto('file://' + __dirname + '/../ecommerce.html', {
      waitUntil: 'networkidle0'
    });
  });
  
  afterEach(async () => {
    await page.close();
  });
  
  test('should fire view_item_list on page load', async () => {
    await page.waitForTimeout(1000);
    
    const viewListEvent = await page.evaluate(() => {
      return window.dataLayer.find(e => e.event === 'view_item_list');
    });
    
    expect(viewListEvent).toBeDefined();
    expect(viewListEvent.ecommerce).toBeDefined();
    expect(viewListEvent.ecommerce.item_list_id).toBe('product_gallery');
    expect(viewListEvent.ecommerce.items).toBeDefined();
    expect(viewListEvent.ecommerce.items.length).toBeGreaterThan(0);
  });
  
  test('should fire add_to_cart with correct structure', async () => {
    // Click first "Add to Cart" button
    await page.click('.add-to-cart');
    
    await page.waitForTimeout(500);
    
    const addToCartEvent = await page.evaluate(() => {
      return window.dataLayer.find(e => e.event === 'add_to_cart');
    });
    
    expect(addToCartEvent).toBeDefined();
    expect(addToCartEvent.ecommerce.currency).toBe('USD');
    expect(addToCartEvent.ecommerce.value).toBeGreaterThan(0);
    expect(addToCartEvent.ecommerce.items).toBeDefined();
    expect(addToCartEvent.ecommerce.items.length).toBe(1);
    
    // Verify item structure
    const item = addToCartEvent.ecommerce.items[0];
    expect(item.item_id).toBeDefined();
    expect(item.item_name).toBeDefined();
    expect(item.price).toBeGreaterThan(0);
    expect(item.quantity).toBe(1);
  });
  
  test('should clear ecommerce object before each event', async () => {
    // Add item to cart
    await page.click('.add-to-cart');
    await page.waitForTimeout(500);
    
    // Check for ecommerce: null clearing events
    const clearEvents = await page.evaluate(() => {
      return window.dataLayer.filter(e => e.ecommerce === null);
    });
    
    expect(clearEvents.length).toBeGreaterThan(0);
  });
  
  test('should prevent duplicate purchase on page refresh', async () => {
    // Add items to cart
    const addButtons = await page.$$('.add-to-cart');
    for (const button of addButtons) {
      await button.click();
      await page.waitForTimeout(200);
    }
    
    // Begin checkout
    await page.click('#checkout-btn');
    await page.waitForTimeout(500);
    
    // Complete purchase
    await page.click('#purchase-btn');
    await page.waitForTimeout(1000);
    
    // Get transaction ID
    const txnId = await page.evaluate(() => {
      const purchaseEvent = window.dataLayer.find(e => e.event === 'purchase');
      return purchaseEvent?.ecommerce?.transaction_id;
    });
    
    expect(txnId).toBeDefined();
    
    // Reload page (simulating refresh)
    await page.reload({ waitUntil: 'networkidle0' });
    
    // Try to purchase again (should be blocked)
    await page.click('.add-to-cart');
    await page.waitForTimeout(200);
    await page.click('#checkout-btn');
    await page.waitForTimeout(200);
    await page.click('#purchase-btn');
    await page.waitForTimeout(1000);
    
    // Count purchase events
    const purchaseCount = await page.evaluate(() => {
      return window.dataLayer.filter(e => e.event === 'purchase').length;
    });
    
    expect(purchaseCount).toBe(0); // Should be blocked by deduplication
    
    // Verify blocked event was logged
    const blockedEvent = await page.evaluate(() => {
      return window.dataLayer.find(e => e.event === 'purchase_blocked');
    });
    
    expect(blockedEvent).toBeDefined();
    expect(blockedEvent.reason).toBe('duplicate_prevention');
  });
  
  test('should include transaction_id in purchase event', async () => {
    // Complete purchase flow
    await page.click('.add-to-cart');
    await page.waitForTimeout(200);
    await page.click('#checkout-btn');
    await page.waitForTimeout(200);
    await page.click('#purchase-btn');
    await page.waitForTimeout(1000);
    
    const purchaseEvent = await page.evaluate(() => {
      return window.dataLayer.find(e => e.event === 'purchase');
    });
    
    expect(purchaseEvent).toBeDefined();
    expect(purchaseEvent.ecommerce.transaction_id).toBeDefined();
    expect(purchaseEvent.ecommerce.transaction_id).toMatch(/^TXN\d+_[a-z0-9]+$/);
    expect(purchaseEvent.ecommerce.value).toBeGreaterThan(0);
    expect(purchaseEvent.ecommerce.currency).toBe('USD');
  });
});
