---
doc_id: ref/fatsecret/guides-authentication
chunk_id: ref/fatsecret/guides-authentication#chunk-2
heading_path: ["FatSecret Platform API - Authentication", "Authentication Types"]
chunk_type: prose
tokens: 162
summary: "Authentication Types"
---

## Authentication Types

### Signed Requests

Signed requests are used for general API access without user-specific data.

#### OAuth 2.0 (Recommended)

- Uses Client Credentials grant type
- Obtain an access token and include it in the Authorization header
- Simpler to implement than OAuth 1.0

See: [OAuth 2.0 Guide](./ref-fatsecret-guides-oauth2.md)

#### OAuth 1.0

- Sign each request using HMAC-SHA1
- Include OAuth parameters in the request
- More complex but widely supported

See: [OAuth 1.0 Guide](./ref-fatsecret-guides-oauth1.md)

### Signed and Delegated Requests

Delegated requests are required when accessing user-specific data (food diaries, exercise logs, weight tracking).

**OAuth 1.0 Only** - 3-legged OAuth is only available with OAuth 1.0.

This authentication type allows your application to act on behalf of a FatSecret user.

See: [3-Legged OAuth Guide](./tutorial-fatsecret-guides-oauth1-three-legged.md)
