---
doc_id: ops/extending/chaining
chunk_id: ops/extending/chaining#chunk-4
heading_path: ["chaining", "Export directories, files and containers"]
chunk_type: code
tokens: 218
summary: "When a host directory or file is copied or mounted to a container's filesystem, modifications mad..."
---
When a host directory or file is copied or mounted to a container's filesystem, modifications made to it in the container do not automatically transfer back to the host. Data flows only one way between Dagger operations, because they are connected in a DAG. To transfer modifications back to the local host, you must explicitly export the directory or file back to the host filesystem.

Just-in-time artifacts such as containers, directories and files can be exported to the host filesystem from the Dagger Function that produced them using the `export` function. The destination path on the host is specified using the `--path` argument.

Here is an example of exporting the build directory returned by a Go builder Dagger Function to the `./my-build` directory on the host:

**System shell:**
```bash
dagger <<EOF
github.com/kpenfound/dagger-modules/golang@v0.2.1 |
  build ./cmd/dagger --source=https://github.com/dagger/dagger |
  export ./my-build
EOF
```

**Dagger Shell:**
```
github.com/kpenfound/dagger-modules/golang@v0.2.1 |
  build ./cmd/dagger --source=https://github.com/dagger/dagger |
  export ./my-build
```

**Dagger CLI:**
```bash
dagger -m github.com/kpenfound/dagger-modules/golang@v0.2.1 call \
  build --source=https://github.com/dagger/dagger --args=./cmd/dagger \
  export --path=./my-build
```
