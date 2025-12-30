---
doc_id: ops/general/faq
chunk_id: ops/general/faq#chunk-5
heading_path: ["FAQ", "Troubleshooting"]
chunk_type: prose
tokens: 172
summary: "Troubleshooting"
---

## Troubleshooting

### How to resolve the "version 'GLIBC_X.XX' not found" error?

This is typically caused by running moon in an old environment, like Ubuntu 18, and the minimum required libc doesn't exist or is too old. Since moon is Rust based, we're unable to support all environments and versions perpetually, and will only support relatively modern environments.

There's not an easy fix to this problem, but there are a few potential solutions, from easiest to hardest:

-   Run moon in a Docker container/image that has the correct environment and libs. For example, the `node:latest` image.
-   Upgrade the environment to a newer one. For example, Ubuntu 18 -> 22.
-   Try and install a newer libc (more information).

For more information on this problem as a whole, refer to this in-depth article.
