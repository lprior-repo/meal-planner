---
doc_id: ops/features/toolchains
chunk_id: ops/features/toolchains#chunk-2
heading_path: ["toolchains", "Key Concepts"]
chunk_type: prose
tokens: 108
summary: "Toolchains are Dagger modules that are installed into your module to provide additional functiona..."
---
### What are Toolchains?

Toolchains are Dagger modules that are installed into your module to provide additional functionality without needing to integrate with your module's SDK or blueprint. When you install a toolchain:

- The toolchain's functions become available in your module's API as a namespaced field
- Multiple toolchains can be installed simultaneously
- Toolchains work with modules that have an SDK, use a blueprint, or neither
- Each toolchain maintains its own context and can access files from your module's directory
