/**
 * Base scraper class with common functionality
 */

import { Browser, Page, chromium } from 'playwright';
import { ScraperConfig, ScraperResult } from '../types.js';
import { htmlToMarkdown, cleanMarkdown } from '../utils/markdown.js';
import { saveToFile, createOutputPath } from '../utils/file.js';

/**
 * Abstract base class for documentation scrapers
 */
export abstract class BaseScraper {
  protected browser: Browser | null = null;
  protected page: Page | null = null;

  constructor(protected config: ScraperConfig) {}

  /**
   * Initialize browser and page
   */
  protected async init(): Promise<void> {
    this.browser = await chromium.launch({
      headless: true,
    });
    this.page = await this.browser.newPage();
  }

  /**
   * Clean up browser resources
   */
  protected async cleanup(): Promise<void> {
    if (this.page) {
      await this.page.close();
      this.page = null;
    }
    if (this.browser) {
      await this.browser.close();
      this.browser = null;
    }
  }

  /**
   * Navigate to a URL and wait for content
   */
  protected async navigateAndWait(url: string): Promise<void> {
    if (!this.page) {
      throw new Error('Page not initialized. Call init() first.');
    }

    await this.page.goto(url, {
      waitUntil: 'networkidle',
      timeout: this.config.timeout,
    });

    if (this.config.waitForSelector) {
      await this.page.waitForSelector(this.config.waitForSelector, {
        timeout: this.config.timeout,
      });
    }
  }

  /**
   * Extract content from current page
   */
  protected async extractContent(): Promise<ScraperResult> {
    if (!this.page) {
      throw new Error('Page not initialized.');
    }

    const url = this.page.url();
    const title = await this.page.title();

    // Get main content selector or fallback to body
    const contentSelector = this.config.selectors?.content || 'body';
    const htmlContent = await this.page.$eval(contentSelector, (el) => el.innerHTML);

    const markdown = cleanMarkdown(htmlToMarkdown(htmlContent));

    return {
      title,
      url,
      content: markdown,
      metadata: {
        scrapedAt: new Date(),
        wordCount: markdown.split(/\s+/).length,
      },
    };
  }

  /**
   * Save scraper result to file
   */
  protected async saveResult(result: ScraperResult): Promise<string> {
    const filepath = createOutputPath(this.config.outputPath, result.title);
    await saveToFile(filepath, result.content);
    return filepath;
  }

  /**
   * Run the scraper (to be implemented by subclasses)
   */
  abstract run(): Promise<void>;
}
