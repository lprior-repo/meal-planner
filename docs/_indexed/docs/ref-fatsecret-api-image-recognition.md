---
id: ref/fatsecret/api-image-recognition
title: "Image Recognition API v1"
category: ref
tags: ["advanced", "api", "reference", "image", "fatsecret"]
---

# Image Recognition API v1

> **Context**: Optional Add-On feature for detecting foods within images.

Optional Add-On feature for detecting foods within images.

## Endpoint

```text
POST https://platform.fatsecret.com/rest/image-recognition/v1
```text

## Overview

Detects foods within an image and returns matches from the FatSecret database. This endpoint analyzes uploaded images and identifies food items, returning nutritional information and serving suggestions.

## Authentication

Requires OAuth 2.0 with the `image-recognition` scope.

## Request

### Headers

| Header | Value |
|--------|-------|
| Content-Type | application/json |
| Authorization | Bearer {access_token} |

### Body Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| image_b64 | string | Yes | Base64 encoded image (max 999,982 characters) |
| include_food_data | boolean | No | Include full food data in response |
| eaten_foods | array | No | Previously consumed foods for better matching |
| region | string | No | Region filter (Premier feature) |
| language | string | No | Response language (Premier feature) |

### eaten_foods Array Structure

Each item in the `eaten_foods` array can contain:

| Field | Type | Description |
|-------|------|-------------|
| food_id | integer | FatSecret food ID |
| food_name | string | Name of the food |
| food_brand | string | Brand name (if applicable) |
| serving_description | string | Description of serving size |
| serving_size | number | Size of the serving |

### Request Limits

- Maximum request body size: **1 MB**
- Maximum `image_b64` length: **999,982 characters**

## Response

### food_response Array

Each detected food item includes:

| Field | Type | Description |
|-------|------|-------------|
| food_id | integer | Unique food identifier |
| food_entry_name | string | Display name for the food entry |

### eaten Object

Information about the detected food as consumed:

| Field | Type | Description |
|-------|------|-------------|
| food_names | array | Possible names for the food |
| descriptions | array | Food descriptions |
| units | array | Available units of measurement |
| metric_info | object | Metric measurement information |
| total_nutritional_content | object | Complete nutritional breakdown |

### suggested_serving Object

Recommended serving information:

| Field | Type | Description |
|-------|------|-------------|
| serving_id | integer | Unique serving identifier |
| serving_description | string | Human-readable serving description |
| number_of_units | number | Suggested number of units |

### food Object (when include_food_data=true)

Full food details including:

- Complete food information
- All available servings with nutritional data
- Brand information (if applicable)

## Example Request

```json
{
  "image_b64": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
  "include_food_data": true,
  "eaten_foods": [
    {
      "food_id": 12345,
      "food_name": "Apple",
      "serving_description": "1 medium",
      "serving_size": 1
    }
  ]
}
```text

## Example Response

```json
{
  "food_response": [
    {
      "food_id": 33691,
      "food_entry_name": "Banana",
      "eaten": {
        "food_names": ["Banana", "Fresh Banana"],
        "descriptions": ["Medium banana"],
        "units": ["medium", "small", "large", "cup sliced"],
        "metric_info": {
          "metric_serving_amount": 118,
          "metric_serving_unit": "g"
        },
        "total_nutritional_content": {
          "calories": 105,
          "carbohydrate": 27,
          "protein": 1.3,
          "fat": 0.4,
          "fiber": 3.1
        }
      },
      "suggested_serving": {
        "serving_id": 52183,
        "serving_description": "1 medium (7\" to 7-7/8\" long)",
        "number_of_units": 1
      },
      "food": {
        "food_id": 33691,
        "food_name": "Banana",
        "food_type": "Generic",
        "servings": {
          "serving": [...]
        }
      }
    }
  ]
}
```

## Error Codes

| Code | Description |
|------|-------------|
| 211 | No food item detected in the image |

## Best Practices

1. **Intermediate Screen**: After receiving results, show an intermediate screen allowing users to adjust servings before logging. This improves accuracy and user experience.

2. **Image Quality**: Use clear, well-lit images with the food as the primary subject for best recognition results.

3. **Eaten Foods Context**: Provide `eaten_foods` array when available to improve matching based on user's eating patterns.

4. **Error Handling**: Always handle error 211 gracefully - prompt users to try a different image or use manual food search.


## See Also

- [Documentation Index](./COMPASS.md)
