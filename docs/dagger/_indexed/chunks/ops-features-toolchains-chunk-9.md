---
doc_id: ops/features/toolchains
chunk_id: ops/features/toolchains#chunk-9
heading_path: ["toolchains", "Installing Toolchains"]
chunk_type: mixed
tokens: 173
summary: "To install a toolchain in your module, use the `dagger toolchain install` command:

```bash
dagge..."
---
### Install a Toolchain

To install a toolchain in your module, use the `dagger toolchain install` command:

```bash
dagger toolchain install github.com/example/toolchain
```

You can install toolchains from:

- **GitHub repositories**: `github.com/user/repo/path`
- **Local paths**: `./path/to/toolchain` or `/absolute/path`
- **Git URLs**: Any valid Git URL with optional version tags

### Install with a Custom Name

By default, the toolchain is accessible using its module name. If the module name is not suitable or conflicts with a function in your module, you can specify a custom name:

```bash
dagger toolchain install github.com/example/toolchain --name mytool
```

### Install Multiple Toolchains

You can install as many toolchains as you need:

```bash
dagger toolchain install github.com/example/hello
dagger toolchain install github.com/example/builder
dagger toolchain install github.com/example/tester
```

Each toolchain becomes available under its own namespace in your module's API.
