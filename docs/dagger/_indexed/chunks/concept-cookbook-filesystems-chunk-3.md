---
doc_id: concept/cookbook/filesystems
chunk_id: concept/cookbook/filesystems#chunk-3
heading_path: ["filesystems", "Mount or copy a directory or remote repository to a container"]
chunk_type: code
tokens: 322
summary: "The following Dagger Function accepts a `Directory` argument, which could reference either a dire..."
---
The following Dagger Function accepts a `Directory` argument, which could reference either a directory from the local filesystem or from a remote Git repository. It mounts the specified directory to the `/src` path in a container and returns the modified container.

### Go

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
	// Source directory
	source *dagger.Directory,
) *dagger.Container {
	return dag.Container().
		From("alpine:latest").
		WithMountedDirectory("/src", source)
}
```

### Python

```python
from typing import Annotated

import dagger
from dagger import Doc, dag, function, object_type

@object_type
class MyModule:
    @function
    def mount_directory(
        self, source: Annotated[dagger.Directory, Doc("Source directory")]
    ) -> dagger.Container:
        """Return a container with a mounted directory"""
        return (
            dag.container()
            .from_("alpine:latest")
            .with_mounted_directory("/src", source)
        )
```

### TypeScript

```typescript
import { dag, Container, Directory, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Return a container with a mounted directory
   */
  @func()
  mountDirectory(
    /**
     * Source directory
     */
    source: Directory,
  ): Container {
    return dag
      .container()
      .from("alpine:latest")
      .withMountedDirectory("/src", source)
  }
}
```

> **Tip**: Besides helping with the final image size, mounts are more performant and resource-efficient. The rule of thumb should be to always use mounts where possible.

### Examples

Mount the `/myapp` host directory to `/src` in the container and return the modified container:

```bash
dagger call mount-directory --source=./myapp/
```

Mount the public `dagger/dagger` GitHub repository to `/src` in the container and return the modified container:

```bash
dagger call mount-directory --source=https://github.com/dagger/dagger#main
```
