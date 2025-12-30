---
doc_id: concept/cookbook/filesystems
chunk_id: concept/cookbook/filesystems#chunk-2
heading_path: ["filesystems", "Clone a remote Git repository into a container"]
chunk_type: code
tokens: 329
summary: "The following Dagger Function accepts a Git repository URL and a Git reference."
---
The following Dagger Function accepts a Git repository URL and a Git reference. It copies the repository at the specified reference to the `/src` path in a container and returns the modified container.

### Go

```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

// Demonstrates cloning a Git repository over HTTP(S).
// For SSH usage, see the SSH snippet (CloneWithSsh).
type MyModule struct{}

func (m *MyModule) Clone(ctx context.Context, repository string, ref string) *dagger.Container {
	d := dag.Git(repository).Ref(ref).Tree()
	return dag.Container().
		From("alpine:latest").
		WithDirectory("/src", d).
		WithWorkdir("/src")
}
```

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    """
    Demonstrates cloning a Git repository over HTTP(S).
    For SSH usage, see the SSH snippet (clone_with_ssh).
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

### TypeScript

```typescript
import { dag, Directory, Container, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
    Demonstrates cloning a Git repository over HTTP(S).
    For SSH usage, see the SSH snippet (cloneWithSsh).
   */
  @func()
  clone(repository: string, ref: string): Container {
    const repoDir = dag.git(repository, { sshAuthSocket: sock }).ref(ref).tree()
    return dag
      .container()
      .from("alpine:latest")
      .withDirectory("/src", repoDir)
      .withWorkdir("/src")
  }
}
```

### Examples

Clone the public `dagger/dagger` GitHub repository to `/src` in the container:

```bash
dagger call clone --repository=https://github.com/dagger/dagger --ref=196f232a4d6b2d1d3db5f5e040cf20b6a76a76c5
```

Clone the public `dagger/dagger` GitHub repository at reference `196f232a4d6b2d1d3db5f5e040cf20b6a76a76c5` to `/src` in the container and open an interactive terminal to inspect the container filesystem:

```bash
dagger call \
  clone --repository=https://github.com/dagger/dagger --ref=196f232a4d6b2d1d3db5f5e040cf20b6a76a76c5 \
  terminal
```
