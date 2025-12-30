---
doc_id: concept/getting-started/types-directory
chunk_id: concept/getting-started/types-directory#chunk-6
heading_path: ["types-directory", "Examples"]
chunk_type: code
tokens: 216
summary: "**Go:**
```go
package main

import (
	\"context\"
	\"dagger/my-module/internal/dagger\"
)

type MyMod..."
---
### Clone a remote Git repository into a container

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) Clone(ctx context.Context, repository string, ref string) *dagger.Container {
	d := dag.Git(repository).Ref(ref).Tree()
	return dag.Container().
		From("alpine:latest").
		WithDirectory("/src", d).
		WithWorkdir("/src")
}
```

**Example:**
```bash
dagger call clone --repository=https://github.com/dagger/dagger --ref=196f232a4d6b2d1d3db5f5e040cf20b6a76a76c5
```

### Mount or copy a directory to a container

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Return a container with a mounted directory
func (m *MyModule) MountDirectory(
	ctx context.Context,
	source *dagger.Directory,
) *dagger.Container {
	return dag.Container().
		From("alpine:latest").
		WithMountedDirectory("/src", source)
}
```

### Export a directory or file to the host

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

**Export examples:**
```bash
