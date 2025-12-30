---
doc_id: ops/fatsecret/guides-error-codes
chunk_id: ops/fatsecret/guides-error-codes#chunk-9
heading_path: ["FatSecret Platform API - Error Codes", "Rate Limiting"]
chunk_type: prose
tokens: 50
summary: "Rate Limiting"
---

## Rate Limiting

- Rate limits vary by subscription plan
- When rate limited, wait for the duration specified in the `Retry-After` header
- Implement exponential backoff for repeated failures
- Cache responses where appropriate to reduce API calls
