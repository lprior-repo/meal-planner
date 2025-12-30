---
doc_id: concept/cookbook/containers
chunk_id: concept/cookbook/containers#chunk-4
heading_path: ["containers", "Set environment variables in a container"]
chunk_type: code
tokens: 190
summary: "The following Dagger Function demonstrates how to set a single environment variable in a container."
---
The following Dagger Function demonstrates how to set a single environment variable in a container.

### Go

```go
package main

import "context"

type MyModule struct{}

// Set a single environment variable in a container
func (m *MyModule) SetEnvVar(ctx context.Context) (string, error) {
	return dag.Container().
		From("alpine").
		WithEnvVariable("ENV_VAR", "VALUE").
		WithExec([]string{"env"}).
		Stdout(ctx)
}
```

### Python

```python
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    async def set_env_var(self) -> str:
        """Set a single environment variable in a container"""
        return await (
            dag.container()
            .from_("alpine")
            .with_env_variable("ENV_VAR", "VALUE")
            .with_exec(["env"])
            .stdout()
        )
```

### TypeScript

```typescript
import { dag, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Set a single environment variable in a container
   */
  @func()
  async setEnvVar(): Promise<string> {
    return await dag
      .container()
      .from("alpine")
      .withEnvVariable("ENV_VAR", "VALUE")
      .withExec(["env"])
      .stdout()
  }
}
```

### Example

Set a single environment variable in a container:

```bash
dagger call set-env-var
```
