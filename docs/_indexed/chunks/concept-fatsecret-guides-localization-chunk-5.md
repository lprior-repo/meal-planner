---
doc_id: concept/fatsecret/guides-localization
chunk_id: concept/fatsecret/guides-localization#chunk-5
heading_path: ["FatSecret Platform API - Localization", "Example Requests"]
chunk_type: code
tokens: 132
summary: "Example Requests"
---

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
