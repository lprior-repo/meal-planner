# FoodsScraper

Scrapes FatSecret Foods API documentation from the official platform documentation.

## Target Endpoints

The scraper extracts documentation for the following endpoints:

1. `foods.autocomplete.v2` - Autocomplete suggestions for food searches
2. `food.find_id_for_barcode.v2` - Lookup food by barcode
3. `foods.search.v3` - Search for foods
4. `food.get.v5` - Get detailed food information by ID

## Features

- **Automatic navigation** - Navigates to Foods section on FatSecret docs
- **JSON extraction** - Finds and parses JSON response examples
- **Parameter parsing** - Extracts parameter tables with types, requirements, descriptions
- **Dual output** - Saves both markdown documentation and JSON fixtures
- **Rate limiting** - 1-second delays between requests to be respectful
- **Error handling** - Gracefully handles missing fields and malformed JSON

## Output Structure

```
output/
├── markdown/
│   └── foods/
│       ├── foods.autocomplete.v2.md
│       ├── food.find_id_for_barcode.v2.md
│       ├── foods.search.v3.md
│       └── food.get.v5.md
└── fixtures/
    └── foods/
        ├── foods.autocomplete.v2.json
        ├── food.find_id_for_barcode.v2.json
        ├── foods.search.v3.json
        └── food.get.v5.json
```

## Markdown Format

Each markdown file includes:

- Endpoint name as H2 header
- HTTP method (GET/POST)
- Full URL
- Authentication requirements (OAuth 2.0)
- Parameter table with columns: Name, Type, Required, Description
- JSON response example in code block

Example:

```markdown
## foods.search.v3

**HTTP Method:** GET
**URL:** https://platform.fatsecret.com/rest/foods/search/v3
**Authentication:** OAuth 2.0 required

### Parameters

| Name   | Type   | Required | Description               |
| ------ | ------ | -------- | ------------------------- |
| query  | string | Yes      | Search query text         |
| limit  | number | No       | Maximum results to return |
| offset | number | No       | Pagination offset         |

### Response Example

\`\`\`json
{
"foods": [
{
"food_id": "12345",
"food_name": "Apple",
"food_type": "Generic"
}
]
}
\`\`\`
```

## Usage

### Basic Usage

```typescript
import { FoodsScraper } from './scrapers/foods.js';
import { ScraperConfig } from './types.js';

const config: ScraperConfig = {
  baseUrl: 'https://platform.fatsecret.com/docs/guides',
  outputPath: './output',
  timeout: 30000,
};

const scraper = new FoodsScraper(config);
await scraper.run();
```

### Using Individual Methods

```typescript
const scraper = new FoodsScraper(config);

// Extract JSON from HTML content
const html = '<pre><code class="language-json">{"test": true}</code></pre>';
const jsonBlocks = await scraper.extractJsonBlocks(html);
// Returns: ['{"test": true}']

// Extract parameters from table HTML
const tableHtml = `
  <table>
    <thead><tr><th>Name</th><th>Type</th><th>Required</th></tr></thead>
    <tbody><tr><td>food_id</td><td>string</td><td>Yes</td></tr></tbody>
  </table>
`;
const params = await scraper.extractParameters(tableHtml);
// Returns: [{ name: 'food_id', type: 'string', required: true, description: '' }]

// Save documentation and fixture
await scraper.saveOutput('foods.search.v3', '# Foods Search\n\nSearch for foods...', { foods: [] });
```

## Testing

Run the test suite:

```bash
npm test -- foods-scraper.test.ts
```

Tests include:

- ✓ JSON block extraction (single and multiple)
- ✓ Parameter table parsing (with missing columns)
- ✓ Output file saving (markdown + JSON)
- ✓ Directory creation
- ⊘ Integration test (skipped by default, requires network)

## Architecture

The scraper extends `BaseScraper` which provides:

- Browser initialization (Playwright/Chromium)
- Page navigation and waiting
- Content extraction
- Resource cleanup

### Methods

#### `navigateToCategory(): Promise<PageLink[]>`

Navigates to the Foods section and extracts endpoint links.

**Returns:** Array of page links with title and URL

#### `extractJsonBlocks(html: string): Promise<string[]>`

Extracts JSON code blocks from HTML content.

**Parameters:**

- `html` - HTML string to parse

**Returns:** Array of JSON strings

#### `extractParameters(html: string): Promise<Parameter[]>`

Parses parameter table from HTML.

**Parameters:**

- `html` - HTML string containing a table

**Returns:** Array of parameter objects

#### `saveOutput(endpointName: string, markdown: string, jsonExample: unknown): Promise<void>`

Saves markdown documentation and JSON fixture.

**Parameters:**

- `endpointName` - Name of the endpoint (used as filename)
- `markdown` - Formatted markdown content
- `jsonExample` - Parsed JSON object

#### `run(): Promise<void>`

Runs the complete scraping workflow.

**Workflow:**

1. Initialize browser
2. Navigate to Foods category
3. Extract endpoint links
4. For each endpoint:
   - Navigate to endpoint page
   - Extract JSON examples
   - Extract parameters
   - Format markdown
   - Save output files
   - Wait 1 second (rate limiting)
5. Cleanup browser

## Error Handling

The scraper handles:

- Missing JSON blocks (returns empty array)
- Malformed JSON (wraps in `{ raw: "..." }`)
- Missing parameter tables (returns empty array)
- Network timeouts (configured via `config.timeout`)
- Missing page initialization (throws descriptive error)

## Rate Limiting

To be respectful to the FatSecret servers, the scraper:

- Waits 1 second between page navigations
- Uses a single browser instance for all requests
- Reuses page context where possible

## Dependencies

- `playwright` - Browser automation
- `path` - File path utilities
- `fs/promises` - Async file operations
- Custom utilities from `../utils/file.js`

## Notes

- The integration test (`navigateToCategory`) is skipped by default because it requires network access and may fail if FatSecret changes their documentation structure
- Run manually with `npm test -- --run foods-scraper.test.ts` and unskip the test to verify navigation logic
- All methods that use `page.evaluate()` run code in the browser context, so DOM APIs are available
