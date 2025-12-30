---
doc_id: ref/fatsecret/guides-oauth1
chunk_id: ref/fatsecret/guides-oauth1#chunk-7
heading_path: ["FatSecret Platform API - OAuth 1.0 Guide", "Usage"]
chunk_type: prose
tokens: 19
summary: "Usage"
---

## Usage
result = oauth1_request(
    'YOUR_CONSUMER_KEY',
    'YOUR_CONSUMER_SECRET',
    'foods.search',
    {'search_expression': 'chicken', 'format': 'json'}
)
print(result)
```
