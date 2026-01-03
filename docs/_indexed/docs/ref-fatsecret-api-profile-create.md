---
id: ref/fatsecret/api-profile-create
title: "Profile Create"
category: ref
tags: ["profile", "fatsecret", "reference"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>Profile Create</title>
  <description>Create a profile for a user within your application.</description>
  <created_at>2026-01-02T19:55:26.849965</created_at>
  <updated_at>2026-01-02T19:55:26.849965</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="Endpoint" level="2"/>
    <section name="Parameters" level="2"/>
    <section name="Response" level="2"/>
    <section name="Example Response (JSON)" level="2"/>
    <section name="3-Legged OAuth" level="2"/>
    <section name="Usage Notes" level="2"/>
  </sections>
  <features>
    <feature>3-legged_oauth</feature>
    <feature>endpoint</feature>
    <feature>example_response_json</feature>
    <feature>parameters</feature>
    <feature>response</feature>
    <feature>usage_notes</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
  </dependencies>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>profile,fatsecret,reference</tags>
</doc_metadata>
-->

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
