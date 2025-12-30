---
doc_id: ref/fatsecret/guides-oauth1
chunk_id: ref/fatsecret/guides-oauth1#chunk-9
heading_path: ["FatSecret Platform API - OAuth 1.0 Guide", "Common Issues"]
chunk_type: prose
tokens: 53
summary: "Common Issues"
---

## Common Issues

1. **Signature mismatch** - Double-check URL encoding and parameter sorting
2. **Timestamp expired** - Ensure system clock is synchronized
3. **Nonce reuse** - Generate a new nonce for each request
4. **Encoding issues** - Use RFC 3986 percent-encoding
