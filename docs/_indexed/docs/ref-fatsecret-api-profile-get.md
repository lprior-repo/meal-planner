---
id: ref/fatsecret/api-profile-get
title: "Profile Get Status"
category: ref
tags: ["profile", "fatsecret", "reference"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>Profile Get Status</title>
  <description>Retrieve profile status and settings for a user.</description>
  <created_at>2026-01-02T19:55:26.851722</created_at>
  <updated_at>2026-01-02T19:55:26.851722</updated_at>
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

# Profile Get Status

> **Context**: Retrieve profile status and settings for a user.

Retrieve profile status and settings for a user.

> **OAuth 1.0 Only** - This endpoint requires OAuth 1.0 authentication.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/profile/v1`
- **HTTP Method:** GET
- **API Method:** `profile.get`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `format` | string | No | Response format: `json` or `xml` (default: `xml`) |

## Response

| Field | Type | Description |
|-------|------|-------------|
| `weight_measure` | string | User's preferred weight unit: `kg` or `lb` |
| `height_measure` | string | User's preferred height unit: `cm` or `inch` |
| `last_weight_kg` | number | Most recent weight entry in kilograms |
| `last_weight_date_int` | integer | Date of last weight entry (days since Jan 1, 1970) |
| `last_weight_comment` | string | Comment on the last weight entry |
| `goal_weight_kg` | number | Target weight in kilograms |
| `height_cm` | number | User's height in centimeters |

## Example Response (JSON)

```json
{
  "profile": {
    "weight_measure": "kg",
    "height_measure": "cm",
    "last_weight_kg": "75.5",
    "last_weight_date_int": "19724",
    "last_weight_comment": "Morning weigh-in",
    "goal_weight_kg": "70.0",
    "height_cm": "175"
  }
}
```

## Usage Notes

- Weight values are always returned in kilograms regardless of `weight_measure` preference
- Height is always returned in centimeters regardless of `height_measure` preference
- Use the `*_measure` fields to display values in the user's preferred units
- `last_weight_date_int` uses Unix epoch day format (days since January 1, 1970)


## See Also

- [Documentation Index](./COMPASS.md)
