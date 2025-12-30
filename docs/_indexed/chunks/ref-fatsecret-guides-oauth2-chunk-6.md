---
doc_id: ref/fatsecret/guides-oauth2
chunk_id: ref/fatsecret/guides-oauth2#chunk-6
heading_path: ["FatSecret Platform API - OAuth 2.0 Guide", "Request access token"]
chunk_type: prose
tokens: 23
summary: "Request access token"
---

## Request access token
curl -X POST "https://oauth.fatsecret.com/connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "YOUR_CLIENT_ID:YOUR_CLIENT_SECRET" \
  -d "grant_type=client_credentials&scope=basic"
