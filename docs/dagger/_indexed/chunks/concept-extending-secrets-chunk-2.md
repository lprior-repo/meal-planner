---
doc_id: concept/extending/secrets
chunk_id: concept/extending/secrets#chunk-2
heading_path: ["secrets", "Caching"]
chunk_type: prose
tokens: 298
summary: "When a `Secret` is included in other operations, the layer cache entries for those operations wil..."
---
When a `Secret` is included in other operations, the layer cache entries for those operations will be based on the plaintext value of the secret. If the same operation is run with a secret with the same plaintext value, that operation may be cached rather than re-executed. In the above example, the secret is specified as `env://API_TOKEN`, so the cache for the `with-exec` will be based on the plaintext value of the secret. If two clients execute the container and have the same `API_TOKEN` environment variable value, they may share layer cache entries for the container. However, if two clients have different values for the `API_TOKEN` environment variable, the `with-exec` will not share cache entries, even though both clients specify the secret as `env://API_TOKEN`.

In some cases, users may desire that operations share layer cache entries even if the secret plaintext value is different. For example, a secret may often rotate in plaintext value but not be meaningfully different; in these cases, it should still be possible to reuse the cache for operations that include that secret.

For these use cases, the optional `cacheKey` argument to `Secret` construction can be used to specify the "cache key" of the secret. Secrets that share the same `cacheKey` will be considered equivalent when checking cache of operations that include them, even if their plaintext value differs. See [the cookbook](./concept-cookbook-secrets.md#customize-secret-caching-behavior) for example usage.
