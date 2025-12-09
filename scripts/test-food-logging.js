const { chromium } = require('playwright');

async function testFoodLogging() {
  console.log('🎭 Starting Playwright test for food logging...\n');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // Step 1: Navigate to a food detail page with good nutrition data
    const foodId = '168741'; // Top round steak with 115 nutrients
    const foodUrl = `http://localhost:8080/foods/${foodId}`;

    console.log(`📍 Navigating to ${foodUrl}`);
    await page.goto(foodUrl);
    await page.waitForLoadState('networkidle');

    // Step 2: Verify the page loaded
    const title = await page.title();
    console.log(`✓ Page loaded: ${title}`);

    // Step 3: Check for "Log This Food" button
    const logButton = await page.locator('a.btn.btn-primary:has-text("Log This Food")');
    const buttonExists = await logButton.count() > 0;
    console.log(`${buttonExists ? '✓' : '✗'} "Log This Food" button ${buttonExists ? 'found' : 'NOT FOUND'}`);

    if (!buttonExists) {
      throw new Error('Log button not found on page!');
    }

    // Step 4: Click the button to go to logging form
    console.log('\n📝 Clicking "Log This Food" button...');
    await logButton.click();
    await page.waitForLoadState('networkidle');

    const logFormTitle = await page.title();
    console.log(`✓ Navigated to: ${logFormTitle}`);

    // Step 5: Fill out the form
    console.log('\n📋 Filling out food logging form...');

    // Check form fields exist
    const gramsInput = page.locator('input[name="grams"]');
    const mealTypeSelect = page.locator('select[name="meal_type"]');
    const submitButton = page.locator('button[type="submit"]:has-text("Log Food")');

    console.log(`✓ Grams input: ${await gramsInput.count() > 0 ? 'found' : 'NOT FOUND'}`);
    console.log(`✓ Meal type select: ${await mealTypeSelect.count() > 0 ? 'found' : 'NOT FOUND'}`);
    console.log(`✓ Submit button: ${await submitButton.count() > 0 ? 'found' : 'NOT FOUND'}`);

    // Fill in the form
    await gramsInput.fill('200'); // 200 grams
    await mealTypeSelect.selectOption('lunch');

    console.log('✓ Form filled: 200g, meal type: lunch');

    // Step 6: Submit the form
    console.log('\n🚀 Submitting form...');
    await submitButton.click();
    await page.waitForLoadState('networkidle', { timeout: 10000 });

    // Step 7: Check for success or error
    const currentUrl = page.url();
    const pageContent = await page.content();

    console.log(`\n📍 After submit, URL: ${currentUrl}`);

    // Check for success message
    const hasSuccess = pageContent.includes('Added to log') || pageContent.includes('success');
    const hasError = pageContent.includes('error') || pageContent.includes('Error');
    const redirectedToDashboard = currentUrl.includes('/dashboard');

    console.log(`${hasSuccess ? '✅' : '⚠️'} Success message: ${hasSuccess ? 'YES' : 'NO'}`);
    console.log(`${hasError ? '❌' : '✅'} Error message: ${hasError ? 'YES' : 'NO'}`);
    console.log(`${redirectedToDashboard ? '✅' : '⚠️'} Redirected to dashboard: ${redirectedToDashboard ? 'YES' : 'NO'}`);

    // Get the response status
    const finalContent = await page.content();
    if (finalContent.includes('Unsupported media type')) {
      console.log('\n❌ ERROR: Still getting "Unsupported media type"');
      console.log('Response preview:', finalContent.substring(0, 500));
      throw new Error('Unsupported media type error persists');
    }

    if (hasError && !hasSuccess) {
      console.log('\n❌ Form submission failed with error');
      console.log('Error content:', finalContent.substring(0, 500));
      throw new Error('Form submission error');
    }

    console.log('\n✅ SUCCESS! Food logging works correctly!');
    return true;

  } catch (error) {
    console.error('\n❌ TEST FAILED:', error.message);

    // Take a screenshot for debugging
    try {
      await page.screenshot({ path: '/tmp/food-logging-error.png' });
      console.log('📸 Screenshot saved to /tmp/food-logging-error.png');
    } catch (e) {}

    throw error;
  } finally {
    await browser.close();
  }
}

// Run the test
testFoodLogging()
  .then(() => {
    console.log('\n🎉 All tests passed!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Test suite failed');
    process.exit(1);
  });
