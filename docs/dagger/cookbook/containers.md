# Container Images

Dagger allows you to build, publish, and export container images, also known as just-in-time artifacts, as part of your Dagger Functions. This section shows you how to work with container images using Dagger with practical examples.

## Publish a container image to a private registry

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

## Export a container image to the host

The following Dagger Function returns a just-in-time container. This can be exported to the host as an OCI tarball.

### Go

```go
package main

import "dagger/my-module/internal/dagger"

type MyModule struct{}

// Return a container
func (m *MyModule) Base() *dagger.Container {
	return dag.Container().
		From("alpine:latest").
		WithExec([]string{"mkdir", "/src"}).
		WithExec([]string{"touch", "/src/foo", "/src/bar"})
}
```

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    def base(self) -> dagger.Container:
        """Return a container"""
        return (
            dag.container()
            .from_("alpine:latest")
            .with_exec(["mkdir", "/src"])
            .with_exec(["touch", "/src/foo", "/src/bar"])
        )
```

### TypeScript

```typescript
import { dag, Container, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Return a container
   */
  @func()
  base(): Container {
    return dag
      .container()
      .from("alpine:latest")
      .withExec(["mkdir", "/src"])
      .withExec(["touch", "/src/foo", "/src/bar"])
  }
}
```

### Examples

Load the container image returned by the Dagger Function into Docker:

```bash
dagger call base export-image --name myimage
```

Load the container image returned by the Dagger Function as a tarball to the host filesystem:

```bash
dagger call base export --path=/home/admin/mycontainer.tgz
```

## Set environment variables in a container

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
