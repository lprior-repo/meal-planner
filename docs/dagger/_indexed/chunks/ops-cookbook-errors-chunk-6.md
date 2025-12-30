---
doc_id: ops/cookbook/errors
chunk_id: ops/cookbook/errors#chunk-6
heading_path: ["errors", "Debug workflows with the interactive terminal"]
chunk_type: code
tokens: 302
summary: "Dagger provides two features that can help greatly when trying to debug a workflow - opening an i..."
---
Dagger provides two features that can help greatly when trying to debug a workflow - opening an interactive terminal session at the failure point, or at explicit breakpoints throughout your workflow code. All context is available at the point of failure. Multiple terminals are supported in the same Dagger Function; they will open in sequence.

The following Dagger Function opens an interactive terminal session at different stages in a Dagger workflow to debug a container build.

### Go

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

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    def container(self) -> dagger.Container:
        return (
            dag.container()
            .from_("alpine:latest")
            .terminal()
            .with_exec(["sh", "-c", "echo hello world > /foo && cat /foo"])
            .terminal()
        )
```

### TypeScript

```typescript
import { dag, Container, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  @func()
  container(): Container {
    return dag
      .container()
      .from("alpine:latest")
      .terminal()
      .withExec(["sh", "-c", "echo hello world > /foo && cat /foo"])
      .terminal()
  }
}
```

### Example

Execute a Dagger Function to build a container, and open an interactive terminal at two different points in the build process. The interactive terminal enables you to inspect the container filesystem and environment "live", during the build process.

```bash
dagger call container
```
