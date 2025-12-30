---
doc_id: ops/extending/chaining
chunk_id: ops/extending/chaining#chunk-3
heading_path: ["chaining", "Live-debug container builds"]
chunk_type: code
tokens: 139
summary: "`Container` objects expose a `terminal()` API method, which lets you starting an ephemeral intera..."
---
`Container` objects expose a `terminal()` API method, which lets you starting an ephemeral interactive terminal session in the corresponding container. This feature is very useful for debugging and experimenting since it allows you to inspect containers directly and at any stage of your Dagger Function execution.

Here is an example of chaining a `Container.terminal()` function call to start an interactive terminal in the container returned by a Wolfi container builder Dagger Function:

**System shell:**
```bash
dagger -c 'github.com/dagger/dagger/modules/wolfi@v0.16.2 | container --packages=cowsay | terminal'
```

**Dagger Shell:**
```
github.com/dagger/dagger/modules/wolfi@v0.16.2 | container --packages=cowsay | terminal
```

**Dagger CLI:**
```bash
dagger -m github.com/dagger/dagger/modules/wolfi@v0.16.2 call \
  container --packages="cowsay" \
  terminal
```
