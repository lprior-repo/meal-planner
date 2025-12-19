/**
 * Example: Scrape FatSecret Recipes API documentation
 *
 * Usage: tsx examples/scrape-recipes.ts
 */

import { scrapeRecipesDocs } from '../src/index.js';

async function main() {
  console.log('Starting FatSecret Recipes API documentation scraper...\n');

  try {
    await scrapeRecipesDocs({
      outputPath: 'output/markdown/recipes',
    });

    console.log('\nScraping completed successfully!');
    console.log('Check output/markdown/recipes/ for markdown files');
    console.log('Check output/fixtures/recipes/ for JSON fixtures');
  } catch (error) {
    console.error('Error during scraping:', error);
    process.exit(1);
  }
}

main();
