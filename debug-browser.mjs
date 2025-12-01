import puppeteer from 'puppeteer';

const browser = await puppeteer.launch({ headless: true });
const page = await browser.newPage();

// Collect all console messages
page.on('console', msg => {
  console.log(`[${msg.type()}] ${msg.text()}`);
});

// Collect page errors
page.on('pageerror', err => {
  console.log('[pageerror]', err.message);
});

// Collect request failures
page.on('requestfailed', request => {
  console.log('[requestfailed]', request.url(), request.failure()?.errorText);
});

// Log all requests and their status
page.on('response', response => {
  if (response.status() >= 400) {
    console.log('[response 4xx]', response.status(), response.url());
  }
});

try {
  console.log('Navigating to http://localhost:1234...');
  await page.goto('http://localhost:1234', { waitUntil: 'networkidle0', timeout: 10000 });

  // Wait a bit for any async errors
  await new Promise(r => setTimeout(r, 2000));

  // Check the DOM
  const appContent = await page.evaluate(() => {
    const app = document.querySelector('#app');
    return {
      innerHTML: app?.innerHTML || 'NO CONTENT',
      childCount: app?.childElementCount || 0
    };
  });

  console.log('\n--- DOM State ---');
  console.log('Child count:', appContent.childCount);
  console.log('Content preview:', appContent.innerHTML.substring(0, 500));

} catch (err) {
  console.error('Navigation error:', err.message);
} finally {
  await browser.close();
}
