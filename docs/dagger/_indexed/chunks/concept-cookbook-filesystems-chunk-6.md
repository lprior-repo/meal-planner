---
doc_id: concept/cookbook/filesystems
chunk_id: concept/cookbook/filesystems#chunk-6
heading_path: ["filesystems", "Set a module-wide default path"]
chunk_type: code
tokens: 308
summary: "The following Dagger module uses a constructor to set a module-wide `Directory` argument and poin..."
---
The following Dagger module uses a constructor to set a module-wide `Directory` argument and point it to a default path on the host. This eliminates the need to pass a common `Directory` argument individually to each Dagger Function in the module. If required, the default path can be overridden by specifying a different `Directory` value at call time.

### Go

```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct {
	Source *dagger.Directory
}

func New(
	// +defaultPath="."
	source *dagger.Directory,
) *MyModule {
	return &MyModule{
		Source: source,
	}
}

func (m *MyModule) Foo(ctx context.Context) ([]string, error) {
	return dag.Container().
		From("alpine:latest").
		WithMountedDirectory("/app", m.Source).
		Directory("/app").
		Entries(ctx)
}
```

### Python

```python
from typing import Annotated

import dagger
from dagger import DefaultPath, dag, function, object_type

@object_type
class MyModule:
    source: Annotated[dagger.Directory, DefaultPath(".")]

    @function
    async def foo(self) -> str:
        return await (
            dag.container()
            .from_("alpine:latest")
            .with_mounted_directory("/app", self.source)
            .directory("/app")
            .entries()
        )
```

### TypeScript

```typescript
import { dag, Directory, object, func, argument } from "@dagger.io/dagger"

@object()
class MyModule {
  source: Directory

  constructor(
    @argument({ defaultPath: "." })
    source: Directory,
  ) {
    this.source = source
  }

  @func()
  async foo(): Promise<string[]> {
    return await dag
      .container()
      .from("alpine:latest")
      .withMountedDirectory("/app", this.source)
      .directory("/app")
      .entries()
  }
}
```

### Examples

Call the Dagger Function without arguments. The default path (the current directory `.`) is used:

```bash
dagger call foo
```

Call the Dagger Function with a constructor argument. The specified directory (`/src/myapp`) is used:

```bash
dagger call --source=/src/myapp foo
```
