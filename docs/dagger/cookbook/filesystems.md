# Filesystems

This page contains practical examples for working with files and directories in Dagger. Each section below provides code examples in multiple languages and demonstrates different approaches to filesystem operations.

## Clone a remote Git repository into a container

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

## Mount or copy a directory or remote repository to a container

The following Dagger Function accepts a `Directory` argument, which could reference either a directory from the local filesystem or from a remote Git repository. It mounts the specified directory to the `/src` path in a container and returns the modified container.

### Go

```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Return a container with a mounted directory
func (m *MyModule) MountDirectory(
	ctx context.Context,
	// Source directory
	source *dagger.Directory,
) *dagger.Container {
	return dag.Container().
		From("alpine:latest").
		WithMountedDirectory("/src", source)
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
    def mount_directory(
        self, source: Annotated[dagger.Directory, Doc("Source directory")]
    ) -> dagger.Container:
        """Return a container with a mounted directory"""
        return (
            dag.container()
            .from_("alpine:latest")
            .with_mounted_directory("/src", source)
        )
```

### TypeScript

```typescript
import { dag, Container, Directory, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Return a container with a mounted directory
   */
  @func()
  mountDirectory(
    /**
     * Source directory
     */
    source: Directory,
  ): Container {
    return dag
      .container()
      .from("alpine:latest")
      .withMountedDirectory("/src", source)
  }
}
```

> **Tip**: Besides helping with the final image size, mounts are more performant and resource-efficient. The rule of thumb should be to always use mounts where possible.

### Examples

Mount the `/myapp` host directory to `/src` in the container and return the modified container:

```bash
dagger call mount-directory --source=./myapp/
```

Mount the public `dagger/dagger` GitHub repository to `/src` in the container and return the modified container:

```bash
dagger call mount-directory --source=https://github.com/dagger/dagger#main
```

## Export a directory or file to the host

The following Dagger Functions return a just-in-time directory and file. These outputs can be exported to the host with `dagger call ... export ...`.

> **Note**: When a host directory or file is copied or mounted to a container's filesystem, modifications made to it in the container do not automatically transfer back to the host. Data flows only one way between Dagger operations, because they are connected in a DAG. To transfer modifications back to the local host, you must explicitly export the directory or file back to the host filesystem.

### Go

```go
package main

import "dagger/my-module/internal/dagger"

type MyModule struct{}

// Return a directory
func (m *MyModule) GetDir() *dagger.Directory {
	return m.Base().
		Directory("/src")
}

// Return a file
func (m *MyModule) GetFile() *dagger.File {
	return m.Base().
		File("/src/foo")
}

// Return a base container
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
    def get_dir(self) -> dagger.Directory:
        """Return a directory"""
        return self.base().directory("/src")

    @function
    def get_file(self) -> dagger.File:
        """Return a file"""
        return self.base().file("/src/foo")

    @function
    def base(self) -> dagger.Container:
        """Return a base container"""
        return (
            dag.container()
            .from_("alpine:latest")
            .with_exec(["mkdir", "/src"])
            .with_exec(["touch", "/src/foo", "/src/bar"])
        )
```

### TypeScript

```typescript
import {
  dag,
  Directory,
  Container,
  File,
  object,
  func,
} from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Return a directory
   */
  @func()
  getDir(): Directory {
    return this.base().directory("/src")
  }

  /**
   * Return a file
   */
  @func()
  getFile(): File {
    return this.base().file("/src/foo")
  }

  /**
   * Return a base container
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

Export the directory returned by the Dagger Function to the `/home/admin/export` path on the host:

```bash
dagger call get-dir export --path=/home/admin/export
```

Export the file returned by the Dagger Function to the `/home/admin/myfile` path on the host:

```bash
dagger call get-file export --path=/home/admin/myfile
```

## Request a file over HTTP/HTTPS and save it in a container

### Go

```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) ReadFileHttp(
	ctx context.Context,
	url string,
) *dagger.Container {
	file := dag.HTTP(url)
	return dag.Container().
		From("alpine:latest").
		WithFile("/src/myfile", file)
}
```

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    def read_file_http(self, url: str) -> dagger.Container:
        file = dag.http(url)
        return dag.container().from_("alpine:latest").with_file("/src/myfile", file)
```

### TypeScript

```typescript
import { dag, object, func, Container } from "@dagger.io/dagger"

@object()
class MyModule {
  @func()
  readFileHttp(url: string): Container {
    const file = dag.http(url)
    return dag.container().from("alpine:latest").withFile("/src/myfile", file)
  }
}
```

### Examples

Request the `README.md` file from the public `dagger/dagger` GitHub repository over HTTPS, save it as `/src/myfile` in the container, and return the container:

```bash
dagger call read-file-http --url=https://raw.githubusercontent.com/dagger/dagger/refs/heads/main/README.md
```

Request the `README.md` file from the public `dagger/dagger` GitHub repository over HTTPS, save it as `/src/myfile` in the container, and display its contents:

```bash
dagger call \
  read-file-http --url=https://raw.githubusercontent.com/dagger/dagger/refs/heads/main/README.md \
  file --path=/src/myfile \
  contents
```

## Set a module-wide default path

The following Dagger module uses a constructor to set a module-wide `Directory` argument and point it to a default path on the host. This eliminates the need to pass a common `Directory` argument individually to each Dagger Function in the module. If required, the default path can be overridden by specifying a different `Directory` value at call time.

### Go

```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct {
	Source *dagger.Directory
}

func New(
	// +defaultPath="."
	source *dagger.Directory,
) *MyModule {
	return &MyModule{
		Source: source,
	}
}

func (m *MyModule) Foo(ctx context.Context) ([]string, error) {
	return dag.Container().
		From("alpine:latest").
		WithMountedDirectory("/app", m.Source).
		Directory("/app").
		Entries(ctx)
}
```

### Python

```python
from typing import Annotated

import dagger
from dagger import DefaultPath, dag, function, object_type

@object_type
class MyModule:
    source: Annotated[dagger.Directory, DefaultPath(".")]

    @function
    async def foo(self) -> str:
        return await (
            dag.container()
            .from_("alpine:latest")
            .with_mounted_directory("/app", self.source)
            .directory("/app")
            .entries()
        )
```

### TypeScript

```typescript
import { dag, Directory, object, func, argument } from "@dagger.io/dagger"

@object()
class MyModule {
  source: Directory

  constructor(
    @argument({ defaultPath: "." })
    source: Directory,
  ) {
    this.source = source
  }

  @func()
  async foo(): Promise<string[]> {
    return await dag
      .container()
      .from("alpine:latest")
      .withMountedDirectory("/app", this.source)
      .directory("/app")
      .entries()
  }
}
```

### Examples

Call the Dagger Function without arguments. The default path (the current directory `.`) is used:

```bash
dagger call foo
```

Call the Dagger Function with a constructor argument. The specified directory (`/src/myapp`) is used:

```bash
dagger call --source=/src/myapp foo
```
