---
doc_id: tutorial/fatsecret/guides-welcome
chunk_id: tutorial/fatsecret/guides-welcome#chunk-2
heading_path: ["FatSecret Platform API - Welcome", "Integration Methods"]
chunk_type: code
tokens: 66
summary: "Integration Methods"
---

## Integration Methods

### URL-Based Integration

Send requests directly to specific method endpoints:

```yaml
https://platform.fatsecret.com/rest/{method}
```yaml

Example:
```yaml
https://platform.fatsecret.com/rest/foods.search.v3
```

### Method-Based Integration

Send requests to the central API endpoint with the method specified as a parameter:

```yaml
https://platform.fatsecret.com/rest/server.api
```text

Pass the method name using the `method` parameter in your request.
