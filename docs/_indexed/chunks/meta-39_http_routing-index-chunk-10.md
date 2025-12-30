---
doc_id: meta/39_http_routing/index
chunk_id: meta/39_http_routing/index#chunk-10
heading_path: ["HTTP routes", "Troubleshooting"]
chunk_type: prose
tokens: 80
summary: "Troubleshooting"
---

## Troubleshooting

- If the script isn't triggered:
  - Check that the HTTP method matches (e.g., POST vs GET).
  - Verify authentication is correctly set.
  - Ensure any custom scripts throw errors to help debug failures.

- For signature validation failures:
  - Double-check the secret key and signature header.
  - Ensure `raw_body` is enabled if validation depends on the raw body.

---
