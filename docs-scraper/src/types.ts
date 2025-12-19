/**
 * Common types and interfaces for documentation scrapers
 */

import { z } from 'zod';

/**
 * Configuration for a documentation scraper
 */
export const ScraperConfigSchema = z.object({
  baseUrl: z.string().url(),
  outputPath: z.string(),
  selectors: z
    .object({
      content: z.string().optional(),
      navigation: z.string().optional(),
      title: z.string().optional(),
    })
    .optional(),
  waitForSelector: z.string().optional(),
  timeout: z.number().optional().default(60000),
});

export type ScraperConfig = z.infer<typeof ScraperConfigSchema>;

/**
 * Result from a scraping operation
 */
export const ScraperResultSchema = z.object({
  title: z.string(),
  url: z.string().url(),
  content: z.string(),
  metadata: z
    .object({
      scrapedAt: z.date(),
      wordCount: z.number(),
      links: z.array(z.string()).optional(),
    })
    .optional(),
});

export type ScraperResult = z.infer<typeof ScraperResultSchema>;

/**
 * Page navigation item
 */
export const PageLinkSchema = z.object({
  title: z.string(),
  url: z.string().url(),
  depth: z.number().optional().default(0),
});

export type PageLink = z.infer<typeof PageLinkSchema>;
