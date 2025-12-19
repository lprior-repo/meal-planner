/**
 * Documentation Scraper Entry Point
 *
 * Main entry point for running documentation scrapers.
 * Scrapers are modular and can be run individually or in batch.
 */

export { type ScraperConfig, type ScraperResult } from './types.js';

// Scrapers will be exported here as they are created
// export { scrapeFatSecretDocs } from './scrapers/fatsecret.js';
// export { scrapeTandoorDocs } from './scrapers/tandoor.js';

/**
 * Main function to run scrapers
 */
async function main() {
  console.log('Documentation scraper ready.');
  console.log('Add specific scrapers to src/scrapers/ to begin.');
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}
