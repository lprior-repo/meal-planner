/**
 * FatSecret Foods API documentation scraper
 */

import { BaseScraper } from './base.js';
import { PageLink } from '../types.js';
import { saveToFile } from '../utils/file.js';
import { join } from 'path';

/**
 * Parameter information extracted from documentation
 */
export interface Parameter {
  name: string;
  type?: string;
  required: boolean;
  description: string;
}

/**
 * Scraper for FatSecret Foods API documentation endpoints
 */
export class FoodsScraper extends BaseScraper {
  private readonly targetEndpoints = [
    'foods.autocomplete.v2',
    'food.find_id_for_barcode.v2',
    'foods.search.v3',
    'food.get.v5',
  ];

  /**
   * Navigate to Foods category and extract endpoint links
   */
  async navigateToCategory(): Promise<PageLink[]> {
    if (!this.page) {
      await this.init();
    }

    if (!this.page) {
      throw new Error('Failed to initialize page');
    }

    // Navigate to the Foods API guides page
    await this.navigateAndWait(this.config.baseUrl);

    // Wait for navigation menu to load
    await this.page.waitForSelector('nav, [role="navigation"]', {
      timeout: this.config.timeout,
    });

    // Extract all endpoint links
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const links = await this.page.evaluate(() => {
      const linkElements = Array.from(
        (document as any).querySelectorAll('a[href*="foods"], a[href*="food"]')
      );
      return linkElements
        .map((el: any) => ({
          title: el.textContent?.trim() || '',
          url: el.href,
        }))
        .filter((link: any) => link.title && link.url);
    });

    // Filter to only target endpoints
    const filteredLinks: PageLink[] = links
      .filter((link) => this.targetEndpoints.some((endpoint) => link.title.includes(endpoint)))
      .map((link) => ({
        title: link.title,
        url: link.url,
        depth: 0,
      }));

    return filteredLinks;
  }

  /**
   * Extract JSON code blocks from HTML content
   */
  async extractJsonBlocks(html: string): Promise<string[]> {
    if (!this.page) {
      await this.init();
    }

    if (!this.page) {
      throw new Error('Failed to initialize page');
    }

    // Set HTML content in a temporary page context
    await this.page.setContent(`<html><body>${html}</body></html>`);

    // Extract JSON blocks
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const blocks = await this.page.evaluate(() => {
      const codeBlocks = Array.from(
        (document as any).querySelectorAll('pre code.language-json, pre code[class*="json"]')
      );

      return codeBlocks
        .map((block: any) => block.textContent?.trim() || '')
        .filter((text: string) => text.length > 0);
    });

    return blocks;
  }

  /**
   * Extract parameter information from HTML table
   */
  async extractParameters(html: string): Promise<Parameter[]> {
    if (!this.page) {
      await this.init();
    }

    if (!this.page) {
      throw new Error('Failed to initialize page');
    }

    // Set HTML content in a temporary page context
    await this.page.setContent(`<html><body>${html}</body></html>`);

    // Extract parameters from table
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const params = await this.page.evaluate(() => {
      const table = (document as any).querySelector('table');
      if (!table) {
        return [];
      }

      const headers = Array.from(table.querySelectorAll('thead th')).map(
        (th: any) => th.textContent?.trim().toLowerCase() || ''
      );

      const rows = Array.from(table.querySelectorAll('tbody tr'));

      return rows.map((row: any) => {
        const cells = Array.from(row.querySelectorAll('td'));
        const param: { name: string; type?: string; required: boolean; description: string } = {
          name: '',
          required: false,
          description: '',
        };

        cells.forEach((cell: any, index: number) => {
          const header = headers[index];
          const value = cell.textContent?.trim() || '';

          if (header.includes('name')) {
            param.name = value;
          } else if (header.includes('type')) {
            param.type = value;
          } else if (header.includes('required')) {
            param.required = value.toLowerCase() === 'yes' || value.toLowerCase() === 'true';
          } else if (header.includes('description')) {
            param.description = value;
          }
        });

        return param;
      });
    });

    return params.filter((p) => p.name.length > 0);
  }

  /**
   * Save endpoint documentation as markdown and JSON fixture
   */
  async saveOutput(endpointName: string, markdown: string, jsonExample: unknown): Promise<void> {
    const mdDir = join(this.config.outputPath, 'markdown', 'foods');
    const jsonDir = join(this.config.outputPath, 'fixtures', 'foods');

    const mdPath = join(mdDir, `${endpointName}.md`);
    const jsonPath = join(jsonDir, `${endpointName}.json`);

    // Save markdown
    await saveToFile(mdPath, markdown);

    // Save JSON fixture
    const jsonContent = JSON.stringify(jsonExample, null, 2);
    await saveToFile(jsonPath, jsonContent);
  }

  /**
   * Format endpoint documentation as markdown
   */
  private formatEndpointMarkdown(
    name: string,
    method: string,
    url: string,
    parameters: Parameter[],
    jsonExample: string,
    authRequired: boolean = true
  ): string {
    let markdown = `## ${name}\n\n`;
    markdown += `**HTTP Method:** ${method}\n`;
    markdown += `**URL:** ${url}\n\n`;

    if (authRequired) {
      markdown += `**Authentication:** OAuth 2.0 required\n\n`;
    }

    if (parameters.length > 0) {
      markdown += `### Parameters\n\n`;
      markdown += `| Name | Type | Required | Description |\n`;
      markdown += `|------|------|----------|-------------|\n`;

      parameters.forEach((param) => {
        const type = param.type || 'string';
        const required = param.required ? 'Yes' : 'No';
        markdown += `| ${param.name} | ${type} | ${required} | ${param.description} |\n`;
      });

      markdown += `\n`;
    }

    if (jsonExample) {
      markdown += `### Response Example\n\n`;
      markdown += `\`\`\`json\n${jsonExample}\n\`\`\`\n\n`;
    }

    return markdown;
  }

  /**
   * Scrape a single endpoint page
   */
  private async scrapeEndpoint(link: PageLink): Promise<void> {
    if (!this.page) {
      throw new Error('Page not initialized');
    }

    console.log(`Scraping endpoint: ${link.title}`);

    await this.navigateAndWait(link.url);

    // Wait for content to load
    await this.page.waitForTimeout(1000);

    // Extract page HTML
    const contentHtml = await this.page.content();

    // Extract JSON examples
    const jsonBlocks = await this.extractJsonBlocks(contentHtml);

    // Extract parameters
    const parameters = await this.extractParameters(contentHtml);

    // Parse JSON example
    let jsonExample: unknown = {};
    if (jsonBlocks.length > 0) {
      try {
        jsonExample = JSON.parse(jsonBlocks[0]);
      } catch (error) {
        console.warn(`Failed to parse JSON for ${link.title}:`, error);
        jsonExample = { raw: jsonBlocks[0] };
      }
    }

    // Format markdown
    const markdown = this.formatEndpointMarkdown(
      link.title,
      'GET',
      link.url,
      parameters,
      jsonBlocks[0] || '',
      true
    );

    // Save output
    await this.saveOutput(link.title, markdown, jsonExample);

    // Rate limiting
    await this.page.waitForTimeout(1000);
  }

  /**
   * Run the scraper
   */
  async run(): Promise<void> {
    try {
      await this.init();

      // Navigate to Foods category and get links
      const links = await this.navigateToCategory();

      console.log(`Found ${links.length} endpoint(s) to scrape`);

      // Scrape each endpoint
      for (const link of links) {
        await this.scrapeEndpoint(link);
      }

      console.log('Scraping complete');
    } catch (error) {
      console.error('Scraper error:', error);
      throw error;
    } finally {
      await this.cleanup();
    }
  }
}
