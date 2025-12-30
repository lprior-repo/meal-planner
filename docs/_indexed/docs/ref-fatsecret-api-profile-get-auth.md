---
id: ref/fatsecret/api-profile-get-auth
title: "Profile Get Auth"
category: ref
tags: ["fatsecret", "profile", "reference"]
---

# Profile Get Auth

> **Context**: Retrieve authentication credentials for an existing user profile.

Retrieve authentication credentials for an existing user profile.

> **OAuth 1.0 Only** - This endpoint requires OAuth 1.0 authentication.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/profile/auth/v1`
- **HTTP Method:** GET
- **API Method:** `profile.get_auth`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `user_id` | string | No | Your own ID for the user |
| `format` | string | No | Response format: `json` or `xml` (default: `xml`) |

## Response

| Field | Description |
|-------|-------------|
| `auth_token` | OAuth token for the profile |
| `auth_secret` | OAuth secret for the profile |

## Example Response (JSON)

```json
{
  "profile": {
    "auth_token": "abc123...",
    "auth_secret": "xyz789..."
  }
}
```

## Usage Notes

- Use this endpoint to retrieve credentials for an existing profile
- Useful when you need to recover or verify stored credentials
- The credentials returned are the same as those from `profile.create`


## See Also

- [Documentation Index](./COMPASS.md)
