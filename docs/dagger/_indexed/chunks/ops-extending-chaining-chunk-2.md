---
doc_id: ops/extending/chaining
chunk_id: ops/extending/chaining#chunk-2
heading_path: ["chaining", "Execute commands in containers"]
chunk_type: code
tokens: 150
summary: "The Dagger CLI can add follow-up processing to a just-in-time container, essentially enabling you..."
---
The Dagger CLI can add follow-up processing to a just-in-time container, essentially enabling you to continue the workflow directly from the command-line. `Container` objects expose a `withExec()` API method, which lets you execute a command in the corresponding container.

Here is an example of chaining a `Container.withExec()` call to a container returned by a Wolfi container builder Dagger Function, to execute a command that displays the contents of the `/etc/` directory:

**System shell:**
```bash
dagger <<EOF
github.com/dagger/dagger/modules/wolfi@v0.16.2 |
  container |
  with-exec ls /etc/ |
  stdout
EOF
```

**Dagger Shell:**
```
github.com/dagger/dagger/modules/wolfi@v0.16.2 |
  container |
  with-exec ls /etc/ |
  stdout
```

**Dagger CLI:**
```bash
dagger -m github.com/dagger/dagger/modules/wolfi@v0.16.2 call \
  container \
  with-exec --args="ls","/etc/" \
  stdout
```
