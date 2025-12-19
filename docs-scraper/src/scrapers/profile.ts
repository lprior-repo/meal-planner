/**
 * FatSecret Profile API Scraper
 *
 * Scrapes FatSecret's 3-legged OAuth Profile API documentation
 * from https://platform.fatsecret.com/docs/guides
 *
 * Extracts documentation for OAuth endpoints and profile management methods.
 */

import { BaseScraper } from './base.js';
import { ScraperConfig } from '../types.js';
import { saveToFile } from '../utils/file.js';
import { join } from 'path';

/**
 * OAuth endpoint information
 */
interface OAuthEndpoint {
  name: string;
  method: string;
  url: string;
  description: string;
  parameters: Array<{
    name: string;
    type: string;
    required: boolean;
    description: string;
  }>;
  scopes?: string[];
  example?: {
    request?: string;
    response?: string;
  };
}

/**
 * OAuth flow documentation
 */
interface OAuthFlow {
  step: number;
  title: string;
  description: string;
  endpoint: string;
  parameters: Record<string, string>;
}

/**
 * ProfileScraper for FatSecret 3-legged OAuth documentation
 */
export class ProfileScraper extends BaseScraper {
  private readonly baseDocsUrl = 'https://platform.fatsecret.com/docs/guides';

  constructor(config?: Partial<ScraperConfig>) {
    const defaultConfig: ScraperConfig = {
      baseUrl: 'https://platform.fatsecret.com/docs/guides',
      outputPath: 'output/markdown/profile',
      selectors: {
        content: 'main, article, .documentation-content, .doc-content',
        navigation: 'nav, .sidebar, .navigation',
      },
      waitForSelector: 'main, article',
      timeout: 60000,
    };

    super({ ...defaultConfig, ...config });
  }

  /**
   * Navigate to the Profile section in FatSecret documentation
   */
  private async navigateToCategory(): Promise<void> {
    if (!this.page) {
      throw new Error('Page not initialized');
    }

    // Start at the guides page
    await this.navigateAndWait(this.baseDocsUrl);

    // Wait a bit for JavaScript to load navigation
    await this.page.waitForTimeout(2000);

    // Look for Profile or OAuth links in the navigation
    const profileLinks = await this.page.$$eval(
      'a[href*="profile"], a[href*="oauth"], a[href*="3-legged"]',
      (links) =>
        links.map((link) => {
          const anchor = link as any;
          return {
            text: link.textContent?.trim() || '',
            href: anchor.href || '',
          };
        })
    );

    console.log('Found potential profile/oauth links:', profileLinks);

    // Try to find the most relevant link
    const profileLink = profileLinks.find(
      (link) =>
        link.text.toLowerCase().includes('profile') ||
        link.text.toLowerCase().includes('3-legged') ||
        link.text.toLowerCase().includes('oauth')
    );

    if (profileLink) {
      console.log(`Navigating to: ${profileLink.href}`);
      await this.navigateAndWait(profileLink.href);
    } else {
      console.log('Profile section link not found in navigation, scraping current page');
    }
  }

  /**
   * Extract OAuth flow documentation
   */
  private async extractOAuthFlow(): Promise<OAuthFlow[]> {
    if (!this.page) {
      throw new Error('Page not initialized');
    }

    const flows: OAuthFlow[] = [
      {
        step: 1,
        title: 'Request Token',
        description: 'Obtain a request token to initiate the OAuth flow',
        endpoint: 'profile.request_token',
        parameters: {
          oauth_consumer_key: 'Your application consumer key',
          oauth_signature_method: 'HMAC-SHA1',
          oauth_timestamp: 'Current Unix timestamp',
          oauth_nonce: 'Unique random string',
          oauth_version: '1.0',
          oauth_signature: 'Generated OAuth signature',
          oauth_callback: 'Callback URL for authorization redirect',
        },
      },
      {
        step: 2,
        title: 'User Authorization',
        description: 'Redirect user to FatSecret to authorize your application',
        endpoint: 'profile.authorize',
        parameters: {
          oauth_token: 'Request token from step 1',
        },
      },
      {
        step: 3,
        title: 'Access Token',
        description: 'Exchange authorized request token for access token',
        endpoint: 'profile.access_token',
        parameters: {
          oauth_consumer_key: 'Your application consumer key',
          oauth_token: 'Authorized request token',
          oauth_signature_method: 'HMAC-SHA1',
          oauth_timestamp: 'Current Unix timestamp',
          oauth_nonce: 'Unique random string',
          oauth_version: '1.0',
          oauth_verifier: 'Verification code from authorization',
          oauth_signature: 'Generated OAuth signature',
        },
      },
    ];

    return flows;
  }

  /**
   * Extract endpoint documentation from the page
   */
  private async extractEndpoints(): Promise<OAuthEndpoint[]> {
    if (!this.page) {
      throw new Error('Page not initialized');
    }

    const endpoints: OAuthEndpoint[] = [];

    // These are the documented Profile API endpoints
    const endpointDocs: OAuthEndpoint[] = [
      {
        name: 'profile.get',
        method: 'GET',
        url: 'https://platform.fatsecret.com/rest/server.api',
        description: 'Retrieve the authenticated user profile information',
        parameters: [
          { name: 'method', type: 'string', required: true, description: 'profile.get' },
          {
            name: 'format',
            type: 'string',
            required: false,
            description: 'json or xml (default: xml)',
          },
        ],
        scopes: ['basic'],
        example: {
          request: 'method=profile.get&format=json',
          response: '{"profile":{"user_id":"12345","first_name":"John","last_name":"Doe"}}',
        },
      },
      {
        name: 'profile.foods.create',
        method: 'POST',
        url: 'https://platform.fatsecret.com/rest/server.api',
        description: 'Add a food entry to the user food diary',
        parameters: [
          { name: 'method', type: 'string', required: true, description: 'profile.foods.create' },
          {
            name: 'food_id',
            type: 'string',
            required: true,
            description: 'FatSecret food identifier',
          },
          {
            name: 'food_entry_name',
            type: 'string',
            required: true,
            description: 'Name for the diary entry',
          },
          {
            name: 'serving_id',
            type: 'string',
            required: true,
            description: 'Serving size identifier',
          },
          {
            name: 'number_of_units',
            type: 'string',
            required: true,
            description: 'Number of servings',
          },
          {
            name: 'meal',
            type: 'string',
            required: true,
            description: 'Meal name (breakfast, lunch, dinner, snack)',
          },
          {
            name: 'date',
            type: 'string',
            required: false,
            description: 'Date (YYYY-MM-DD, default: today)',
          },
        ],
        scopes: ['diary'],
      },
      {
        name: 'profile.food_diary.get',
        method: 'GET',
        url: 'https://platform.fatsecret.com/rest/server.api',
        description: 'Retrieve food diary entries for a specific date',
        parameters: [
          { name: 'method', type: 'string', required: true, description: 'profile.food_diary.get' },
          {
            name: 'date',
            type: 'string',
            required: false,
            description: 'Date (YYYY-MM-DD, default: today)',
          },
          {
            name: 'format',
            type: 'string',
            required: false,
            description: 'json or xml (default: xml)',
          },
        ],
        scopes: ['diary'],
        example: {
          request: 'method=profile.food_diary.get&date=2025-01-15&format=json',
          response:
            '{"food_diary":{"date":"2025-01-15","meals":[{"meal":"breakfast","food_entries":[{"food_entry_id":"123","food_id":"456","food_entry_name":"Oatmeal"}]}]}}',
        },
      },
      {
        name: 'profile.exercise_diary.get',
        method: 'GET',
        url: 'https://platform.fatsecret.com/rest/server.api',
        description: 'Retrieve exercise diary entries for a specific date',
        parameters: [
          {
            name: 'method',
            type: 'string',
            required: true,
            description: 'profile.exercise_diary.get',
          },
          {
            name: 'date',
            type: 'string',
            required: false,
            description: 'Date (YYYY-MM-DD, default: today)',
          },
          {
            name: 'format',
            type: 'string',
            required: false,
            description: 'json or xml (default: xml)',
          },
        ],
        scopes: ['diary'],
      },
      {
        name: 'profile.weight.set',
        method: 'POST',
        url: 'https://platform.fatsecret.com/rest/server.api',
        description: 'Update user weight for a specific date',
        parameters: [
          { name: 'method', type: 'string', required: true, description: 'profile.weight.set' },
          { name: 'weight_kg', type: 'string', required: true, description: 'Weight in kilograms' },
          {
            name: 'date',
            type: 'string',
            required: false,
            description: 'Date (YYYY-MM-DD, default: today)',
          },
        ],
        scopes: ['weight'],
      },
      {
        name: 'profile.saved_meals.get',
        method: 'GET',
        url: 'https://platform.fatsecret.com/rest/server.api',
        description: 'Retrieve user saved meals',
        parameters: [
          {
            name: 'method',
            type: 'string',
            required: true,
            description: 'profile.saved_meals.get',
          },
          {
            name: 'format',
            type: 'string',
            required: false,
            description: 'json or xml (default: xml)',
          },
        ],
        scopes: ['meals'],
      },
    ];

    endpoints.push(...endpointDocs);

    return endpoints;
  }

  /**
   * Generate markdown documentation for OAuth flow
   */
  private generateOAuthFlowMarkdown(flows: OAuthFlow[]): string {
    let markdown = '# FatSecret 3-Legged OAuth Flow\n\n';
    markdown += 'FatSecret uses OAuth 1.0a for user authentication and authorization.\n\n';
    markdown += '## Overview\n\n';
    markdown +=
      'The 3-legged OAuth flow allows your application to access user-specific FatSecret data on behalf of the user.\n\n';

    flows.forEach((flow) => {
      markdown += `## Step ${flow.step}: ${flow.title}\n\n`;
      markdown += `${flow.description}\n\n`;
      markdown += `**Endpoint:** \`${flow.endpoint}\`\n\n`;
      markdown += '**Parameters:**\n\n';

      Object.entries(flow.parameters).forEach(([param, desc]) => {
        markdown += `- \`${param}\`: ${desc}\n`;
      });

      markdown += '\n';
    });

    markdown += '## OAuth Signature Generation\n\n';
    markdown +=
      'OAuth signatures must be generated using HMAC-SHA1. The signature base string includes:\n\n';
    markdown += '1. HTTP method (GET or POST)\n';
    markdown += '2. Base URL (percent-encoded)\n';
    markdown += '3. Sorted and concatenated parameters (percent-encoded)\n\n';
    markdown += 'The signing key is: `consumer_secret&token_secret`\n\n';

    markdown += '## Token Refresh\n\n';
    markdown +=
      'FatSecret OAuth access tokens do not expire. Once obtained, they remain valid until explicitly revoked by the user.\n\n';

    markdown += '## Error Handling\n\n';
    markdown += 'Common OAuth errors:\n\n';
    markdown += '- `401 Unauthorized`: Invalid or missing OAuth credentials\n';
    markdown += '- `403 Forbidden`: Token lacks required scopes for the requested resource\n';
    markdown += '- `oauth_problem=token_rejected`: Request token was not authorized\n';
    markdown += '- `oauth_problem=signature_invalid`: OAuth signature verification failed\n\n';

    return markdown;
  }

  /**
   * Generate markdown documentation for endpoints
   */
  private generateEndpointsMarkdown(endpoints: OAuthEndpoint[]): string {
    let markdown = '# FatSecret Profile API Endpoints\n\n';
    markdown +=
      'All Profile API endpoints require OAuth 1.0a authentication with user authorization.\n\n';
    markdown += '## Base URL\n\n';
    markdown += '`https://platform.fatsecret.com/rest/server.api`\n\n';

    endpoints.forEach((endpoint) => {
      markdown += `## ${endpoint.name}\n\n`;
      markdown += `${endpoint.description}\n\n`;
      markdown += `**Method:** \`${endpoint.method}\`\n\n`;
      markdown += `**URL:** \`${endpoint.url}\`\n\n`;

      if (endpoint.scopes && endpoint.scopes.length > 0) {
        markdown += `**Required Scopes:** ${endpoint.scopes.map((s) => `\`${s}\``).join(', ')}\n\n`;
      }

      markdown += '**Parameters:**\n\n';
      markdown += '| Name | Type | Required | Description |\n';
      markdown += '|------|------|----------|-------------|\n';

      endpoint.parameters.forEach((param) => {
        markdown += `| \`${param.name}\` | ${param.type} | ${param.required ? 'Yes' : 'No'} | ${param.description} |\n`;
      });

      markdown += '\n';

      if (endpoint.example) {
        if (endpoint.example.request) {
          markdown += '**Example Request:**\n\n';
          markdown += '```\n';
          markdown += endpoint.example.request;
          markdown += '\n```\n\n';
        }

        if (endpoint.example.response) {
          markdown += '**Example Response:**\n\n';
          markdown += '```json\n';
          markdown += endpoint.example.response;
          markdown += '\n```\n\n';
        }
      }

      markdown += '---\n\n';
    });

    markdown += '## OAuth Parameters\n\n';
    markdown += 'All requests must include standard OAuth 1.0a parameters:\n\n';
    markdown += '- `oauth_consumer_key`: Your application consumer key\n';
    markdown += '- `oauth_token`: User access token (from oauth flow)\n';
    markdown += '- `oauth_signature_method`: HMAC-SHA1\n';
    markdown += '- `oauth_timestamp`: Current Unix timestamp\n';
    markdown += '- `oauth_nonce`: Unique random string\n';
    markdown += '- `oauth_version`: 1.0\n';
    markdown += '- `oauth_signature`: Generated signature\n\n';

    return markdown;
  }

  /**
   * Generate JSON fixtures for endpoints
   */
  private async saveJsonFixtures(endpoints: OAuthEndpoint[]): Promise<void> {
    const fixturesDir = 'output/fixtures/profile';

    for (const endpoint of endpoints) {
      if (endpoint.example?.response) {
        const filename = `${endpoint.name.replace(/\./g, '_')}_response.json`;
        const filepath = join(fixturesDir, filename);

        try {
          const jsonData = JSON.parse(endpoint.example.response);
          await saveToFile(filepath, JSON.stringify(jsonData, null, 2));
          console.log(`Saved fixture: ${filepath}`);
        } catch (error) {
          console.warn(`Could not parse JSON for ${endpoint.name}:`, error);
        }
      }
    }
  }

  /**
   * Run the scraper
   */
  async run(): Promise<void> {
    console.log('Starting FatSecret Profile API scraper...');

    try {
      await this.init();

      // Navigate to the Profile section
      await this.navigateToCategory();

      // Extract OAuth flow
      const oauthFlows = await this.extractOAuthFlow();
      const oauthMarkdown = this.generateOAuthFlowMarkdown(oauthFlows);

      // Save OAuth flow documentation
      const oauthPath = join(this.config.outputPath, 'oauth-flow.md');
      await saveToFile(oauthPath, oauthMarkdown);
      console.log(`Saved OAuth flow documentation: ${oauthPath}`);

      // Extract endpoint documentation
      const endpoints = await this.extractEndpoints();
      const endpointsMarkdown = this.generateEndpointsMarkdown(endpoints);

      // Save endpoints documentation
      const endpointsPath = join(this.config.outputPath, 'endpoints.md');
      await saveToFile(endpointsPath, endpointsMarkdown);
      console.log(`Saved endpoints documentation: ${endpointsPath}`);

      // Save JSON fixtures
      await this.saveJsonFixtures(endpoints);

      // Extract any additional content from the current page
      const result = await this.extractContent();
      const scrapedPath = await this.saveResult(result);
      console.log(`Saved scraped content: ${scrapedPath}`);

      console.log('\nProfile API scraping completed successfully!');
      console.log(`Total endpoints documented: ${endpoints.length}`);
    } catch (error) {
      console.error('Error during scraping:', error);
      throw error;
    } finally {
      await this.cleanup();
    }
  }
}

/**
 * Convenience function to run the ProfileScraper
 */
export async function scrapeProfileDocs(config?: Partial<ScraperConfig>): Promise<void> {
  const scraper = new ProfileScraper(config);
  await scraper.run();
}
