---
id: ref/fatsecret/api-profile-get-auth
title: "Profile Get Auth"
category: ref
tags: ["profile", "fatsecret", "reference"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>Profile Get Auth</title>
  <description>Retrieve authentication credentials for an existing user profile.</description>
  <created_at>2026-01-02T19:55:26.850974</created_at>
  <updated_at>2026-01-02T19:55:26.850974</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Endpoint" level="2"/>
    <section name="Parameters" level="2"/>
    <section name="Response" level="2"/>
    <section name="Example Response (JSON)" level="2"/>
    <section name="Usage Notes" level="2"/>
  </sections>
  <features>
    <feature>endpoint</feature>
    <feature>example_response_json</feature>
    <feature>parameters</feature>
    <feature>response</feature>
    <feature>usage_notes</feature>
  </features>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>profile,fatsecret,reference</tags>
</doc_metadata>
-->

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
