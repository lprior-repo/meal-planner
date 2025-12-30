---
doc_id: concept/cookbook/containers
chunk_id: concept/cookbook/containers#chunk-2
heading_path: ["containers", "Publish a container image to a private registry"]
chunk_type: code
tokens: 372
summary: "The following Dagger Function publishes a just-in-time container image to a private registry."
---
The following Dagger Function publishes a just-in-time container image to a private registry.

### Go

```go
package main

import (
	"context"
	"fmt"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Publish a container image to a private registry
func (m *MyModule) Publish(
	ctx context.Context,
	// Registry address
	registry string,
	// Registry username
	username string,
	// Registry password
	password *dagger.Secret,
) (string, error) {
	return dag.Container().
		From("nginx:1.23-alpine").
		WithNewFile(
			"/usr/share/nginx/html/index.html",
			"Hello from Dagger!",
			dagger.ContainerWithNewFileOpts{Permissions: 0o400},
		).
		WithRegistryAuth(registry, username, password).
		Publish(ctx, fmt.Sprintf("%s/%s/my-nginx", registry, username))
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
    async def publish(
        self,
        registry: Annotated[str, Doc("Registry address")],
        username: Annotated[str, Doc("Registry username")],
        password: Annotated[dagger.Secret, Doc("Registry password")],
    ) -> str:
        """Publish a container image to a private registry"""
        return await (
            dag.container()
            .from_("nginx:1.23-alpine")
            .with_new_file(
                "/usr/share/nginx/html/index.html",
                "Hello from Dagger!",
                permissions=0o400,
            )
            .with_registry_auth(registry, username, password)
            .publish(f"{registry}/{username}/my-nginx")
        )
```

### TypeScript

```typescript
import { dag, Secret, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Publish a container image to a private registry
   */
  @func()
  async publish(
    /**
     * Registry address
     */
    registry: string,
    /**
     * Registry username
     */
    username: string,
    /**
     * Registry password
     */
    password: Secret,
  ): Promise<string> {
    return await dag
      .container()
      .from("nginx:1.23-alpine")
      .withNewFile("/usr/share/nginx/html/index.html", "Hello from Dagger!", {
        permissions: 0o400,
      })
      .withRegistryAuth(registry, username, password)
      .publish(`${registry}/${username}/my-nginx`)
  }
}
```

### Examples

Publish a just-in-time container image to Docker Hub, using the account username `user` and the password set in the `PASSWORD` environment variable:

```bash
dagger call publish --registry=docker.io --username=user --password=env://PASSWORD
```

Publish a just-in-time container image to GitHub Container Registry, using the account username `user` and the GitHub personal access token set in the `PASSWORD` environment variable:

```bash
dagger call publish --registry=ghcr.io --username=user --password=env://PASSWORD
```
