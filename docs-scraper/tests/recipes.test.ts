/**
 * Tests for RecipesScraper
 */

import { describe, it, expect, beforeAll } from 'vitest';
import { RecipesScraper } from '../src/scrapers/recipes.js';

describe('RecipesScraper', () => {
  let scraper: RecipesScraper;

  beforeAll(() => {
    scraper = new RecipesScraper({
      baseUrl: 'https://platform.fatsecret.com/docs/guides',
      outputPath: 'output/test/recipes',
    });
  });

  it('should create a RecipesScraper instance', () => {
    expect(scraper).toBeInstanceOf(RecipesScraper);
  });

  it('should have a run method', () => {
    expect(typeof scraper.run).toBe('function');
  });

  it('should extend BaseScraper', () => {
    expect(scraper).toHaveProperty('init');
    expect(scraper).toHaveProperty('cleanup');
  });
});
