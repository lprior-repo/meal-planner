---
doc_id: ops/getting-started/types-container
chunk_id: ops/getting-started/types-container#chunk-3
heading_path: ["types-container", "Examples"]
chunk_type: code
tokens: 372
summary: "The following Dagger Function builds an image from a Dockerfile."
---
### Build image from Dockerfile

The following Dagger Function builds an image from a Dockerfile.

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Build and publish image from existing Dockerfile
func (m *MyModule) Build(
	ctx context.Context,
	// location of directory containing Dockerfile
	src *dagger.Directory,
) (string, error) {
	ref, err := src.
		DockerBuild().
		Publish(ctx, "ttl.sh/hello-dagger")
	if err != nil {
		return "", err
	}
	return ref, nil
}
```

**Example:**
```bash
dagger call build --src="https://github.com/dockersamples/python-flask-redis"
```

### Debug workflows with the interactive terminal

Dagger provides two features that can help with debugging - opening an interactive terminal session at the failure point, or at explicit breakpoints.

**Go:**
```go
package main

import (
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) Container() *dagger.Container {
	return dag.Container().
		From("alpine:latest").
		Terminal().
		WithExec([]string{"sh", "-c", "echo hello world > /foo && cat /foo"}).
		Terminal()
}
```

### Add OCI annotations to image

**Go:**
```go
package main

import (
	"context"
	"fmt"
	"math"
	"math/rand/v2"
)

type MyModule struct{}

// Build and publish image with OCI annotations
func (m *MyModule) Build(ctx context.Context) (string, error) {
	address, err := dag.Container().
		From("alpine:latest").
		WithExec([]string{"apk", "add", "git"}).
		WithWorkdir("/src").
		WithExec([]string{"git", "clone", "https://github.com/dagger/dagger", "."}).
		WithAnnotation("org.opencontainers.image.authors", "John Doe").
		WithAnnotation("org.opencontainers.image.title", "Dagger source image viewer").
		Publish(ctx, fmt.Sprintf("ttl.sh/custom-image-%.0f", math.Floor(rand.Float64()*10000000)))
	if err != nil {
		return "", err
	}
	return address, nil
}
```

### Add OCI labels to image

**Go:**
```go
package main

import (
	"context"
	"time"
)

type MyModule struct{}

// Build and publish image with OCI labels
func (m *MyModule) Build(
	ctx context.Context,
) (string, error) {
	ref, err := dag.Container().
		From("alpine").
		WithLabel("org.opencontainers.image.title", "my-alpine").
		WithLabel("org.opencontainers.image.version", "1.0").
		WithLabel("org.opencontainers.image.created", time.Now().String()).
		WithLabel("org.opencontainers.image.source", "https://github.com/alpinelinux/docker-alpine").
		WithLabel("org.opencontainers.image.licenses", "MIT").
		Publish(ctx, "ttl.sh/my-alpine")
	if err != nil {
		return "", err
	}
	return ref, nil
}
```
