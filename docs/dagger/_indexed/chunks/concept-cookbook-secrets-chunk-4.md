---
doc_id: concept/cookbook/secrets
chunk_id: concept/cookbook/secrets#chunk-4
heading_path: ["secrets", "Use secret in Dockerfile build"]
chunk_type: code
tokens: 459
summary: "The following code listing demonstrates how to inject a secret into a Dockerfile build."
---
The following code listing demonstrates how to inject a secret into a Dockerfile build. The secret is automatically mounted in the build container at `/run/secrets/SECRET-ID`.

### Go

```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Build a Container from a Dockerfile
func (m *MyModule) Build(
	ctx context.Context,
	// The source code to build
	source *dagger.Directory,
	// The secret to use in the Dockerfile
	secret *dagger.Secret,
) (*dagger.Container, error) {
	// Ensure the Dagger secret's name matches what the Dockerfile
	// expects as the id for the secret mount.
	secretVal, err := secret.Plaintext(ctx)
	if err != nil {
		return nil, err
	}

	buildSecret := dag.SetSecret("gh-secret", secretVal)

	return source.
		DockerBuild(dagger.DirectoryDockerBuildOpts{
			Secrets: []*dagger.Secret{buildSecret},
		}), nil
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
    async def build(
        self,
        source: Annotated[dagger.Directory, Doc("The source code to build")],
        secret: Annotated[dagger.Secret, Doc("The secret to use in the Dockerfile")],
    ) -> dagger.Container:
        """Build a Container from a Dockerfile"""
        # Ensure the Dagger secret's name matches what the Dockerfile
        # expects as the id for the secret mount.
        build_secret = dag.set_secret("gh-secret", await secret.plaintext())
        return source.docker_build(secrets=[build_secret])
```

### TypeScript

```typescript
import { dag, object, func, Secret } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Build a Container from a Dockerfile
   */
  @func()
  async build(
    /**
     * The source code to build
     */
    source: Directory,
    /**
     * The secret to use in the Dockerfile
     */
    secret: Secret,
  ): Promise<Container> {
    // Ensure the Dagger secret's name matches what the Dockerfile
    // expects as the id for the secret mount.
    const buildSecret = dag.setSecret("gh-secret", await secret.plaintext())
    return source.dockerBuild({ secrets: [buildSecret] })
  }
}
```

The sample Dockerfile below demonstrates the process of mounting the secret using a secret filesystem mount type and using it in the Dockerfile build process:

```dockerfile
FROM alpine:3.17
RUN apk add curl
RUN --mount=type=secret,id=gh-secret \
    curl "https://api.github.com/repos/dagger/dagger/issues" \
        --header "Accept: application/vnd.github+json" \
        --header "Authorization: Bearer $(cat /run/secrets/gh-secret)"
```

### Dockerfile build with mounted secret

Build from a Dockerfile with a mounted secret from the host environment:

```bash
dagger call build --source=. --secret=env://GITHUB_API_TOKEN
```
