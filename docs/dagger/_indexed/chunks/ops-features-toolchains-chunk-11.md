---
doc_id: ops/features/toolchains
chunk_id: ops/features/toolchains#chunk-11
heading_path: ["toolchains", "Toolchains with SDKs"]
chunk_type: mixed
tokens: 74
summary: "Toolchains work seamlessly with modules that have an SDK."
---
Toolchains work seamlessly with modules that have an SDK. Your module can implement its own functions while also exposing toolchain functions:

### Example: Go Module with Toolchain

Initialize a Go module and install a toolchain:

```bash
dagger init --sdk=go
dagger toolchain install github.com/example/hello
```

Now you can call both your module's functions and the toolchain's functions:

```bash
