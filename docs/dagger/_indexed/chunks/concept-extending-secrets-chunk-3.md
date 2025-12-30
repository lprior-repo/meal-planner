---
doc_id: concept/extending/secrets
chunk_id: concept/extending/secrets#chunk-3
heading_path: ["secrets", "Security considerations"]
chunk_type: prose
tokens: 120
summary: "- Dagger automatically scrubs secrets from its various logs and output streams."
---
- Dagger automatically scrubs secrets from its various logs and output streams. This ensures that sensitive data does not leak - for example, in the event of a crash.
- Secret plaintext should be handled securely within your Dagger workflow. For example, you should not write secret plaintext to a file, as it could then be stored in the Dagger cache.
- Secrets are scoped by default to the modules they're defined in. To share a secret across modules, you must intentionally pass a reference to it via constructor or function arguments.
