---
doc_id: ops/features/toolchains
chunk_id: ops/features/toolchains#chunk-14
heading_path: ["toolchains", "Toolchains with Blueprints"]
chunk_type: mixed
tokens: 98
summary: "Toolchains can be combined with blueprints, giving you the best of both worlds: a blueprint provi..."
---
Toolchains can be combined with blueprints, giving you the best of both worlds: a blueprint provides the core template for your module, while toolchains add supplementary functionality.

```bash
dagger init --blueprint=github.com/example/app-blueprint
dagger toolchain install github.com/example/linter
dagger toolchain install github.com/example/deployer
```

This configuration allows you to:

- Use the blueprint's functions as your module's primary API
- Access additional toolchain functions for auxiliary tasks
- Keep your module focused while still having access to extended functionality
