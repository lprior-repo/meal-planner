---
doc_id: ops/cookbook/builds
chunk_id: ops/cookbook/builds#chunk-2
heading_path: ["builds", "Perform a multi-stage build"]
chunk_type: code
tokens: 360
summary: "The following Dagger Function performs a multi-stage build."
---
The following Dagger Function performs a multi-stage build.

### Go

```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Build and publish Docker container
func (m *MyModule) Build(
	ctx context.Context,
	// source code location
	// can be local directory or remote Git repository
	src *dagger.Directory,
) (string, error) {
	// build app
	builder := dag.Container().
		From("golang:latest").
		WithDirectory("/src", src).
		WithWorkdir("/src").
		WithEnvVariable("CGO_ENABLED", "0").
		WithExec([]string{"go", "build", "-o", "myapp"})

	// publish binary on alpine base
	prodImage := dag.Container().
		From("alpine").
		WithFile("/bin/myapp", builder.File("/src/myapp")).
		WithEntrypoint([]string{"/bin/myapp"})

	// publish to ttl.sh registry
	addr, err := prodImage.Publish(ctx, "ttl.sh/myapp:latest")
	if err != nil {
		return "", err
	}

	return addr, nil
}
```

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    def build(self, src: dagger.Directory) -> str:
        """Build and publish Docker container"""
        # build app
        builder = (
            dag.container()
            .from_("golang:latest")
            .with_directory("/src", src)
            .with_workdir("/src")
            .with_env_variable("CGO_ENABLED", "0")
            .with_exec(["go", "build", "-o", "myapp"])
        )

        # publish binary on alpine base
        prod_image = (
            dag.container()
            .from_("alpine")
            .with_file("/bin/myapp", builder.file("/src/myapp"))
            .with_entrypoint(["/bin/myapp"])
        )

        # publish to ttl.sh registry
        addr = prod_image.publish("ttl.sh/myapp:latest")

        return addr
```

### TypeScript

```typescript
import { dag, Container, Directory, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Build and publish Docker container
   */
  @func()
  build(src: Directory): Promise<string> {
    // build app
    const builder = dag
      .container()
      .from("golang:latest")
      .withDirectory("/src", src)
      .withWorkdir("/src")
      .withEnvVariable("CGO_ENABLED", "0")
      .withExec(["go", "build", "-o", "myapp"])

    // publish binary on alpine base
    const prodImage = dag
      .container()
      .from("alpine")
      .withFile("/bin/myapp", builder.file("/src/myapp"))
      .withEntrypoint(["/bin/myapp"])

    // publish to ttl.sh registry
    const addr = prodImage.publish("ttl.sh/myapp:latest")

    return addr
  }
}
```

### Example

Perform a multi-stage build of the source code in the `golang/example/hello` repository and publish the resulting image:

```bash
dagger call build --src="https://github.com/golang/example#master:hello"
```
