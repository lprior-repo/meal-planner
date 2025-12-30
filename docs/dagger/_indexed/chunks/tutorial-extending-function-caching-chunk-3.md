---
doc_id: tutorial/extending/function-caching
chunk_id: tutorial/extending/function-caching#chunk-3
heading_path: ["function-caching", "How cache hits work"]
chunk_type: prose
tokens: 519
summary: "This section details mechanics important to understanding when and why a function call may be eit..."
---
This section details mechanics important to understanding when and why a function call may be either cached or uncached.

### Function inputs as cache keys

When the Dagger engine checks for a cached result of a function call, it looks at all the inputs to the call:

1. The source code of the module the function is in
2. The values of the arguments being provided to the function call
3. The values of the parent object of the function call

If a previous function call has been made with all of those inputs at the same value, then there is potential for a cache hit. In other words, all those inputs serve as the "cache key".

This also means that if any of those inputs change from what has been called previously, you will get a cache miss. For example, changing the source code of a module will invalidate all the cache for its functions.

### Secrets and caching

[Secrets](/getting-started/types/secret) are never cached on disk by Dagger. Function calls that return Secrets or values that reference Secrets (e.g. a Container that has a secret set as an environment variable) *may* be cached provided that the Secret in question was sourced using a secret provider (e.g. `env://MY_SECRET`). In these cases, Dagger is able to cache the source of the secret without having to write the plaintext to disk, [instead using a securely derived hash of the secret plaintext](./concept-extending-secrets.md#caching).

Secrets that were created via `SetSecret` calls by a function are incompatible with persistent function caching. Any function that returns a value that references such a Secret will not be cached with a TTL even if the function call was configured as such. Instead, the function call will behave as though it was configured as "session" caching (unless it was configured with "never" caching, in which case that setting will be honored).

### TTLs do not guarantee retention

When a function call is cached with a TTL (or has the default behavior of a 7 day TTL), that means that the cache may last for *up to* that TTL. It does not guarantee that the cached result will stay in the engine for that long. It only guarantees that the cache entry will expire after the TTL has passed.

This is because the engine may need to [prune data when disk space runs low](/reference/configuration/cache), which can include cached function call results.
