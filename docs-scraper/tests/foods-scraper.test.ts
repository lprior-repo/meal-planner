/**
 * Test suite for FoodsScraper
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { FoodsScraper } from '../src/scrapers/foods.js';
import { ScraperConfig } from '../src/types.js';
import { existsSync } from 'fs';
import { readFile, rm } from 'fs/promises';
import { join } from 'path';

describe('FoodsScraper', () => {
  let scraper: FoodsScraper;
  let config: ScraperConfig;
  const testOutputDir = join(process.cwd(), 'output', 'test');

  beforeEach(() => {
    config = {
      baseUrl: 'https://platform.fatsecret.com/docs/guides',
      outputPath: testOutputDir,
      timeout: 30000,
    };
    scraper = new FoodsScraper(config);
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
          "food_id": "12345",
          "food_name": "Apple"
        }
        </code></pre>
      `;

      const blocks = await scraper.extractJsonBlocks(html);
      expect(blocks).toHaveLength(1);
      expect(blocks[0]).toContain('food_id');
      expect(blocks[0]).toContain('Apple');
    });

    it('should handle multiple JSON blocks', async () => {
      const html = `
        <pre><code class="language-json">{"id": 1}</code></pre>
        <pre><code class="language-json">{"id": 2}</code></pre>
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
              <td>food_id</td>
              <td>string</td>
              <td>Yes</td>
              <td>The unique food identifier</td>
            </tr>
            <tr>
              <td>format</td>
              <td>string</td>
              <td>No</td>
              <td>Response format (json/xml)</td>
            </tr>
          </tbody>
        </table>
      `;

      const params = await scraper.extractParameters(html);
      expect(params).toHaveLength(2);
      expect(params[0]).toMatchObject({
        name: 'food_id',
        type: 'string',
        required: true,
        description: expect.stringContaining('unique food identifier'),
      });
      expect(params[1]).toMatchObject({
        name: 'format',
        type: 'string',
        required: false,
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
              <td>Search query text</td>
            </tr>
          </tbody>
        </table>
      `;

      const params = await scraper.extractParameters(html);
      expect(params).toHaveLength(1);
      expect(params[0].name).toBe('query');
      expect(params[0].description).toContain('Search query');
    });

    it('should return empty array when no table found', async () => {
      const html = '<p>No table here</p>';
      const params = await scraper.extractParameters(html);
      expect(params).toHaveLength(0);
    });
  });

  describe('saveOutput', () => {
    it('should save markdown and JSON files for endpoint', async () => {
      const endpointName = 'foods.search.v3';
      const markdown = '# Foods Search\n\nSearch for foods...';
      const jsonExample = { foods: [{ food_id: '123' }] };

      await scraper.saveOutput(endpointName, markdown, jsonExample);

      const mdPath = join(testOutputDir, 'markdown', 'foods', `${endpointName}.md`);
      const jsonPath = join(testOutputDir, 'fixtures', 'foods', `${endpointName}.json`);

      expect(existsSync(mdPath)).toBe(true);
      expect(existsSync(jsonPath)).toBe(true);

      const mdContent = await readFile(mdPath, 'utf-8');
      expect(mdContent).toBe(markdown);

      const jsonContent = await readFile(jsonPath, 'utf-8');
      const parsed = JSON.parse(jsonContent);
      expect(parsed).toMatchObject(jsonExample);
    });

    it('should create nested directories as needed', async () => {
      const endpointName = 'food.get.v5';
      await scraper.saveOutput(endpointName, '# Test', { test: true });

      const mdPath = join(testOutputDir, 'markdown', 'foods', `${endpointName}.md`);
      expect(existsSync(mdPath)).toBe(true);
    });
  });

  describe('navigateToCategory', () => {
    it.skip('should navigate to Foods section and return endpoint links', async () => {
      // This test is skipped by default as it requires network access
      // and may fail if FatSecret docs structure changes
      // Run manually with: npm test -- --run foods-scraper.test.ts
      const links = await scraper.navigateToCategory();

      // Should find the 4 target endpoints
      expect(links.length).toBeGreaterThanOrEqual(4);

      const endpointNames = links.map((link) => link.title);
      expect(endpointNames).toContain('foods.autocomplete.v2');
      expect(endpointNames).toContain('food.find_id_for_barcode.v2');
      expect(endpointNames).toContain('foods.search.v3');
      expect(endpointNames).toContain('food.get.v5');
    }, 60000); // 60 second timeout for network operation
  });
});
