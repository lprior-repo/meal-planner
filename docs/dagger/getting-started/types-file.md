# File

The `File` type represents a single file.

## Common operations

| Field | Description |
|-------|-------------|
| `contents` | Returns the contents of the file |
| `export` | Writes the file to a path on the host |

> **Tip:** Default paths are also available for `File` arguments.

## Examples

### Mount or copy a local or remote file to a container

The following Dagger Function accepts a `File` argument, which could reference either a file from the local filesystem or from a remote Git repository.

**Go:**
```go
package main

import (
	"context"
	"fmt"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Return a container with a mounted file
func (m *MyModule) MountFile(
	ctx context.Context,
	// Source file
	f *dagger.File,
) *dagger.Container {
	name, _ := f.Name(ctx)
	return dag.Container().
		From("alpine:latest").
		WithMountedFile(fmt.Sprintf("/src/%s", name), f)
}
```

**Python:**
```python
from typing import Annotated
import dagger
from dagger import Doc, dag, function, object_type

@object_type
class MyModule:
    @function
    async def copy_file(
        self,
        f: Annotated[dagger.File, Doc("Source file")],
    ) -> dagger.Container:
        """Return a container with a mounted file"""
        name = await f.name()
        return (
            dag.container().from_("alpine:latest").with_mounted_file(f"/src/{name}", f)
        )
```

**TypeScript:**
```typescript
import { dag, Container, File, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Return a container with a mounted file
   */
  @func()
  async copyFile(
    /**
     * Source file
     */
    f: File,
  ): Promise<Container> {
    const name = await f.name()
    return dag
      .container()
      .from("alpine:latest")
      .withMountedFile(`/src/${name}`, f)
  }
}
```

**Examples:**
```bash
# Mount a local file
dagger call mount-file --f=/home/admin/archives.zip

# Mount from GitHub
dagger call mount-file --f=https://github.com/dagger/dagger.git#main:README.md

# Copy a local file
dagger call copy-file --f=/home/admin/archives.zip

# Copy from GitHub
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
# Export the directory
dagger call get-dir export --path=/home/admin/export

# Export the file
dagger call get-file export --path=/home/admin/myfile
```
