/**
 * Test suite for BrandsScraper
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { BrandsScraper } from '../src/scrapers/brands.js';
import { ScraperConfig } from '../src/types.js';
import { existsSync } from 'fs';
import { readFile, rm } from 'fs/promises';
import { join } from 'path';

describe('BrandsScraper', () => {
  let scraper: BrandsScraper;
  let config: ScraperConfig;
  const testOutputDir = join(process.cwd(), 'output', 'test');

  beforeEach(() => {
    config = {
      baseUrl: 'https://platform.fatsecret.com/docs/guides',
      outputPath: testOutputDir,
      timeout: 30000,
    };
    scraper = new BrandsScraper(config);
  });

  afterEach(async () => {
    // Clean up test output directory
    if (existsSync(testOutputDir)) {
      await rm(testOutputDir, { recursive: true, force: true });
    }
  });

  describe('extractJsonBlocks', () => {
    it('should extract JSON code blocks from HTML content', async () => {
      const html = `
        <pre><code class="language-json">
        {
          "brand_id": "123",
          "brand_name": "Acme Foods",
          "brand_type": "Manufacturer"
        }
        </code></pre>
      `;

      const blocks = await scraper.extractJsonBlocks(html);
      expect(blocks).toHaveLength(1);
      expect(blocks[0]).toContain('brand_id');
      expect(blocks[0]).toContain('Acme Foods');
    });

    it('should handle multiple JSON blocks', async () => {
      const html = `
        <pre><code class="language-json">{"brand_id": "1"}</code></pre>
        <pre><code class="language-json">{"brand_id": "2"}</code></pre>
      `;

      const blocks = await scraper.extractJsonBlocks(html);
      expect(blocks).toHaveLength(2);
    });

    it('should return empty array when no JSON blocks found', async () => {
      const html = '<p>No JSON here</p>';
      const blocks = await scraper.extractJsonBlocks(html);
      expect(blocks).toHaveLength(0);
    });
  });

  describe('extractParameters', () => {
    it('should extract parameter information from table HTML', async () => {
      const html = `
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Type</th>
              <th>Required</th>
              <th>Description</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>starts_with</td>
              <td>string</td>
              <td>No</td>
              <td>Filter brands starting with this text</td>
            </tr>
            <tr>
              <td>brand_type</td>
              <td>string</td>
              <td>No</td>
              <td>Filter by brand type (Manufacturer, Restaurant, Supermarket)</td>
            </tr>
          </tbody>
        </table>
      `;

      const params = await scraper.extractParameters(html);
      expect(params).toHaveLength(2);
      expect(params[0]).toMatchObject({
        name: 'starts_with',
        type: 'string',
        required: false,
        description: expect.stringContaining('starting with'),
      });
      expect(params[1]).toMatchObject({
        name: 'brand_type',
        type: 'string',
        required: false,
        description: expect.stringContaining('Manufacturer'),
      });
    });

    it('should handle missing optional columns gracefully', async () => {
      const html = `
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Description</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>query</td>
              <td>Brand search query</td>
            </tr>
          </tbody>
        </table>
      `;

      const params = await scraper.extractParameters(html);
      expect(params).toHaveLength(1);
      expect(params[0].name).toBe('query');
      expect(params[0].description).toContain('search query');
    });

    it('should return empty array when no table found', async () => {
      const html = '<p>No table here</p>';
      const params = await scraper.extractParameters(html);
      expect(params).toHaveLength(0);
    });
  });

  describe('saveOutput', () => {
    it('should save markdown and JSON files for endpoint', async () => {
      const endpointName = 'brands.get.v2';
      const markdown = '# Brands Get\n\nGet brand information...';
      const jsonExample = {
        brands: [{ brand_id: '123', brand_name: 'Acme', brand_type: 'Manufacturer' }],
      };

      await scraper.saveOutput(endpointName, markdown, jsonExample);

      const mdPath = join(testOutputDir, 'markdown', 'food_brands', `${endpointName}.md`);
      const jsonPath = join(testOutputDir, 'fixtures', 'food_brands', `${endpointName}.json`);

      expect(existsSync(mdPath)).toBe(true);
      expect(existsSync(jsonPath)).toBe(true);

      const mdContent = await readFile(mdPath, 'utf-8');
      expect(mdContent).toBe(markdown);

      const jsonContent = await readFile(jsonPath, 'utf-8');
      const parsed = JSON.parse(jsonContent);
      expect(parsed).toMatchObject(jsonExample);
    });

    it('should create nested directories as needed', async () => {
      const endpointName = 'brand.search.v1';
      await scraper.saveOutput(endpointName, '# Test', { test: true });

      const mdPath = join(testOutputDir, 'markdown', 'food_brands', `${endpointName}.md`);
      expect(existsSync(mdPath)).toBe(true);
    });
  });

  describe('navigateToCategory', () => {
    it.skip('should navigate to Food Brands section and return endpoint links', async () => {
      // This test is skipped by default as it requires network access
      // and may fail if FatSecret docs structure changes
      // Run manually with: npm test -- --run brands-scraper.test.ts
      const links = await scraper.navigateToCategory();

      // Should find the 2 target endpoints
      expect(links.length).toBeGreaterThanOrEqual(2);

      const endpointNames = links.map((link) => link.title);
      expect(endpointNames).toContain('brands.get.v2');
      expect(endpointNames).toContain('brand.search.v1');
    }, 60000); // 60 second timeout for network operation
  });
});
