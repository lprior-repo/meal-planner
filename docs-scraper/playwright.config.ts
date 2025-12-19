import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for documentation scraping
 *
 * Key settings:
 * - Single worker to avoid rate limiting
 * - 60s navigation timeout for slow doc sites
 * - Headless mode for CI/CD compatibility
 * - Chromium only (sufficient for modern docs)
 */
export default defineConfig({
  testDir: './tests',

  // Run tests sequentially to avoid overwhelming doc sites
  fullyParallel: false,
  workers: 1,

  // Fail the build on CI if you accidentally left test.only in the source code
  forbidOnly: !!process.env.CI,

  // Retry failed tests once on CI
  retries: process.env.CI ? 1 : 0,

  // Reporter configuration
  reporter: 'html',

  // Shared settings for all projects
  use: {
    // Base URL - can be overridden per scraper
    baseURL: process.env.BASE_URL || 'http://localhost:3000',

    // Collect trace on failure
    trace: 'on-first-retry',

    // Screenshot on failure
    screenshot: 'only-on-failure',

    // Extended timeout for navigation (some doc sites are slow)
    navigationTimeout: 60000,

    // Extended timeout for actions
    actionTimeout: 10000,
  },

  // Configure projects for major browsers
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        // Reasonable viewport for documentation
        viewport: { width: 1280, height: 720 },
      },
    },
  ],

  // Run your local dev server before starting the tests (optional)
  // webServer: {
  //   command: 'npm run start',
  //   url: 'http://localhost:3000',
  //   reuseExistingServer: !process.env.CI,
  // },
});
