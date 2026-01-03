---
id: tutorial/fatsecret/guides-welcome
title: "FatSecret Platform API - Welcome"
category: tutorial
tags: ["tutorial", "api", "fatsecret", "beginner"]
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>api</category>
  <title>FatSecret Platform API - Welcome</title>
  <description>The FatSecret Platform API provides programmatic access to FatSecret&apos;s food and nutrition database.</description>
  <created_at>2026-01-02T19:55:26.881129</created_at>
  <updated_at>2026-01-02T19:55:26.881129</updated_at>
  <language>en</language>
  <sections count="9">
    <section name="Integration Methods" level="2"/>
    <section name="URL-Based Integration" level="3"/>
    <section name="Method-Based Integration" level="3"/>
    <section name="Authentication" level="2"/>
    <section name="OAuth 2.0" level="3"/>
    <section name="OAuth 1.0" level="3"/>
    <section name="Response Formats" level="2"/>
    <section name="Getting Started" level="2"/>
    <section name="Related Guides" level="2"/>
  </sections>
  <features>
    <feature>authentication</feature>
    <feature>getting_started</feature>
    <feature>integration_methods</feature>
    <feature>method-based_integration</feature>
    <feature>oauth_10</feature>
    <feature>oauth_20</feature>
    <feature>related_guides</feature>
    <feature>response_formats</feature>
    <feature>url-based_integration</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
    <dependency type="feature">ref/fatsecret/guides-authentication</dependency>
    <dependency type="feature">ref/fatsecret/guides-oauth2</dependency>
    <dependency type="feature">ref/fatsecret/guides-oauth1</dependency>
    <dependency type="feature">ref/fatsecret/guides-parameters</dependency>
    <dependency type="feature">ops/fatsecret/guides-error-codes</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">guides-authentication.md</entity>
    <entity relationship="uses">guides-oauth2.md</entity>
    <entity relationship="uses">guides-oauth1.md</entity>
    <entity relationship="uses">guides-parameters.md</entity>
    <entity relationship="uses">guides-error-codes.md</entity>
  </related_entities>
  <examples count="5">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>tutorial,api,fatsecret,beginner</tags>
</doc_metadata>
-->

# FatSecret Platform API - Welcome

> **Context**: The FatSecret Platform API provides programmatic access to FatSecret's food and nutrition database.

The FatSecret Platform API provides programmatic access to FatSecret's food and nutrition database.

## Integration Methods

### URL-Based Integration

Send requests directly to specific method endpoints:

```yaml
https://platform.fatsecret.com/rest/{method}
```yaml

Example:
```yaml
https://platform.fatsecret.com/rest/foods.search.v3
```

### Method-Based Integration

Send requests to the central API endpoint with the method specified as a parameter:

```yaml
https://platform.fatsecret.com/rest/server.api
```text

Pass the method name using the `method` parameter in your request.

## Authentication

The API supports two OAuth standards:

### OAuth 2.0

- Recommended for new integrations
- Uses Bearer tokens in the Authorization header
- Simpler implementation

**Example Request (OAuth 2.0):**

```bash
curl -X POST "https://platform.fatsecret.com/rest/foods.search.v3" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"search_expression": "chicken breast", "max_results": 10}'
```text

### OAuth 1.0

- Legacy support available
- Requires request signing with HMAC-SHA1
- Supports 3-legged OAuth for user profile access

**Example Request (OAuth 1.0):**

```bash
curl "https://platform.fatsecret.com/rest/server.api?method=foods.search&search_expression=chicken&oauth_consumer_key=YOUR_KEY&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1234567890&oauth_nonce=abc123&oauth_version=1.0&oauth_signature=CALCULATED_SIGNATURE"
```

## Response Formats

The API returns responses in JSON format by default. Include the `format` parameter to specify the response format if needed.

## Getting Started

1. Register for API credentials at [FatSecret Platform](https://platform.fatsecret.com/)
2. Choose your authentication method (OAuth 2.0 recommended)
3. Obtain an access token
4. Start making API requests

## Related Guides

- [Authentication Overview](./ref-fatsecret-guides-authentication.md)
- [OAuth 2.0 Guide](./ref-fatsecret-guides-oauth2.md)
- [OAuth 1.0 Guide](./ref-fatsecret-guides-oauth1.md)
- [Parameters Reference](./ref-fatsecret-guides-parameters.md)
- [Error Codes](./ops-fatsecret-guides-error-codes.md)


## See Also

- [Authentication Overview](guides-authentication.md)
- [OAuth 2.0 Guide](guides-oauth2.md)
- [OAuth 1.0 Guide](guides-oauth1.md)
- [Parameters Reference](guides-parameters.md)
- [Error Codes](guides-error-codes.md)
