---
doc_id: ref/fatsecret/guides-authentication
chunk_id: ref/fatsecret/guides-authentication#chunk-3
heading_path: ["FatSecret Platform API - Authentication", "Profile Management"]
chunk_type: prose
tokens: 117
summary: "Profile Management"
---

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
