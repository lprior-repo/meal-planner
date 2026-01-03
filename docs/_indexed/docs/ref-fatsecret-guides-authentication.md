---
id: ref/fatsecret/guides-authentication
title: "FatSecret Platform API - Authentication"
category: ref
tags: ["api", "fatsecret", "reference"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>FatSecret Platform API - Authentication</title>
  <description>The FatSecret Platform API supports multiple authentication methods depending on your use case.</description>
  <created_at>2026-01-02T19:55:26.858425</created_at>
  <updated_at>2026-01-02T19:55:26.858425</updated_at>
  <language>en</language>
  <sections count="10">
    <section name="Authentication Types" level="2"/>
    <section name="Signed Requests" level="3"/>
    <section name="OAuth 2.0 (Recommended)" level="4"/>
    <section name="OAuth 1.0" level="4"/>
    <section name="Signed and Delegated Requests" level="3"/>
    <section name="Profile Management" level="2"/>
    <section name="profile.create" level="3"/>
    <section name="profile.get_auth" level="3"/>
    <section name="Choosing an Authentication Method" level="2"/>
    <section name="Security Best Practices" level="2"/>
  </sections>
  <features>
    <feature>authentication_types</feature>
    <feature>choosing_an_authentication_method</feature>
    <feature>oauth_10</feature>
    <feature>oauth_20_recommended</feature>
    <feature>profile_management</feature>
    <feature>profilecreate</feature>
    <feature>profileget_auth</feature>
    <feature>security_best_practices</feature>
    <feature>signed_and_delegated_requests</feature>
    <feature>signed_requests</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
    <dependency type="feature">ref/fatsecret/guides-oauth2</dependency>
    <dependency type="feature">ref/fatsecret/guides-oauth1</dependency>
    <dependency type="feature">tutorial/fatsecret/guides-oauth1-three-legged</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">guides-oauth2.md</entity>
    <entity relationship="uses">guides-oauth1.md</entity>
    <entity relationship="uses">guides-oauth1-three-legged.md</entity>
  </related_entities>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>api,fatsecret,reference</tags>
</doc_metadata>
-->

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
