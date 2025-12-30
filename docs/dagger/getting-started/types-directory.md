# Directory

Dagger Functions do not have access to the filesystem of the host you invoke the Dagger Function from. Instead, host files and directories need to be explicitly passed as command-line arguments to Dagger Functions.

There are two important reasons for this:

- **Reproducibility**: By providing a call-time mechanism to define and control the files available to a Dagger Function, Dagger guards against creating hidden dependencies on ambient properties of the host filesystem.
- **Security**: By forcing you to explicitly specify which host files and directories a Dagger Function "sees" on every call, Dagger ensures that you're always 100% in control.

The `Directory` type represents the state of a directory. This could be either a local directory path or a remote Git reference.

## Common operations

| Field | Description |
|-------|-------------|
| `dockerBuild` | Builds a new Docker container from the directory |
| `entries` | Returns a list of files and directories in the directory |
| `export` | Writes the contents of the directory to a path on the host |
| `file` | Returns a file at the given path as a `File` |
| `withFile` / `withFiles` | Returns the directory plus the file(s) copied to the given path |

## Default paths

It is possible to assign a default path for a `Directory` or `File` argument in a Dagger Function. Dagger will automatically use this default path when no value is specified.

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) ReadDir(
	ctx context.Context,
	// +defaultPath="/"
	source *dagger.Directory,
) ([]string, error) {
	return source.Entries(ctx)
}
```

**Python:**
```python
from typing import Annotated
import dagger
from dagger import DefaultPath, function, object_type

@object_type
class MyModule:
    @function
    async def read_dir(
        self,
        source: Annotated[dagger.Directory, DefaultPath("/")],
    ) -> list[str]:
        return await source.entries()
```

**TypeScript:**
```typescript
import { Directory, File, argument, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  @func()
  async readDir(
    @argument({ defaultPath: "/" }) source: Directory,
  ): Promise<string[]> {
    return await source.entries()
  }
}
```

## Filters

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

## Mounts

When working with directories and files, you can choose whether to copy or mount them:

- `Container.withDirectory()` - returns a container plus a directory written at the given path
- `Container.withFile()` - returns a container plus a file written at the given path
- `Container.withMountedDirectory()` - returns a container plus a directory mounted at the given path
- `Container.withMountedFile()` - returns a container plus a file mounted at the given path

Mounts only take effect within your workflow invocation; they are not copied to the final image. Mounts are more performant and resource-efficient.

## Examples

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
# Export the directory
dagger call get-dir export --path=/home/admin/export

# Export the file
dagger call get-file export --path=/home/admin/myfile
```
