---
doc_id: concept/fatsecret/guides-localization
chunk_id: concept/fatsecret/guides-localization#chunk-7
heading_path: ["FatSecret Platform API - Localization", "OAuth 2.0 Scope"]
chunk_type: prose
tokens: 39
summary: "OAuth 2.0 Scope"
---

## OAuth 2.0 Scope

Include the `localization` scope when requesting your access token:

```bash
curl -X POST "https://oauth.fatsecret.com/connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "YOUR_CLIENT_ID:YOUR_CLIENT_SECRET" \
  -d "grant_type=client_credentials&scope=basic localization"
```
