#!/usr/bin/env tsx
/**
 * FatSecret Profile API Scraper Runner
 *
 * Standalone script to scrape FatSecret Profile API documentation
 * for 3-legged OAuth endpoints.
 *
 * Usage:
 *   npm run scrape:profile
 *   tsx scripts/scrape-profile.ts
 */

import { scrapeProfileDocs } from '../src/scrapers/profile.js';

async function main() {
  console.log('='.repeat(60));
  console.log('FatSecret Profile API Documentation Scraper');
  console.log('='.repeat(60));
  console.log();

  try {
    await scrapeProfileDocs();
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
