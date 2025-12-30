---
doc_id: meta/39_http_routing/index
chunk_id: meta/39_http_routing/index#chunk-5
heading_path: ["HTTP routes", "Generate an OpenAPI specification from HTTP routes and webhooks"]
chunk_type: prose
tokens: 418
summary: "Generate an OpenAPI specification from HTTP routes and webhooks"
---

## Generate an OpenAPI specification from HTTP routes and webhooks

Windmill supports generating a compliant OpenAPI 3.1 specification from your existing HTTP routes and webhook triggers.

### How it works

You can export a unified OpenAPI specification that includes:

- HTTP routes and webhook triggers (filtered by path or type)
- Route metadata: `summary`, `description`, async/sync behavior
- Security models for supported authentication types
- Parameter inference (e.g., `:id` becomes an OpenAPI `path` parameter)
- Auto-generated `servers`, `components`, and reusable definitions

### To generate a spec

1. Go to **Custom HTTP routes**
2. Click **To OpenAPI spec**
3. (Optional) Provide API metadata:
   - **Title** and **version** (default to `"Windmill API"` and `"1.0.0"` if omitted)
   - **Description**, **contact info**, and **license** are also supported
4. Add **filters** to include specific routes or webhooks:
   - HTTP Routes: by folder, path, and route pattern
   - Webhooks: by kind (`script` or `flow`) and path
5. Choose output format: **YAML** or **JSON**
6. Click **Generate OpenAPI document**

You can then:
- Preview and copy the document
- Download it
- Copy a ready-made `cURL` command to call the generation API

### Security mapping

The OpenAPI document reflects security as follows:

- **HTTP Routes**:
  - ✅ `Windmill Auth` → JWT bearer scheme (`bearerFormat: JWT`)
  - ✅ `Basic Auth` → HTTP Basic auth scheme
  - ✅ `API Key` → API key in header (with exact header name)
  - ❌ Other methods (e.g., Custom Script, Signature Auth) will not be included in the `security` field

- **Webhooks**:
  - Always mapped to `JWT bearer` authentication (`bearerFormat: JWT`)

All defined security schemes are included under `components.securitySchemes`.


### Additional behavior

- For **HTTP routes**, any route segments like `:user_id` are automatically converted to OpenAPI `path` parameters
- For **webhooks**, both **asynchronous** and **synchronous** endpoint variants are included in the spec
- Metadata such as `summary` and `description` is included when available
- Standardized `requestBodies` and `responses` are defined in the `components` section
---
