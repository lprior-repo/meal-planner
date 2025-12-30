# GitRepository

The `GitRepository` type represents a Git repository.

## Common operations

| Field | Description |
|-------|-------------|
| `branch` | Returns details of a branch |
| `commit` | Returns details of a commit |
| `head` | Returns details of the current HEAD |
| `ref` | Returns details of a ref |
| `tag` | Returns details of a tag |
| `tags` | Returns tags that match a given pattern |
| `branches` | Returns branches that match a given pattern |

## Example

### Clone a remote Git repository into a container

The following Dagger Function accepts a Git repository URL and a Git reference. It copies the repository at the specified reference to the `/src` path in a container and returns the modified container.

> **Note:** For SSH-based cloning, this requires explicitly forwarding the host `SSH_AUTH_SOCK` to the Dagger Function.

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

// Demonstrates cloning a Git repository over HTTP(S).
type MyModule struct{}

func (m *MyModule) Clone(ctx context.Context, repository string, ref string) *dagger.Container {
	d := dag.Git(repository).Ref(ref).Tree()
	return dag.Container().
		From("alpine:latest").
		WithDirectory("/src", d).
		WithWorkdir("/src")
}
```

**Go (SSH):**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

// Demonstrates an SSH-based clone requiring a user-supplied SSHAuthSocket.
type MyModule struct{}

func (m *MyModule) CloneWithSsh(ctx context.Context, repository string, ref string, sock *dagger.Socket) *dagger.Container {
	d := dag.Git(repository, dagger.GitOpts{SSHAuthSocket: sock}).Ref(ref).Tree()
	return dag.Container().
		From("alpine:latest").
		WithDirectory("/src", d).
		WithWorkdir("/src")
}
```

**Python:**
```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    """
    Demonstrates cloning a Git repository over HTTP(S).
    """

    @function
    async def clone(
        self,
        repository: str,
        ref: str,
    ) -> dagger.Container:
        repo_dir = dag.git(repository).ref(ref).tree()
        return (
            dag.container()
            .from_("alpine:latest")
            .with_directory("/src", repo_dir)
            .with_workdir("/src")
        )
```

**TypeScript:**
```typescript
import { dag, Directory, Container, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
    Demonstrates cloning a Git repository over HTTP(S).
   */
  @func()
  clone(repository: string, ref: string): Container {
    const repoDir = dag.git(repository).ref(ref).tree()
    return dag
      .container()
      .from("alpine:latest")
      .withDirectory("/src", repoDir)
      .withWorkdir("/src")
  }
}
```

**Examples:**

Clone the public `dagger/dagger` GitHub repository to `/src` in the container:

```bash
dagger call clone --repository=https://github.com/dagger/dagger --ref=196f232a4d6b2d1d3db5f5e040cf20b6a76a76c5
```

Clone and open an interactive terminal:

```bash
dagger call \
  clone --repository=https://github.com/dagger/dagger --ref=196f232a4d6b2d1d3db5f5e040cf20b6a76a76c5 \
  terminal
```

Clone over SSH with socket forwarding:

```bash
dagger call \
  clone-with-ssh --repository=git@github.com:dagger/dagger.git --ref=196f232a4d6b2d1d3db5f5e040cf20b6a76a76c5 --sock=$SSH_AUTH_SOCK \
  terminal
```
