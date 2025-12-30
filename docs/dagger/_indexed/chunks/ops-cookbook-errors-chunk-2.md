---
doc_id: ops/cookbook/errors
chunk_id: ops/cookbook/errors#chunk-2
heading_path: ["errors", "Terminate gracefully"]
chunk_type: code
tokens: 322
summary: "The following Dagger Function demonstrates how to handle errors in a workflow."
---
The following Dagger Function demonstrates how to handle errors in a workflow.

### Go

```go
package main

import (
	"context"
	"errors"
	"fmt"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Generate an error
func (m *MyModule) Test(ctx context.Context) (string, error) {
	out, err := dag.
		Container().
		From("alpine").
		// ERROR: cat: read error: Is a directory
		WithExec([]string{"cat", "/"}).
		Stdout(ctx)

	var e *dagger.ExecError
	if errors.As(err, &e) {
		return fmt.Sprintf("Test pipeline failure: %s", e.Stderr), nil
	} else if err != nil {
		return "", err
	}

	return out, nil
}
```

### Python

```python
from dagger import DaggerError, dag, function, object_type

@object_type
class MyModule:
    @function
    async def test(self) -> str:
        """Generate an error"""
        try:
            return await (
                dag.container()
                .from_("alpine")
                # ERROR: cat: read error: Is a directory
                .with_exec(["cat", "/"])
                .stdout()
            )
        except DaggerError as e:
            # DaggerError is the base class for all errors raised by dagger
            return "Test pipeline failure: " + e.stderr
```

### TypeScript

```typescript
import { dag, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Generate an error
   */
  @func()
  async test(): Promise<string> {
    try {
      return await dag
        .container()
        .from("alpine")
        // ERROR: cat: read error: Is a directory
        .withExec(["cat", "/"])
        .stdout()
    } catch (e) {
      return `Test pipeline failure: ${e.stderr}`
    }
  }
}
```

### Example

Execute a Dagger Function which creates a container and runs a command in it. If the command fails, the error is captured and the Dagger Function is gracefully terminated with a custom error message.

```bash
dagger call test
```
