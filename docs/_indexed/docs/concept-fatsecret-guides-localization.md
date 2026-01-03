---
id: concept/fatsecret/guides-localization
title: "FatSecret Platform API - Localization"
category: concept
tags: ["concept", "fatsecret", "advanced", "api"]
---

# FatSecret Platform API - Localization

> **Context**: Localization features allow you to filter food data by region and receive responses in different languages.

Localization features allow you to filter food data by region and receive responses in different languages.

**Note:** Localization requires a Premier subscription and the `localization` scope.

## Parameters

### Region Parameter

The `region` parameter filters food results to show items available in a specific country.

```bash
region=AU
```text

### Language Parameter

The `language` parameter returns response text in the specified language.

```bash
language=de
```

## Supported Regions

| Code | Country |
|------|---------|
| AU | Australia |
| AT | Austria |
| BE | Belgium |
| BR | Brazil |
| CA | Canada |
| CL | Chile |
| CN | China |
| CZ | Czech Republic |
| DK | Denmark |
| FI | Finland |
| FR | France |
| DE | Germany |
| HK | Hong Kong |
| HU | Hungary |
| IN | India |
| ID | Indonesia |
| IE | Ireland |
| IL | Israel |
| IT | Italy |
| JP | Japan |
| KR | South Korea |
| MY | Malaysia |
| MX | Mexico |
| NL | Netherlands |
| NZ | New Zealand |
| NO | Norway |
| PK | Pakistan |
| PH | Philippines |
| PL | Poland |
| PT | Portugal |
| RU | Russia |
| SA | Saudi Arabia |
| SG | Singapore |
| ZA | South Africa |
| ES | Spain |
| SE | Sweden |
| CH | Switzerland |
| TW | Taiwan |
| TH | Thailand |
| TR | Turkey |
| AE | United Arab Emirates |
| GB | United Kingdom |
| US | United States |
| VN | Vietnam |

## Supported Languages

| Code | Language |
|------|----------|
| en | English |
| de | German |
| es | Spanish |
| fr | French |
| it | Italian |
| ja | Japanese |
| ko | Korean |
| nl | Dutch |
| pl | Polish |
| pt | Portuguese |
| ru | Russian |
| zh | Chinese (Simplified) |
| zh-TW | Chinese (Traditional) |

## Example Requests

### Search for Foods in Germany (German Language)

```bash
curl -X POST "https://platform.fatsecret.com/rest/foods.search.v3" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "search_expression": "bread",
    "region": "DE",
    "language": "de",
    "max_results": 10
  }'
```text

### Search for Foods in Japan (Japanese Language)

```bash
curl -X POST "https://platform.fatsecret.com/rest/foods.search.v3" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "search_expression": "rice",
    "region": "JP",
    "language": "ja",
    "max_results": 10
  }'
```bash

### Get Food Details in French

```bash
curl -X POST "https://platform.fatsecret.com/rest/food.get.v4" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "food_id": 33691,
    "language": "fr"
  }'
```text

## Behavior Notes

### Region Filtering

- When `region` is specified, only foods available in that region are returned
- Generic foods (not region-specific) are still included
- Brand-specific foods are filtered to those available in the region

### Language Translation

- Food names and descriptions are translated when available
- Serving descriptions are translated
- Not all foods have translations for all languages
- Falls back to English if translation unavailable

### Combining Parameters

You can use `region` and `language` independently or together:

```json
{
  "search_expression": "cheese",
  "region": "FR",
  "language": "fr"
}
```text

This returns French foods with French language text.

## OAuth 2.0 Scope

Include the `localization` scope when requesting your access token:

```bash
curl -X POST "https://oauth.fatsecret.com/connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "YOUR_CLIENT_ID:YOUR_CLIENT_SECRET" \
  -d "grant_type=client_credentials&scope=basic localization"
```

## Default Behavior

- If `region` is not specified: Returns global food database
- If `language` is not specified: Returns English text


## See Also

- [Documentation Index](./COMPASS.md)
