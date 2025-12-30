---
doc_id: tutorial/fatsecret/guides-welcome
chunk_id: tutorial/fatsecret/guides-welcome#chunk-3
heading_path: ["FatSecret Platform API - Welcome", "Authentication"]
chunk_type: code
tokens: 106
summary: "Authentication"
---

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
