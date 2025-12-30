---
doc_id: ops/features/toolchains
chunk_id: ops/features/toolchains#chunk-5
heading_path: ["toolchains", "App teams install them"]
chunk_type: code
tokens: 117
summary: "dagger toolchain install github."
---
dagger toolchain install github.com/platform/linter
dagger toolchain install github.com/platform/security-scanner
dagger toolchain install github.com/platform/deployer

dagger call linter lint
```

### CI/CD Composition

Build a complete CI/CD pipeline by composing toolchains:

```bash
dagger toolchain install github.com/example/tester
dagger toolchain install github.com/example/builder
dagger toolchain install github.com/example/publisher
dagger toolchain install github.com/example/notifier
```

Run your entire pipeline:

```bash
dagger call tester test && \
dagger call builder build && \
dagger call publisher publish && \
dagger call notifier notify --status success
```

### Polyglot Projects

Use toolchains written in different languages without worrying about compatibility:

```bash
