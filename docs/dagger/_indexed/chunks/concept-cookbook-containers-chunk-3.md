---
doc_id: concept/cookbook/containers
chunk_id: concept/cookbook/containers#chunk-3
heading_path: ["containers", "Export a container image to the host"]
chunk_type: code
tokens: 213
summary: "The following Dagger Function returns a just-in-time container."
---
The following Dagger Function returns a just-in-time container. This can be exported to the host as an OCI tarball.

### Go

```go
package main

import "dagger/my-module/internal/dagger"

type MyModule struct{}

// Return a container
func (m *MyModule) Base() *dagger.Container {
	return dag.Container().
		From("alpine:latest").
		WithExec([]string{"mkdir", "/src"}).
		WithExec([]string{"touch", "/src/foo", "/src/bar"})
}
```

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    def base(self) -> dagger.Container:
        """Return a container"""
        return (
            dag.container()
            .from_("alpine:latest")
            .with_exec(["mkdir", "/src"])
            .with_exec(["touch", "/src/foo", "/src/bar"])
        )
```

### TypeScript

```typescript
import { dag, Container, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Return a container
   */
  @func()
  base(): Container {
    return dag
      .container()
      .from("alpine:latest")
      .withExec(["mkdir", "/src"])
      .withExec(["touch", "/src/foo", "/src/bar"])
  }
}
```

### Examples

Load the container image returned by the Dagger Function into Docker:

```bash
dagger call base export-image --name myimage
```

Load the container image returned by the Dagger Function as a tarball to the host filesystem:

```bash
dagger call base export --path=/home/admin/mycontainer.tgz
```
