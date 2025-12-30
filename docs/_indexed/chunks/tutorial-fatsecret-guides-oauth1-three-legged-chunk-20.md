---
doc_id: tutorial/fatsecret/guides-oauth1-three-legged
chunk_id: tutorial/fatsecret/guides-oauth1-three-legged#chunk-20
heading_path: ["FatSecret Platform API - 3-Legged OAuth", "Security Considerations"]
chunk_type: prose
tokens: 45
summary: "Security Considerations"
---

## Security Considerations

1. Store access tokens securely (encrypted at rest)
2. Use HTTPS for all OAuth communications
3. Validate the `oauth_token` in callbacks matches what you sent
4. Implement CSRF protection for callback endpoints
