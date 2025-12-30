---
doc_id: ops/tandoor/faq
chunk_id: ops/tandoor/faq#chunk-5
heading_path: ["Faq", "Why are images not loading?"]
chunk_type: prose
tokens: 107
summary: "Why are images not loading?"
---

## Why are images not loading?
If images are not loading this might be related to the same issue as the CSRF errors (see above).
A discussion about that can be found at [Issue #452](https://github.com/vabene1111/recipes/issues/452)

The other common issue is that the recommended nginx container is removed from the deployment stack.
If removed, the nginx webserver needs to be replaced by something else that servers the /mediafiles/ directory or
`GUNICORN_MEDIA` needs to be enabled to allow media serving by the application container itself.
