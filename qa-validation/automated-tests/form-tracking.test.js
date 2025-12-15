/**
 * Form Tracking Validation Tests
 * Tests the "Good" form implementation from index.html
 */

const puppeteer = require('puppeteer');

describe('Form Tracking Implementation', () => {
  let browser;
  let page;
  
  beforeAll(async () => {
    browser = await puppeteer.launch({
      headless: 'new',
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
  });
  
  afterAll(async () => {
    await browser.close();
  });
  
  beforeEach(async () => {
    page = await browser.newPage();
    
    // Enable console logging
    page.on('console', msg => {
      console.log('PAGE LOG:', msg.text());
    });
    
    // Navigate to demo page
    await page.goto('file://' + __dirname + '/../index.html', {
      waitUntil: 'networkidle0'
    });
  });
  
  afterEach(async () => {
    await page.close();
  });
  
  test('should initialize dataLayer on page load', async () => {
    const dataLayer = await page.evaluate(() => window.dataLayer);
    
    expect(dataLayer).toBeDefined();
    expect(Array.isArray(dataLayer)).toBe(true);
    expect(dataLayer.length).toBeGreaterThan(0);
  });
  
  test('should NOT fire event when form is incomplete', async () => {
    // Get initial dataLayer length
    const initialLength = await page.evaluate(() => window.dataLayer.length);
    
    // Fill only name field (incomplete form)
    await page.type('#good-name', 'Test User');
    
    // Try to submit
    await page.click('button[type="submit"]');
    
    // Wait a bit
    await page.waitForTimeout(500);
    
    // Check dataLayer hasn't grown
    const finalLength = await page.evaluate(() => window.dataLayer.length);
    
    expect(finalLength).toBe(initialLength);
  });
  
  test('should fire form_submission_success when form is valid', async () => {
    // Fill complete form
    await page.type('#good-name', 'Test User');
    await page.type('#good-email', 'test@example.com');
    await page.select('#good-topic', 'support');
    await page.click('#good-basic');
    
    // Submit form
    await page.click('button[type="submit"]');
    
    // Wait for event
    await page.waitForTimeout(1000);
    
    // Check dataLayer for event
    const formEvent = await page.evaluate(() => {
      return window.dataLayer.find(e => e.event === 'form_submission_success');
    });
    
    expect(formEvent).toBeDefined();
    expect(formEvent.form_id).toBe('contact_us');
    expect(formEvent.form_type).toBe('lead');
    expect(formEvent.form_location).toBe('demo_page');
    expect(formEvent.form_fields).toBeDefined();
    expect(formEvent.form_fields.topic).toBe('support');
    expect(formEvent.form_fields.plan).toBe('basic');
  });
  
  test('should prevent double-firing on rapid clicks', async () => {
    // Fill form
    await page.type('#good-name', 'Test User');
    await page.type('#good-email', 'test@example.com');
    await page.select('#good-topic', 'support');
    await page.click('#good-basic');
    
    // Get initial dataLayer length
    const initialLength = await page.evaluate(() => window.dataLayer.length);
    
    // Submit multiple times rapidly
    await page.click('button[type="submit"]');
    await page.click('button[type="submit"]');
    await page.click('button[type="submit"]');
    
    await page.waitForTimeout(1000);
    
    // Count form_submission_success events
    const eventCount = await page.evaluate(() => {
      return window.dataLayer.filter(e => e.event === 'form_submission_success').length;
    });
    
    expect(eventCount).toBe(1); // Should only fire once
  });
  
  test('should display success message after submission', async () => {
    // Fill and submit form
    await page.type('#good-name', 'Test User');
    await page.type('#good-email', 'test@example.com');
    await page.select('#good-topic', 'support');
    await page.click('#good-basic');
    await page.click('button[type="submit"]');
    
    await page.waitForTimeout(1000);
    
    // Check success message is visible
    const successVisible = await page.evaluate(() => {
      const el = document.getElementById('good-success');
      return el && el.style.display !== 'none';
    });
    
    expect(successVisible).toBe(true);
  });
});
