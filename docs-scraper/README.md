# Documentation Scraper

Playwright-based documentation scraper that converts web documentation to clean markdown format.

## Features

- **Playwright-powered**: Handles JavaScript-heavy documentation sites
- **Markdown conversion**: Uses Turndown for HTML to Markdown conversion
- **Type-safe**: Built with TypeScript and Zod validation
- **Modular**: Easy to add new scrapers for different documentation sites
- **Tested**: Vitest test suite included

## Directory Structure

```
docs-scraper/
├── src/
│   ├── scrapers/       # Site-specific scrapers
│   ├── formatters/     # Markdown formatting utilities
│   ├── utils/          # Shared utilities
│   └── index.ts        # Entry point
├── tests/              # Test files
├── output/             # Scraped markdown output
└── playwright.config.ts
```

## Setup

```bash
npm install
npx playwright install chromium
```

## Usage

```bash
# Run scraper
npm run scrape

# Run tests
npm test

# Format code
npm run format
```

## Configuration

- `playwright.config.ts` - Playwright browser settings
- `tsconfig.json` - TypeScript compiler options
- `.prettierrc` - Code formatting rules

## Adding a New Scraper

1. Create a new file in `src/scrapers/`
2. Implement the scraper interface
3. Export from `src/index.ts`
4. Add tests in `tests/`

## Output

Scraped documentation is saved to `output/` as markdown files.
