---
doc_id: ops/cookbook/builds
chunk_id: ops/cookbook/builds#chunk-7
heading_path: ["builds", "Build image from Dockerfile"]
chunk_type: code
tokens: 260
summary: "The following Dagger Function builds an image from a Dockerfile."
---
The following Dagger Function builds an image from a Dockerfile.

### Go

```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Build and publish image from existing Dockerfile
func (m *MyModule) Build(
	ctx context.Context,
	// location of directory containing Dockerfile
	src *dagger.Directory,
) (string, error) {
	ref, err := src.
		DockerBuild(). // build from Dockerfile
		Publish(ctx, "ttl.sh/hello-dagger")
	if err != nil {
		return "", err
	}

	return ref, nil
}
```

### Python

```python
from typing import Annotated

import dagger
from dagger import Doc, function, object_type

@object_type
class MyModule:
    @function
    async def build(
        self,
        src: Annotated[
            dagger.Directory,
            Doc("location of directory containing Dockerfile"),
        ],
    ) -> str:
        """Build and publish image from existing Dockerfile"""
        ref = src.docker_build().publish("ttl.sh/hello-dagger")  # build from Dockerfile
        return await ref
```

### TypeScript

```typescript
import { dag, Directory, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Build and publish image from existing Dockerfile
   * @param src location of directory containing Dockerfile
   */
  @func()
  async build(src: Directory): Promise<string> {
    const ref = await src
      .dockerBuild() // build from Dockerfile
      .publish("ttl.sh/hello-dagger")
    return ref
  }
}
```

### Example

Build and publish an image from an existing Dockerfile

```bash
dagger call build --src="https://github.com/dockersamples/python-flask-redis"
```
