---
doc_id: ops/commands/overview
chunk_id: ops/commands/overview#chunk-2
heading_path: ["Overview", "Caching"]
chunk_type: prose
tokens: 146
summary: "Caching"
---

## Caching

We provide a powerful [caching layer](/docs/concepts/cache), but sometimes you need to debug failing or broken tasks, and this cache may get in the way. To circumvent this, we support the `--cache` global option, or the `MOON_CACHE` environment variable, both of which accept one of the following values.

-   `off` - Turn off caching entirely. Every task will run fresh, including dependency installs.
-   `read` - Read existing items from the cache, but do not write to them.
-   `read-write` (default) - Read and write items to the cache.
-   `write` - Do not read existing cache items, but write new items to the cache.

```
$ moon run app:build --cache off
