---
id: ref/fatsecret/api-profile-get
title: "Profile Get Status"
category: ref
tags: ["fatsecret", "profile", "reference"]
---

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
