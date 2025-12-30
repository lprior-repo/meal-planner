---
doc_id: meta/39_http_routing/index
chunk_id: meta/39_http_routing/index#chunk-6
heading_path: ["HTTP routes", "Authentication options"]
chunk_type: prose
tokens: 228
summary: "Authentication options"
---

## Authentication options

Windmill supports several ways to secure HTTP triggers:

| Method           | Description                                                                                  |
|------------------|----------------------------------------------------------------------------------------------|
| **None**         | Open to anyone (use only in trusted environments)                                            |
| **Windmill Auth**| Uses a Windmill-signed JWT token to ensure the requesting agent has read access to both the runnable and the trigger. The token must be provided either in the Authorization header as Bearer `<token>`, or via a cookie named `token`. You can generate this token from your user settings. |
| **API Key**      | Checks a header (e.g., `x-api-key`) for a valid key stored as a resource                     |
| **Basic Auth**   | Uses HTTP Basic Authentication via a configured resource                                     |
| **Signature Auth** | Verifies a signature using HMAC or third-party formats (Stripe, GitHub, etc.)               |

---

### Signature Auth (HMAC-based)

Use **Signature Auth** to validate incoming HTTP requests using HMAC-style signatures.

- Choose a preset (e.g., Stripe, GitHub) or configure a generic HMAC check.
- If your provider uses custom logic not covered by presets, you can write a **Custom Script** instead.

---
