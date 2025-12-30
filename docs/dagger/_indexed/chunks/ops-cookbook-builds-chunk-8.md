---
doc_id: ops/cookbook/builds
chunk_id: ops/cookbook/builds#chunk-8
heading_path: ["builds", "Cache application dependencies"]
chunk_type: code
tokens: 307
summary: "The following Dagger Function uses a cache volume for application dependencies."
---
The following Dagger Function uses a cache volume for application dependencies. This enables Dagger to reuse the contents of the cache across Dagger Function runs and reduce execution time.

### Go

```go
package main

import "dagger/my-module/internal/dagger"

type MyModule struct{}

// Build an application using cached dependencies
func (m *MyModule) Build(
	// Source code location
	source *dagger.Directory,
) *dagger.Container {
	return dag.Container().
		From("golang:1.21").
		WithDirectory("/src", source).
		WithWorkdir("/src").
		WithMountedCache("/go/pkg/mod", dag.CacheVolume("go-mod-121")).
		WithEnvVariable("GOMODCACHE", "/go/pkg/mod").
		WithMountedCache("/go/build-cache", dag.CacheVolume("go-build-121")).
		WithEnvVariable("GOCACHE", "/go/build-cache").
		WithExec([]string{"go", "build"})
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
    def build(
        self, source: Annotated[dagger.Directory, Doc("Source code location")]
    ) -> dagger.Container:
        """Build an application using cached dependencies"""
        return (
            dag.container()
            .from_("python:3.11")
            .with_directory("/src", source)
            .with_workdir("/src")
            # if using pip
            .with_mounted_cache("/root/.cache/pip", dag.cache_volume("pip_cache"))
            .with_exec(["pip", "install", "-r", "requirements.txt"])
            # if using poetry
            .with_mounted_cache(
                "/root/.cache/pypoetry", dag.cache_volume("poetry_cache")
            )
            .with_exec(
                [
                    "pip",
                    "install",
                    "--user",
                    "poetry==1.5.1",
                    "poetry-dynamic-versioning==0.23.0",
                ]
            )
            # No root first uses dependencies but not the project itself
            .with_exec(["poetry", "install", "--no-root", "--no-interaction"])
            .with_exec(["poetry", "install", "--no-interaction", "--only-root"])
        )
```

### TypeScript

```typescript
import { dag, Container, Directory, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Build an application using cached dependencies
   */
  @func()
  build(
    /**
     * Source code location
     */
    source: Directory,
  ): Container {
    return dag
      .container()
      .from("node:21")
      .withDirectory("/src", source)
      .withWorkdir("/src")
      .withMountedCache("/root/.npm", dag.cacheVolume("node-21"))
      .withExec(["npm", "install"])
  }
}
```

### Example

Build an application using cached dependencies:

```bash
dagger call build --source=.
```
