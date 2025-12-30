---
id: ref/fatsecret/guides-authentication
title: "FatSecret Platform API - Authentication"
category: ref
tags: ["api", "fatsecret", "reference"]
---

# FatSecret Platform API - Authentication

> **Context**: The FatSecret Platform API supports multiple authentication methods depending on your use case.

The FatSecret Platform API supports multiple authentication methods depending on your use case.

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

## Profile Management

To work with user profiles, use these API methods:

### profile.create

Creates a new user profile linked to your application.

**Parameters:**
- `user_id` (optional) - Your application's identifier for the user

**Returns:**
- `auth_token` - OAuth token for the user
- `auth_secret` - OAuth token secret for the user

### profile.get_auth

Retrieves authentication credentials for an existing user profile.

**Parameters:**
- `user_id` - Your application's identifier for the user

**Returns:**
- `auth_token` - OAuth token for the user
- `auth_secret` - OAuth token secret for the user

## Choosing an Authentication Method

| Use Case | Recommended Method |
|----------|-------------------|
| Food search, nutrition data | OAuth 2.0 |
| Barcode lookups | OAuth 2.0 |
| Recipe search | OAuth 2.0 |
| User food diaries | OAuth 1.0 (3-legged) |
| User weight tracking | OAuth 1.0 (3-legged) |
| User exercise logs | OAuth 1.0 (3-legged) |

## Security Best Practices

1. Never expose your Consumer Secret in client-side code
2. Store access tokens securely
3. Use HTTPS for all API communications
4. Implement token refresh logic for OAuth 2.0
5. Validate all OAuth signatures on the server side


## See Also

- [OAuth 2.0 Guide](guides-oauth2.md)
- [OAuth 1.0 Guide](guides-oauth1.md)
- [3-Legged OAuth Guide](guides-oauth1-three-legged.md)
