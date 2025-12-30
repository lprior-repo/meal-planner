---
doc_id: ops/tandoor/faq
chunk_id: ops/tandoor/faq#chunk-4
heading_path: ["Faq", "Why am I getting CSRF Errors?"]
chunk_type: prose
tokens: 85
summary: "Why am I getting CSRF Errors?"
---

## Why am I getting CSRF Errors?
If you are getting CSRF Errors this is most likely due to a reverse proxy not passing the correct headers.

If you are using swag by linuxserver you might need `proxy_set_header X-Forwarded-Proto $scheme;` in your nginx config.
If you are using a plain ngix you might need `proxy_set_header Host $http_host;`.

Further discussions can be found in this [Issue #518](https://github.com/vabene1111/recipes/issues/518)
