---
id: ref/fatsecret/api-natural-language-processing
title: "Natural Language Processing API v1"
category: ref
tags: ["advanced", "natural", "reference", "api", "fatsecret"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>Natural Language Processing API v1</title>
  <description>Optional Add-On feature for parsing natural language food descriptions.</description>
  <created_at>2026-01-02T19:55:26.846558</created_at>
  <updated_at>2026-01-02T19:55:26.846558</updated_at>
  <language>en</language>
  <sections count="18">
    <section name="Endpoint" level="2"/>
    <section name="Overview" level="2"/>
    <section name="Authentication" level="2"/>
    <section name="Request" level="2"/>
    <section name="Headers" level="3"/>
    <section name="Body Parameters" level="3"/>
    <section name="eaten_foods Array Structure" level="3"/>
    <section name="Request Limits" level="3"/>
    <section name="Response" level="2"/>
    <section name="food_response Array" level="3"/>
  </sections>
  <features>
    <feature>authentication</feature>
    <feature>best_practices</feature>
    <feature>body_parameters</feature>
    <feature>eaten_foods_array_structure</feature>
    <feature>eaten_object</feature>
    <feature>endpoint</feature>
    <feature>error_codes</feature>
    <feature>example_request</feature>
    <feature>example_response</feature>
    <feature>food_object_when_include_food_datatrue</feature>
    <feature>food_response_array</feature>
    <feature>headers</feature>
    <feature>overview</feature>
    <feature>request</feature>
    <feature>request_limits</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
  </dependencies>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>advanced,natural,reference,api,fatsecret</tags>
</doc_metadata>
-->

# Natural Language Processing API v1

> **Context**: Optional Add-On feature for parsing natural language food descriptions.

Optional Add-On feature for parsing natural language food descriptions.

## Endpoint

```text
POST https://platform.fatsecret.com/rest/natural-language-processing/v1
```text

## Overview

Breaks down natural language input describing food consumption and returns matching foods from the FatSecret database. This enables users to describe what they ate in conversational text rather than searching for individual items.

**Example Input**: "For breakfast I ate a slice of toast with butter"

## Authentication

Requires OAuth 2.0 with the `nlp` scope.

## Request

### Headers

| Header | Value |
|--------|-------|
| Content-Type | application/json |
| Authorization | Bearer {access_token} |

### Body Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_input | string | Yes | Natural language description of foods eaten (max 1,000 characters) |
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
- Maximum `user_input` length: **1,000 characters**

## Response

The response structure is identical to the Image Recognition API.

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
  "user_input": "For breakfast I ate a slice of toast with butter",
  "include_food_data": true,
  "eaten_foods": [
    {
      "food_id": 12345,
      "food_name": "Whole Wheat Bread",
      "food_brand": "Nature's Own",
      "serving_description": "1 slice",
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
      "food_id": 33099,
      "food_entry_name": "Toast",
      "eaten": {
        "food_names": ["Toast", "White Toast", "Toasted Bread"],
        "descriptions": ["1 slice of toast"],
        "units": ["slice", "piece"],
        "metric_info": {
          "metric_serving_amount": 30,
          "metric_serving_unit": "g"
        },
        "total_nutritional_content": {
          "calories": 79,
          "carbohydrate": 15,
          "protein": 2.7,
          "fat": 1,
          "fiber": 0.8
        }
      },
      "suggested_serving": {
        "serving_id": 47512,
        "serving_description": "1 slice",
        "number_of_units": 1
      }
    },
    {
      "food_id": 36774,
      "food_entry_name": "Butter",
      "eaten": {
        "food_names": ["Butter", "Salted Butter"],
        "descriptions": ["1 pat of butter"],
        "units": ["pat", "tbsp", "tsp", "cup"],
        "metric_info": {
          "metric_serving_amount": 5,
          "metric_serving_unit": "g"
        },
        "total_nutritional_content": {
          "calories": 36,
          "carbohydrate": 0,
          "protein": 0,
          "fat": 4.1,
          "fiber": 0
        }
      },
      "suggested_serving": {
        "serving_id": 51284,
        "serving_description": "1 pat",
        "number_of_units": 1
      }
    }
  ]
}
```

## Error Codes

| Code | Description |
|------|-------------|
| 211 | No food item detected in the input |

## Best Practices

1. **Intermediate Screen**: After receiving results, show an intermediate screen allowing users to adjust servings before logging. This improves accuracy and user experience.

2. **Clear Input**: Encourage users to be specific about quantities (e.g., "two eggs" instead of "some eggs") for better matching.

3. **Eaten Foods Context**: Provide `eaten_foods` array when available to improve matching based on user's eating patterns and preferred brands.

4. **Error Handling**: Always handle error 211 gracefully - prompt users to rephrase or use manual food search.

5. **Input Validation**: Validate input length client-side before making API calls to avoid unnecessary requests.

## Use Cases

- **Voice Input**: Convert speech-to-text and pass to NLP API for hands-free food logging
- **Quick Logging**: Allow users to log entire meals in one natural sentence
- **Chat Interfaces**: Power conversational food logging experiences
- **Accessibility**: Simplify food logging for users who find traditional search difficult


## See Also

- [Documentation Index](./COMPASS.md)
