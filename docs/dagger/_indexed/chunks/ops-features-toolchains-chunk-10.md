---
doc_id: ops/features/toolchains
chunk_id: ops/features/toolchains#chunk-10
heading_path: ["toolchains", "Using Toolchains"]
chunk_type: code
tokens: 160
summary: "Once installed, toolchain functions are available through the toolchain's namespace."
---
### Calling Toolchain Functions

Once installed, toolchain functions are available through the toolchain's namespace. For example, if you installed a toolchain named `hello`:

```bash
dagger call hello message
```

If the toolchain has a constructor that accepts parameters, you can provide them:

```bash
dagger call hello --config myconfig.txt field-config
```

### Accessing Module Files from Toolchains

Toolchains have access to your module's context directory. This means a toolchain can reference files in your module using default path parameters or explicit file arguments:

```go
// In a toolchain module
func (m *Hello) AppConfig(
    ctx context.Context,
    // +defaultPath="./app-config.txt"
    config *dagger.File,
) (string, error) {
    return config.Contents(ctx)
}
```

When called from your module, `app-config.txt` will be resolved from your module's directory, not the toolchain's repository.
