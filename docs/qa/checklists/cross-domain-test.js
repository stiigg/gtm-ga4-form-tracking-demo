/**
 * Automated Cross-Domain Tracking Test
 * Run with: node cross-domain-test.js
 * Requires: npm install puppeteer
 */

const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({ headless: false });
  const page = await browser.newPage();
  
  // Enable console logging
  page.on('console', msg => console.log('PAGE LOG:', msg.text()));
  
  // Step 1: Visit main store
  await page.goto('https://shop.example.com/products/test-product');
  
  // Get initial GA cookie
  const cookies = await page.cookies();
  const gaCookie = cookies.find(c => c.name === '_ga');
  console.log('Domain A _ga cookie:', gaCookie.value);
  
  // Step 2: Add to cart and navigate to checkout domain
  await page.click('.add-to-cart-button');
  await page.waitForTimeout(1000);
  await page.click('.checkout-button');
  await page.waitForNavigation();
  
  // Step 3: Verify linker parameter
  const currentUrl = page.url();
  const hasLinker = currentUrl.includes('_gl=');
  console.log('Linker parameter present:', hasLinker ? '✓' : '✗');
  
  // Step 4: Check cookie persistence
  const checkoutCookies = await page.cookies();
  const checkoutGaCookie = checkoutCookies.find(c => c.name === '_ga');
  console.log('Domain B _ga cookie:', checkoutGaCookie.value);
  
  const cookieMatch = gaCookie.value === checkoutGaCookie.value;
  console.log('Cookie values match:', cookieMatch ? '✓ PASS' : '✗ FAIL');
  
  await browser.close();
})();
