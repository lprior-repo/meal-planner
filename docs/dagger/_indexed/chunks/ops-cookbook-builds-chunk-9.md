---
doc_id: ops/cookbook/builds
chunk_id: ops/cookbook/builds#chunk-9
heading_path: ["builds", "Invalidate cache"]
chunk_type: code
tokens: 364
summary: "The following function demonstrates how to invalidate the Dagger layer cache and force execution ..."
---
The following function demonstrates how to invalidate the Dagger layer cache and force execution of subsequent workflow steps, by introducing a volatile time variable at a specific point in the Dagger workflow.

> **Note**: This is a temporary workaround until cache invalidation support is officially added to Dagger. Changes in mounted cache volumes or secrets do not invalidate the Dagger layer cache.

### Go

```go
package main

import (
	"context"
	"time"
)

type MyModule struct{}

// Run a build with cache invalidation
func (m *MyModule) Build(
	ctx context.Context,
) (string, error) {
	output, err := dag.Container().
		From("alpine").
		// comment out the line below to see the cached date output
		WithEnvVariable("CACHEBUSTER", time.Now().String()).
		WithExec([]string{"date"}).
		Stdout(ctx)
	if err != nil {
		return "", err
	}

	return output, nil
}
```

### Python

```python
from datetime import datetime

from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    async def build(self) -> str:
        """Run a build with cache invalidation"""
        output = (
            dag.container()
            .from_("alpine")
            # comment out the line below to see the cached date output
            .with_env_variable("CACHEBUSTER", str(datetime.now()))
            .with_exec(["date"])
            .stdout()
        )

        return await output
```

### TypeScript

```typescript
import { dag, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Run a build with cache invalidation
   */
  @func()
  async build(): Promise<string> {
    const ref = await dag
      .container()
      .from("alpine")
      // comment out the line below to see the cached date output
      .withEnvVariable("CACHEBUSTER", Date.now().toString())
      .withExec(["date"])
      .stdout()
    return ref
  }
}
```

### Example

Print the date and time, invalidating the cache on each run. However, if the `CACHEBUSTER` environment variable is removed, the same value (the date and time on the first run) is printed on every run.

```bash
dagger call build
```
