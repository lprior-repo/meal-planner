---
doc_id: ref/fatsecret/guides-oauth2
chunk_id: ref/fatsecret/guides-oauth2#chunk-9
heading_path: ["FatSecret Platform API - OAuth 2.0 Guide", "Best Practices"]
chunk_type: prose
tokens: 71
summary: "Best Practices"
---

## Best Practices

1. **Cache tokens** - Reuse tokens until they expire (24 hours)
2. **Server-side only** - Never expose credentials in client-side code
3. **Request minimal scopes** - Only request scopes you need
4. **Handle expiration** - Implement automatic token refresh before expiry
5. **Secure storage** - Store tokens securely, never in plain text
