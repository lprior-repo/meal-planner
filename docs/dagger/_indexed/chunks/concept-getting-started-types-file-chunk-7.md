---
doc_id: concept/getting-started/types-file
chunk_id: concept/getting-started/types-file#chunk-7
heading_path: ["types-file", "Copy from GitHub"]
chunk_type: mixed
tokens: 217
summary: "dagger call copy-file --f=https://github."
---
dagger call copy-file --f=https://github.com/dagger/dagger.git#main:README.md
```

### Request a file over HTTP/HTTPS and save it in a container

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) ReadFileHttp(
	ctx context.Context,
	url string,
) *dagger.Container {
	file := dag.HTTP(url)
	return dag.Container().
		From("alpine:latest").
		WithFile("/src/myfile", file)
}
```

**Example:**
```bash
dagger call read-file-http --url=https://raw.githubusercontent.com/dagger/dagger/refs/heads/main/README.md
```

### Export a directory or file to the host

> **Note:** When a host directory or file is copied or mounted to a container's filesystem, modifications made to it in the container do not automatically transfer back to the host. To transfer modifications back, you must explicitly export the directory or file.

**Go:**
```go
package main

import "dagger/my-module/internal/dagger"

type MyModule struct{}

// Return a directory
func (m *MyModule) GetDir() *dagger.Directory {
	return m.Base().Directory("/src")
}

// Return a file
func (m *MyModule) GetFile() *dagger.File {
	return m.Base().File("/src/foo")
}

// Return a base container
func (m *MyModule) Base() *dagger.Container {
	return dag.Container().
		From("alpine:latest").
		WithExec([]string{"mkdir", "/src"}).
		WithExec([]string{"touch", "/src/foo", "/src/bar"})
}
```

**Examples:**
```bash
