---
id: ref/fatsecret/api-profile-create
title: "Profile Create"
category: ref
tags: ["fatsecret", "reference", "profile"]
---

# Profile Create

> **Context**: Create a profile for a user within your application.

Create a profile for a user within your application.

> **OAuth 1.0 Only** - This endpoint requires OAuth 1.0 authentication.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/profile/v1`
- **HTTP Method:** POST
- **API Method:** `profile.create`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `user_id` | string | Yes | Your own ID for the user (application-specific identifier) |
| `format` | string | No | Response format: `json` or `xml` (default: `xml`) |

## Response

| Field | Description |
|-------|-------------|
| `auth_token` | OAuth token for the created profile |
| `auth_secret` | OAuth secret for the created profile |

> **Security Note:** Store `auth_token` and `auth_secret` securely. These credentials allow API calls on behalf of the user.

## Example Response (JSON)

```json
{
  "profile": {
    "auth_token": "abc123...",
    "auth_secret": "xyz789..."
  }
}
```

## 3-Legged OAuth

You can also use 3-legged OAuth to link profiles to existing fatsecret.com accounts. This allows users to:

- Access their existing FatSecret data
- Sync data between your app and fatsecret.com
- Use a single account across multiple platforms

## Usage Notes

- Each `user_id` should be unique within your application
- The returned credentials are permanent unless revoked
- Use these credentials for subsequent OAuth 1.0 signed requests on behalf of the user


## See Also

- [Documentation Index](./COMPASS.md)
