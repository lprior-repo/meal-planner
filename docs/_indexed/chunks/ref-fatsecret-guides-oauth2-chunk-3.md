---
doc_id: ref/fatsecret/guides-oauth2
chunk_id: ref/fatsecret/guides-oauth2#chunk-3
heading_path: ["FatSecret Platform API - OAuth 2.0 Guide", "Requesting an Access Token"]
chunk_type: prose
tokens: 53
summary: "Requesting an Access Token"
---

## Requesting an Access Token

Access tokens must be requested through a server-side proxy to protect your credentials.

### Token Request

**Endpoint:** `POST https://oauth.fatsecret.com/connect/token`

**Headers:**
- `Content-Type: application/x-www-form-urlencoded`
- `Authorization: Basic {base64(client_id:client_secret)}`

**Body Parameters:**
- `grant_type=client_credentials`
- `scope={space-separated list of scopes}`
