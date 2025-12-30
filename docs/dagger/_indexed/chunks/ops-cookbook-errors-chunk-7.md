---
doc_id: ops/cookbook/errors
chunk_id: ops/cookbook/errors#chunk-7
heading_path: ["errors", "Inspect directories and files"]
chunk_type: code
tokens: 200
summary: "The following Dagger Function clones Dagger's GitHub repository and opens an interactive terminal..."
---
The following Dagger Function clones Dagger's GitHub repository and opens an interactive terminal session to inspect it. Under the hood, this creates a new container (defaults to `alpine`) and starts a shell, mounting the repository directory inside.

### Go

```go
package main

import (
  "context"
)

type MyModule struct{}

func (m *MyModule) SimpleDirectory(ctx context.Context) (string, error) {
	return dag.
		Git("https://github.com/dagger/dagger.git").
		Head().
		Tree().
		Terminal().
		File("README.md").
		Contents(ctx)
}
```

### Python

```python
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    async def simple_directory(self) -> str:
        return await (
            dag.git("https://github.com/dagger/dagger.git")
            .head()
            .tree()
            .terminal()
            .file("README.md")
            .contents()
        )
```

### TypeScript

```typescript
import { dag, Container, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  @func()
  async simpleDirectory(): Promise<string> {
    return await dag
      .git("https://github.com/dagger/dagger.git")
      .head()
      .tree()
      .terminal()
      .file("README.md")
      .contents()
  }
}
```

### Example

Execute a Dagger Function to clone Dagger's GitHub repository and open a terminal session in the repository directory:

```bash
dagger call simple-directory
```
