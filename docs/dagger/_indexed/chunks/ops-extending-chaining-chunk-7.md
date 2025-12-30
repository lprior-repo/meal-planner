---
doc_id: ops/extending/chaining
chunk_id: ops/extending/chaining#chunk-7
heading_path: ["chaining", "Modify container filesystems"]
chunk_type: code
tokens: 169
summary: "Here is an example of modifying a container by adding the current directory from the host to the ..."
---
Here is an example of modifying a container by adding the current directory from the host to the container filesystem at `/src`, by chaining a call to the `Container.withDirectory()` method:

> **Warning:** The example below uploads the entire current directory to the container filesystem. This can take a significant amount of time with large directories. To reduce the time spent on upload, run this example from a directory containing only a few small files.

**System shell:**
```bash
dagger <<EOF
github.com/dagger/dagger/modules/wolfi@v0.16.2 |
  container |
  with-directory /src . |
  with-exec ls /src |
  stdout
EOF
```

**Dagger Shell:**
```
github.com/dagger/dagger/modules/wolfi@v0.16.2 |
  container |
  with-directory /src . |
  with-exec ls /src |
  stdout
```

**Dagger CLI:**
```bash
dagger -m github.com/dagger/dagger/modules/wolfi@v0.16.2 call \
  container \
  with-directory --path=/src --directory=. \
  with-exec --args="ls","/src" \
  stdout
```
