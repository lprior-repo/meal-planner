---
doc_id: meta/32_private_hub/index
chunk_id: meta/32_private_hub/index#chunk-2
heading_path: ["Private Hub", "Restricting access to your Private Hub"]
chunk_type: prose
tokens: 97
summary: "Restricting access to your Private Hub"
---

## Restricting access to your Private Hub

To restrict access to your Private Hub, you need to set the `API_SECRET` environment variable on your Private Hub instance.
You will also need to set the `Private Hub api secret` field in the [instance settings](./meta-18_instance_settings-index.md#private-hub-api-secret) on your Windmill instance to the same value.

When an `API_SECRET` is set, the Private Hub will only be accessible to logged in users or to requests authenticated with the `X-api-secret` header.
