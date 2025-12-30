---
doc_id: ref/reference/configuration-proxy
chunk_id: ref/reference/configuration-proxy#chunk-4
heading_path: ["configuration-proxy", "Applies to All Containers"]
chunk_type: prose
tokens: 91
summary: "These proxy environment variables set on Dagger will also be automatically set on all containers ..."
---
These proxy environment variables set on Dagger will also be automatically set on all containers created by userspace Dagger Functions unless otherwise specified.

The values of these environment variables:
- Do not impact caching of containers
- Are not persisted in Dagger's cache
- Changing values won't invalidate cache

If `withEnvVariable` API is used to explicitly set proxy environment variables, those will override any settings inherited from Dagger's proxy configuration.
