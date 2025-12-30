---
doc_id: ref/fatsecret/guides-parameters
chunk_id: ref/fatsecret/guides-parameters#chunk-4
heading_path: ["FatSecret Platform API - Parameters Reference", "Common Request Parameters"]
chunk_type: prose
tokens: 222
summary: "Common Request Parameters"
---

## Common Request Parameters

### Pagination

| Parameter | Type | Description |
|-----------|------|-------------|
| `page_number` | integer | Page number (0-indexed) |
| `max_results` | integer | Maximum results per page |

### Search

| Parameter | Type | Description |
|-----------|------|-------------|
| `search_expression` | string | Search query text |
| `must_have_images` | boolean | Filter to items with images |

### Date Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `date` | integer | Days since January 1, 1970 |
| `from_date` | integer | Start date (days since epoch) |
| `to_date` | integer | End date (days since epoch) |

### Food Entry Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `meal` | string | Meal type: `breakfast`, `lunch`, `dinner`, `other` |
| `number_of_units` | decimal | Number of servings |

### Sorting

| Parameter | Type | Description |
|-----------|------|-------------|
| `sort_by` | string | Field to sort by |
| `sort_order` | string | Sort direction: `asc` or `desc` |
