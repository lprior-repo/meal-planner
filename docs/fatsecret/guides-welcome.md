# FatSecret Platform API - Welcome

The FatSecret Platform API provides programmatic access to FatSecret's food and nutrition database.

## Integration Methods

### URL-Based Integration

Send requests directly to specific method endpoints:

```yaml
https://platform.fatsecret.com/rest/{method}
```yaml

Example:
```yaml
https://platform.fatsecret.com/rest/foods.search.v3
```

### Method-Based Integration

Send requests to the central API endpoint with the method specified as a parameter:

```yaml
https://platform.fatsecret.com/rest/server.api
```text

Pass the method name using the `method` parameter in your request.

## Authentication

The API supports two OAuth standards:

### OAuth 2.0

- Recommended for new integrations
- Uses Bearer tokens in the Authorization header
- Simpler implementation

**Example Request (OAuth 2.0):**

```bash
curl -X POST "https://platform.fatsecret.com/rest/foods.search.v3" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"search_expression": "chicken breast", "max_results": 10}'
```text

### OAuth 1.0

- Legacy support available
- Requires request signing with HMAC-SHA1
- Supports 3-legged OAuth for user profile access

**Example Request (OAuth 1.0):**

```bash
curl "https://platform.fatsecret.com/rest/server.api?method=foods.search&search_expression=chicken&oauth_consumer_key=YOUR_KEY&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1234567890&oauth_nonce=abc123&oauth_version=1.0&oauth_signature=CALCULATED_SIGNATURE"
```

## Response Formats

The API returns responses in JSON format by default. Include the `format` parameter to specify the response format if needed.

## Getting Started

1. Register for API credentials at [FatSecret Platform](https://platform.fatsecret.com/)
2. Choose your authentication method (OAuth 2.0 recommended)
3. Obtain an access token
4. Start making API requests

## Related Guides

- [Authentication Overview](guides-authentication.md)
- [OAuth 2.0 Guide](guides-oauth2.md)
- [OAuth 1.0 Guide](guides-oauth1.md)
- [Parameters Reference](guides-parameters.md)
- [Error Codes](guides-error-codes.md)
