---
doc_id: concept/getting-started/types-directory
chunk_id: concept/getting-started/types-directory#chunk-4
heading_path: ["types-directory", "Filters"]
chunk_type: code
tokens: 229
summary: "When you pass a directory to a Dagger Function as argument, Dagger uploads everything in that dir..."
---
When you pass a directory to a Dagger Function as argument, Dagger uploads everything in that directory tree. For large monorepos or directories containing large-sized files, this can significantly slow down your Dagger Function. To mitigate this problem, Dagger lets you apply filters.

### Pre-call filtering

Pre-call filtering means that a directory is filtered before it's uploaded to the Dagger Engine. This is useful for large monorepos or large files.

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) Foo(
	ctx context.Context,
	// +ignore=["*", "!**/*.go", "!go.mod", "!go.sum"]
	source *dagger.Directory,
) (*dagger.Container, error) {
	return dag.
		Container().
		From("alpine:latest").
		WithDirectory("/src", source).
		Sync(ctx)
}
```

### Post-call filtering

Post-call filtering means that a directory is filtered after it's uploaded to the Dagger Engine.

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) Foo(
	ctx context.Context,
	source *dagger.Directory,
) *dagger.Container {
	builder := dag.
		Container().
		From("golang:latest").
		WithDirectory("/src", source, dagger.ContainerWithDirectoryOpts{Exclude: []string{"*.git", "internal"}}).
		WithWorkdir("/src/hello").
		WithExec([]string{"go", "build", "-o", "hello.bin", "."})

	return dag.
		Container().
		From("alpine:latest").
		WithDirectory("/app", builder.Directory("/src/hello"), dagger.ContainerWithDirectoryOpts{Include: []string{"hello.bin"}}).
		WithEntrypoint([]string{"/app/hello.bin"})
}
```
