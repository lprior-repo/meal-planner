#!/usr/bin/env tsx
/**
 * FatSecret Food Brands API Scraper Runner
 *
 * Standalone script to scrape FatSecret Food Brands API documentation
 * for brand listing and search endpoints.
 *
 * Usage:
 *   npm run scrape:brands
 *   tsx scripts/scrape-brands.ts
 */

import { scrapeBrandsDocs } from '../src/scrapers/brands.js';

async function main() {
  console.log('='.repeat(60));
  console.log('FatSecret Food Brands API Documentation Scraper');
  console.log('='.repeat(60));
  console.log();

  try {
    await scrapeBrandsDocs();
    console.log();
    console.log('='.repeat(60));
    console.log('Scraping completed successfully!');
    console.log('='.repeat(60));
  } catch (error) {
    console.error();
    console.error('='.repeat(60));
    console.error('Scraping failed:', error);
    console.error('='.repeat(60));
    process.exit(1);
  }
}

main();
