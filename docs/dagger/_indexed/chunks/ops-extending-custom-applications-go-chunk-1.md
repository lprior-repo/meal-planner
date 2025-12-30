---
doc_id: ops/extending/custom-applications-go
chunk_id: ops/extending/custom-applications-go#chunk-1
heading_path: ["custom-applications-go"]
chunk_type: mixed
tokens: 173
summary: "> **Context**: > **Note:** The Dagger Go SDK requires [Go 1."
---
# Go Custom Application

> **Context**: > **Note:** The Dagger Go SDK requires [Go 1.22 or later](https://go.dev/doc/install).


> **Note:** The Dagger Go SDK requires [Go 1.22 or later](https://go.dev/doc/install).

From an existing Go module, install the Dagger Go SDK using the commands below:

```bash
go get dagger.io/dagger@latest
```

After importing `dagger.io/dagger` in your Go module code, run the following command to update `go.sum`:

```bash
go mod tidy
```

This example demonstrates how to build a Go application for multiple architectures and Go versions using the Go SDK.

Clone an example project and create a new Go module in the project directory:

```bash
git clone https://go.googlesource.com/example
cd example/hello
mkdir multibuild && cd multibuild
go mod init multibuild
```

Create a new file in the `multibuild` directory named `main.go` and add the following code to it:
