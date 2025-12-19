/**
 * Documentation Scraper Entry Point
 *
 * Main entry point for running documentation scrapers.
 * Scrapers are modular and can be run individually or in batch.
 */

export { type ScraperConfig, type ScraperResult } from './types.js';

// Scrapers
export { RecipesScraper, scrapeRecipesDocs } from './scrapers/recipes.js';
export { ProfileScraper, scrapeProfileDocs } from './scrapers/profile.js';
export { BrandsScraper, scrapeBrandsDocs } from './scrapers/brands.js';

/**
 * Main function to run scrapers
 */
async function main() {
  console.log('Documentation scraper ready.');

  // Example: Run the recipes scraper
  // Uncomment to execute:
  // await scrapeRecipesDocs();

  console.log('Available scrapers:');
  console.log('  - RecipesScraper: FatSecret Recipes API documentation');
  console.log('  - ProfileScraper: FatSecret Profile API (3-legged OAuth) documentation');
  console.log('  - BrandsScraper: FatSecret Food Brands API documentation');
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}
