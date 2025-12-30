# Container

The `Container` type represents the state of an OCI-compatible container. This `Container` object is not merely a string referencing an image on a remote registry. It is the actual state of a container, managed by the Dagger Engine, and passed to a Dagger Function's code as if it were just another variable.

## Common operations

| Field | Description |
|-------|-------------|
| `from` | Initializes the container from a specified base image |
| `asService` | Turns the container into a `Service` |
| `asTarball` | Returns a serialized tarball of the container as a `File` |
| `export` / `import` | Writes / reads the container as an OCI tarball to / from a file path on the host |
| `publish` | Publishes the container image to a registry |
| `stdout` / `stderr` | Returns the output / error stream of the last executed command |
| `withDirectory` / `withMountedDirectory` | Returns the container plus a directory copied / mounted at the given path |
| `withEntrypoint` | Returns the container with a custom entrypoint command |
| `withExec` | Returns the container after executing a command inside it |
| `withFile` / `withMountedFile` | Returns the container plus a file copied / mounted at the given path |
| `withMountedCache` | Returns the container plus a cache volume mounted at the given path |
| `withRegistryAuth` | Returns the container with registry authentication configured |
| `withWorkdir` | Returns the container configured with a specific working directory |
| `withServiceBinding` | Returns the container with runtime dependency on another `Service` |
| `terminal` | Opens an interactive terminal for this container |

## Examples

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
