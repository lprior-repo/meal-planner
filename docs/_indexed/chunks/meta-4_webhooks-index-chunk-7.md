---
doc_id: meta/4_webhooks/index
chunk_id: meta/4_webhooks/index#chunk-7
heading_path: ["Webhooks", "Export webhook definitions to OpenAPI"]
chunk_type: prose
tokens: 81
summary: "Export webhook definitions to OpenAPI"
---

## Export webhook definitions to OpenAPI

Windmill supports generating an OpenAPI 3.1 specification that includes both HTTP routes and webhook triggers.

Webhook endpoints included in the spec:

- Are matched using filters you define
- Include `summary` and `description` if available
- Are automatically mapped to use **JWT Bearer authentication** in the spec

You can generate this from the [Custom HTTP routes](/docs/core_concepts/http_routing#generate-an-openapi-specification-from-http-routes-and-webhooks) page.
