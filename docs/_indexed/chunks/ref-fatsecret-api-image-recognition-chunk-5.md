---
doc_id: ref/fatsecret/api-image-recognition
chunk_id: ref/fatsecret/api-image-recognition#chunk-5
heading_path: ["Image Recognition API v1", "Request"]
chunk_type: prose
tokens: 240
summary: "Request"
---

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
