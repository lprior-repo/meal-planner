---
doc_id: concept/getting-started/concepts
chunk_id: concept/getting-started/concepts#chunk-4
heading_path: ["concepts", "Chaining"]
chunk_type: mixed
tokens: 318
summary: "Each of Dagger's types comes with functions of its own, which can be used to interact with the co..."
---
Each of Dagger's types comes with functions of its own, which can be used to interact with the corresponding object.

When calling a Dagger function that returns a type, the Dagger API lets you follow up by calling one of that type's functions, which itself can return another type, and so on. This is called "function chaining", and is a core feature of Dagger.

For example, if a Dagger function returns a `Directory`, the caller can continue the chain by calling a function from the `Directory` type to export it to the local filesystem, modify it, mount it into a container, and so on.

Here is an example that chains multiple function calls into a workflow that builds the Dagger CLI from source and exports it to the Dagger host:

**System shell:**
```bash
dagger <<EOF
container |
  from golang:latest |
  with-directory /src https://github.com/dagger/dagger#main |
  with-workdir /src/cmd/dagger |
  with-exec -- go build -o dagger . |
  file ./dagger |
  export ./dagger.bin
EOF
```

In this workflow:
- `from` returns a `golang` container image as a `Container` type
- `with-directory` adds the Dagger open source repository to the container image filesystem
- `with-workdir` sets the working directory to the Dagger repository
- `with-exec` compiles the Dagger CLI
- `file` returns the built binary as a `File` type
- `export` exports the binary artifact to the Dagger host as `./dagger.bin`

Functions can be chained with the CLI, or programmatically in a [custom Dagger function](./concept-extending-functions.md) using a Dagger SDK.
