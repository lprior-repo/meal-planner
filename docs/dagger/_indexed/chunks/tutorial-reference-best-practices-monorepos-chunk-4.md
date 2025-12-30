---
doc_id: tutorial/reference/best-practices-monorepos
chunk_id: tutorial/reference/best-practices-monorepos#chunk-4
heading_path: ["best-practices-monorepos", "Optimization Considerations"]
chunk_type: prose
tokens: 88
summary: "When optimizing monorepo builds, there are two layers to keep in mind:

1."
---
When optimizing monorepo builds, there are two layers to keep in mind:

1. **Dagger's layer cache**: Even if unnecessary CI jobs are triggered, Dagger's layer cache allows most to finish almost instantly. This minimizes infrastructure overhead and makes CI configurations smaller and less fragile.

2. **CI-specific event filters**: These can serve as a secondary optimization but are not as portable as Dagger modules. Use only when absolutely necessary.
