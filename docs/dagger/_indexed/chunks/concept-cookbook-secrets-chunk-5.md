---
doc_id: concept/cookbook/secrets
chunk_id: concept/cookbook/secrets#chunk-5
heading_path: ["secrets", "Customize secret caching behavior"]
chunk_type: mixed
tokens: 216
summary: "By default, the layer cache entries for operations that include a secret will be based on the pla..."
---
By default, the layer cache entries for operations that include a secret will be based on the plaintext value of the secret. Operations that include secrets with the same plaintext value may share cache entries, but if the plaintext differs then the operation will not share cache entries.

In some cases, users may desire that operations share the layer cache entries even if the secret plaintext value is different. For example, a secret may often rotate in plaintext value but not be meaningfully different; in these cases, it should still be possible to reuse the cache for operations that include that secret.

For these use cases, the optional `cacheKey` argument to `Secret` construction can be used to specify the "cache key" of the secret. Secrets that share the same `cacheKey` will be considered equivalent when checking the layer cache for operations that include them, even if their plaintext value differs.

### Example

Use a secret with a specified cache key:

```bash
dagger call github-api --token=env://GITHUB_API_TOKEN?cacheKey=my-cache-key
```
