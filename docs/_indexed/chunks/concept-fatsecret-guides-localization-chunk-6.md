---
doc_id: concept/fatsecret/guides-localization
chunk_id: concept/fatsecret/guides-localization#chunk-6
heading_path: ["FatSecret Platform API - Localization", "Behavior Notes"]
chunk_type: prose
tokens: 132
summary: "Behavior Notes"
---

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
