/**
 * FatSecret Recipes API Documentation Scraper
 *
 * Scrapes documentation for recipes endpoints:
 * - recipes.search.v3
 * - recipe.get.v2
 * - recipe.types.get
 */

import { BaseScraper } from './base.js';
import { ScraperConfig } from '../types.js';
import { saveToFile } from '../utils/file.js';
import { join } from 'path';

/**
 * Endpoint metadata for recipes API
 */
interface EndpointInfo {
  name: string;
  method: string;
  path: string;
  description: string;
}

/**
 * FatSecret Recipes API scraper
 */
export class RecipesScraper extends BaseScraper {
  private readonly endpoints: EndpointInfo[] = [
    {
      name: 'recipes.search.v3',
      method: 'GET',
      path: '/recipes/search/v3',
      description: 'Search for recipes',
    },
    {
      name: 'recipe.get.v2',
      method: 'GET',
      path: '/recipe/v2',
      description: 'Get recipe details by ID',
    },
    {
      name: 'recipe.types.get',
      method: 'GET',
      path: '/recipe_types',
      description: 'List recipe types and categories',
    },
  ];

  constructor(config?: Partial<ScraperConfig>) {
    const defaultConfig: ScraperConfig = {
      baseUrl: 'https://platform.fatsecret.com/docs/guides',
      outputPath: 'output/markdown/recipes',
      selectors: {
        content: '.documentation-content',
        navigation: '.sidebar-nav',
      },
      waitForSelector: '.documentation-content',
      timeout: 60000,
    };

    super({ ...defaultConfig, ...config });
  }

  /**
   * Navigate to the Recipes section of FatSecret documentation
   */
  private async navigateToCategory(): Promise<void> {
    if (!this.page) {
      throw new Error('Page not initialized');
    }

    await this.navigateAndWait(this.config.baseUrl);

    // Look for Recipes link in navigation
    const recipesLink = await this.page.locator('text=Recipes').first();
    if (await recipesLink.isVisible()) {
      await recipesLink.click();
      await this.page.waitForLoadState('networkidle');
    } else {
      console.warn('Recipes navigation link not found, staying on current page');
    }
  }

  /**
   * Extract parameter information from endpoint section
   */
  private async extractParameters(): Promise<string> {
    if (!this.page) {
      throw new Error('Page not initialized');
    }

    const parameterSections = await this.page
      .locator('h3:has-text("Parameters"), h4:has-text("Parameters")')
      .all();

    if (parameterSections.length === 0) {
      return '';
    }

    let markdown = '\n### Parameters\n\n';
    markdown += '| Parameter | Type | Required | Description |\n';
    markdown += '|-----------|------|----------|-------------|\n';

    const parameterSection = parameterSections[0];
    const tableLocator = parameterSection.locator('xpath=following-sibling::table[1]');

    if ((await tableLocator.count()) > 0) {
      const rows = await tableLocator.locator('tbody tr').all();

      for (const row of rows) {
        const cells = await row.locator('td').allTextContents();
        if (cells.length >= 3) {
          markdown += `| ${cells[0].trim()} | ${cells[1].trim()} | ${cells[2].trim()} | ${cells[3]?.trim() || ''} |\n`;
        }
      }
    }

    return markdown;
  }

  /**
   * Extract JSON response example
   */
  private async extractJsonExample(sectionTitle: string): Promise<string> {
    if (!this.page) {
      throw new Error('Page not initialized');
    }

    const codeBlocks = await this.page
      .locator(`h3:has-text("${sectionTitle}"), h4:has-text("${sectionTitle}")`)
      .all();

    if (codeBlocks.length === 0) {
      return '';
    }

    const section = codeBlocks[0];
    const codeLocator = section.locator('xpath=following-sibling::pre[1]//code');

    if ((await codeLocator.count()) > 0) {
      const jsonContent = await codeLocator.first().textContent();
      return jsonContent?.trim() || '';
    }

    return '';
  }

  /**
   * Extract and format endpoint documentation
   */
  private async extractEndpointDoc(endpoint: EndpointInfo): Promise<string> {
    let markdown = `## ${endpoint.name}\n\n`;
    markdown += `**Method:** ${endpoint.method}\n\n`;
    markdown += `**URL:** \`${endpoint.path}\`\n\n`;
    markdown += `**Description:** ${endpoint.description}\n\n`;

    const parameters = await this.extractParameters();
    if (parameters) {
      markdown += parameters;
    }

    markdown += '\n### Authentication\n\n';
    markdown += 'Requires OAuth 1.0 signature with consumer key and access token.\n\n';

    const responseExample = await this.extractJsonExample('Response');
    if (responseExample) {
      markdown += '### Response Example\n\n';
      markdown += '```json\n';
      markdown += responseExample;
      markdown += '\n```\n\n';
    }

    return markdown;
  }

  /**
   * Save JSON fixture from response example
   */
  private async saveJsonFixture(endpoint: EndpointInfo, json: string): Promise<void> {
    if (!json) {
      return;
    }

    const fixturesDir = 'output/fixtures/recipes';
    const filename = `${endpoint.name.replace(/\./g, '_')}.json`;
    const filepath = join(fixturesDir, filename);

    try {
      const parsed = JSON.parse(json);
      const formatted = JSON.stringify(parsed, null, 2);
      await saveToFile(filepath, formatted);
      console.log(`Saved fixture: ${filepath}`);
    } catch (error) {
      console.error(`Failed to save fixture for ${endpoint.name}:`, error);
    }
  }

  /**
   * Scrape all recipe endpoints
   */
  async run(): Promise<void> {
    try {
      await this.init();
      await this.navigateToCategory();

      console.log('Scraping FatSecret Recipes API documentation...');

      for (const endpoint of this.endpoints) {
        console.log(`Processing endpoint: ${endpoint.name}`);

        const endpointDoc = await this.extractEndpointDoc(endpoint);

        const markdownPath = join(this.config.outputPath, `${endpoint.name}.md`);
        await saveToFile(markdownPath, endpointDoc);
        console.log(`Saved markdown: ${markdownPath}`);

        const responseExample = await this.extractJsonExample('Response');
        if (responseExample) {
          await this.saveJsonFixture(endpoint, responseExample);
        }
      }

      console.log('Recipes API documentation scraping complete.');
    } catch (error) {
      console.error('Error scraping recipes documentation:', error);
      throw error;
    } finally {
      await this.cleanup();
    }
  }
}

/**
 * Convenience function to run the recipes scraper
 */
export async function scrapeRecipesDocs(config?: Partial<ScraperConfig>): Promise<void> {
  const scraper = new RecipesScraper(config);
  await scraper.run();
}
