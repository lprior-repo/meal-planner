---
doc_id: meta/39_http_routing/index
chunk_id: meta/39_http_routing/index#chunk-9
heading_path: ["HTTP routes", "Best practices"]
chunk_type: prose
tokens: 79
summary: "Best practices"
---

## Best practices

- Use **preprocessors** to parse, validate, or transform payloads before the `main()` function.
- Prefer **Signature Auth** for third-party integrations that support webhook signing (e.g., Stripe, GitHub).
- Use **Custom Script** authentication only when predefined options are not flexible enough.
- Enable **raw_string** if you need access to the raw body for signature verification or special payloads.

---
