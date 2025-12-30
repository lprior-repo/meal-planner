---
doc_id: ops/features/toolchains
chunk_id: ops/features/toolchains#chunk-15
heading_path: ["toolchains", "Toolchains without an SDK"]
chunk_type: code
tokens: 100
summary: "Even if your module doesn't use an SDK or blueprint, toolchains are valuable."
---
Even if your module doesn't use an SDK or blueprint, toolchains are valuable. They let you compose functionality from multiple modules without writing any code:

```bash
dagger init
dagger toolchain install github.com/example/hello
dagger toolchain install github.com/example/builder
dagger toolchain install github.com/example/tester
```

Your module becomes a collection point for these toolchains, making their combined functionality available through a single interface:

```bash
dagger call hello message
dagger call builder build --source ./app
dagger call tester test --source ./app
```
