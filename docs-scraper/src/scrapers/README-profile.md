# ProfileScraper - FatSecret 3-Legged OAuth API

## Overview

The ProfileScraper extracts documentation for FatSecret's Profile API, which uses 3-legged OAuth 1.0a for user authentication and authorization.

## Target Endpoints

### OAuth Flow Endpoints
- `profile.request_token` - Obtain request token
- `profile.authorize` - User authorization
- `profile.access_token` - Exchange for access token

### Profile Management Endpoints
- `profile.get` - Get user profile information
- `profile.foods.create` - Add food to diary
- `profile.food_diary.get` - Get food diary entries
- `profile.exercise_diary.get` - Get exercise entries
- `profile.weight.set` - Update weight
- `profile.saved_meals.get` - Get saved meals

## Usage

### From npm scripts
```bash
cd docs-scraper
npm run scrape:profile
```

### From code
```typescript
import { scrapeProfileDocs } from './scrapers/profile.js';

await scrapeProfileDocs();
```

### With custom configuration
```typescript
import { ProfileScraper } from './scrapers/profile.js';

const scraper = new ProfileScraper({
  outputPath: 'custom/output/path',
  timeout: 120000,
});

await scraper.run();
```

## Output Structure

### Markdown Documentation

**`output/markdown/profile/oauth-flow.md`**
- Complete OAuth 1.0a flow documentation
- Step-by-step authorization process
- Signature generation guidelines
- Token refresh mechanics
- Error handling

**`output/markdown/profile/endpoints.md`**
- Detailed endpoint documentation
- HTTP methods and URLs
- Parameter specifications
- Required OAuth scopes
- Request/response examples

**`output/markdown/profile/[scraped-page-title].md`**
- Raw scraped content from FatSecret docs

### JSON Fixtures

**`output/fixtures/profile/[endpoint_name]_response.json`**
- Example JSON responses for each endpoint
- Used for testing and development

## OAuth Flow Documentation

The scraper documents the complete 3-legged OAuth flow:

1. **Request Token** - Application requests temporary credentials
2. **User Authorization** - User authorizes application access
3. **Access Token** - Exchange authorized token for permanent credentials

## Key Features

- Comprehensive OAuth 1.0a flow documentation
- Signature generation examples
- Scope requirements for each endpoint
- Token lifecycle management
- Error handling patterns
- JSON response fixtures for testing

## Implementation Notes

### OAuth Signature Generation
The scraper documents OAuth signature requirements:
- HMAC-SHA1 signature method
- Parameter ordering and encoding
- Base string construction
- Signing key format: `consumer_secret&token_secret`

### Scopes
Different endpoints require different OAuth scopes:
- `basic` - Profile information
- `diary` - Food and exercise diary access
- `weight` - Weight management
- `meals` - Saved meals access

### Token Expiration
FatSecret OAuth access tokens do not expire. Once obtained, they remain valid until the user explicitly revokes access.

## Testing

The scraper generates JSON fixtures that can be used for:
- Integration testing
- Mock API responses
- Type validation
- Development without live API access

## Error Handling

The scraper documents common OAuth errors:
- `401 Unauthorized` - Invalid credentials
- `403 Forbidden` - Insufficient scopes
- `oauth_problem=token_rejected` - Authorization failed
- `oauth_problem=signature_invalid` - Signature verification failed
