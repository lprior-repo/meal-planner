---
doc_id: ref/fatsecret/api-foods-search-v1
chunk_id: ref/fatsecret/api-foods-search-v1#chunk-4
heading_path: ["Foods Search v1", "Parameters"]
chunk_type: prose
tokens: 149
summary: "Parameters"
---

## Parameters

### Standard Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `search_expression` | string | Yes | Search terms for food matching |
| `page_number` | integer | No | Page number for paginated results (0-based) |
| `max_results` | integer | No | Maximum results per page (max 50) |
| `format` | string | No | Response format (`json` or `xml`) |

### Premier Parameters

These parameters require Premier access:

| Parameter | Type | Description |
|-----------|------|-------------|
| `generic_description` | string | Filter by generic food description |
| `region` | string | Filter by region code |
| `language` | string | Response language code |
