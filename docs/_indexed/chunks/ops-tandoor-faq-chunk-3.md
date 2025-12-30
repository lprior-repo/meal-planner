---
doc_id: ops/tandoor/faq
chunk_id: ops/tandoor/faq#chunk-3
heading_path: ["Faq", "Why is Tandoor not working correctly?"]
chunk_type: prose
tokens: 253
summary: "Why is Tandoor not working correctly?"
---

## Why is Tandoor not working correctly?
If you just set up your Tandoor instance and you're having issues like;

- Links not working
- CSRF errors
- CORS errors
- No recipes are loading

then make sure you have set [all required headers](./ops-install-docker.md#required-headers) in your reverse proxy correctly.
If that doesn't fix it, you can also refer to the appropriate sub section in the [reverse proxy documentation](./ops-install-docker.md#reverse-proxy) and verify your general webserver configuration.

### Required Headers
Navigate to `/system/` and review the headers listed in the DEBUG section.  At a minimum, if you are using a reverse proxy the headers must match the below conditions.

| Header      | Requirement |
| :---        |    :----   |
| HTTP_HOST:mydomain.tld      | The host domain must match the url that you are using to open Tandoor.  |
| HTTP_X_FORWARDED_HOST:mydomain.tld      | The host domain must match the url that you are using to open Tandoor.  |
| HTTP_X_FORWARDED_PROTO:http(s)      | The protocol must match the url you are using to open Tandoor.  There must be exactly one protocol listed.  |
| HTTP_X_SCRIPT_NAME:/subfolder      | If you are hosting Tandoor at a subfolder instead of a subdomain this header must exist. |
