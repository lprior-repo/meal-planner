/**
 * Example script to scrape FatSecret Foods API documentation
 *
 * Usage:
 *   npm run scrape -- examples/scrape-foods.ts
 *   or
 *   tsx examples/scrape-foods.ts
 */

import { FoodsScraper } from '../src/scrapers/foods.js';
import { ScraperConfig } from '../src/types.js';
import { join } from 'path';

async function main() {
  const config: ScraperConfig = {
    baseUrl: 'https://platform.fatsecret.com/docs/guides',
    outputPath: join(process.cwd(), 'output'),
    timeout: 30000,
  };

  console.log('Starting FatSecret Foods API documentation scraper...');
  console.log(`Base URL: ${config.baseUrl}`);
  console.log(`Output directory: ${config.outputPath}`);
  console.log();

  const scraper = new FoodsScraper(config);

  try {
    await scraper.run();
    console.log();
    console.log('✓ Scraping completed successfully!');
    console.log(`Check ${config.outputPath}/markdown/foods/ for documentation`);
    console.log(`Check ${config.outputPath}/fixtures/foods/ for JSON examples`);
  } catch (error) {
    console.error('✗ Scraping failed:', error);
    process.exit(1);
  }
}

main();
