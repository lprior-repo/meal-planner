# Return Types

In addition to returning basic types (string, boolean, ...), Dagger Functions can also return any of Dagger's core types, such as `Directory`, `Container`, `Service`, `Secret`, and many more.

This opens powerful applications to Dagger Functions. For example, a Dagger Function that builds binaries could take a directory with the source code as argument and return another directory (a "just-in-time" directory) containing just binaries or a container image (a "just-in-time" container) with the binaries included.

> **Note:** If a function doesn't have a return type annotation, it'll be translated to the [dagger.Void](https://docs.dagger.io/api/reference/#definition-Void) type in the API.

## String return values

Here is an example of a Dagger Function that returns operating system information for the container as a string:

**Go:**
```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) OsInfo(ctx context.Context, ctr *dagger.Container) (string, error) {
	return ctr.
		WithExec([]string{"uname", "-a"}).
		Stdout(ctx)
}
```

**Python:**
```python
import dagger
from dagger import function, object_type


@object_type
class MyModule:
    @function
    async def os_info(self, ctr: dagger.Container) -> str:
        return await ctr.with_exec(["uname", "-a"]).stdout()
```

**TypeScript:**
```typescript
import { Container, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  @func()
  async osInfo(ctr: Container): Promise<string> {
    return ctr.withExec(["uname", "-a"]).stdout()
  }
}
```

Here is an example call for this Dagger Function:

```bash
dagger call os-info --ctr=ubuntu:latest
```

The result will look like this:

```
Linux dagger 6.1.0-22-cloud-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.94-1 (2024-06-21) x86_64 x86_64 x86_64 GNU/Linux
```

## Directory return values

Directory return values might be produced by a Dagger Function that:
- Builds language-specific binaries
- Downloads source code from git or another remote source
- Processes source code (for example, generating documentation or linting code)
- Downloads or processes datasets
- Downloads machine learning models

Here is an example of a Go builder Dagger Function that accepts a remote Git address as a `Directory` argument, builds a Go binary from the source code in that repository, and returns the build directory containing the compiled binary:

**Go:**
```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) GoBuilder(ctx context.Context, src *dagger.Directory, arch string, os string) *dagger.Directory {
	return dag.Container().
		From("golang:1.21").
		WithMountedDirectory("/src", src).
		WithWorkdir("/src").
		WithEnvVariable("GOARCH", arch).
		WithEnvVariable("GOOS", os).
		WithEnvVariable("CGO_ENABLED", "0").
		WithExec([]string{"go", "build", "-o", "build/"}).
		Directory("/src/build")
}
```

Here is an example call for this Dagger Function:

```bash
dagger call go-builder --src=https://github.com/golang/example#master:/hello --arch=amd64 --os=linux
```

Once the command completes, you should see this output:

```
_type: Directory
entries:
    - hello
```

This means that the build succeeded, and a `Directory` type representing the build directory was returned.

## Container return values

Just-in-time containers are produced by calling a Dagger Function that returns the `Container` type. This type provides a complete API for building, running and distributing containers.

Here's an example of a Dagger Function that returns a base `alpine` container image with a list of additional specified packages:

**Go:**
```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) AlpineBuilder(ctx context.Context, packages []string) *dagger.Container {
	ctr := dag.Container().
		From("alpine:latest")
	for _, pkg := range packages {
		ctr = ctr.WithExec([]string{"apk", "add", pkg})
	}
	return ctr
}
```

Here is an example call for this Dagger Function:

```bash
dagger call alpine-builder --packages=curl,openssh
```

## Chaining

So long as a Dagger Function returns an object that can be JSON-serialized, its state will be preserved and passed to the next function in the chain. This makes it possible to write custom Dagger Functions that support function chaining in the same style as the Dagger API.

Here is an example module with support for function chaining:

**Go:**
```go
// A Dagger module for saying hello world!

package main

import (
	"context"
	"fmt"
)

type MyModule struct {
	Greeting string
	Name     string
}

func (hello *MyModule) WithGreeting(ctx context.Context, greeting string) (*MyModule, error) {
	hello.Greeting = greeting
	return hello, nil
}

func (hello *MyModule) WithName(ctx context.Context, name string) (*MyModule, error) {
	hello.Name = name
	return hello, nil
}

func (hello *MyModule) Message(ctx context.Context) (string, error) {
	var (
		greeting = hello.Greeting
		name     = hello.Name
	)
	if greeting == "" {
		greeting = "Hello"
	}
	if name == "" {
		name = "World"
	}
	return fmt.Sprintf("%s, %s!", greeting, name), nil
}
```

**Python:**
```python
"""A simple chaining example module."""

from typing import Self

from dagger import function, object_type


@object_type
class MyModule:
    """Functions that chain together."""

    greeting: str = "Hello"
    name: str = "World"

    @function
    def with_greeting(self, greeting: str) -> Self:
        self.greeting = greeting
        return self

    @function
    def with_name(self, name: str) -> Self:
        self.name = name
        return self

    @function
    def message(self) -> str:
        return f"{self.greeting}, {self.name}!"
```

**TypeScript:**
```typescript
import { object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  @func()
  greeting = "Hello"

  @func()
  name = "World"

  @func()
  withGreeting(greeting: string): MyModule {
    this.greeting = greeting
    return this
  }

  @func()
  withName(name: string): MyModule {
    this.name = name
    return this
  }

  @func()
  message(): string {
    return `${this.greeting} ${this.name}`
  }
}
```

And here is an example call for this module:

```bash
dagger call with-name --name=Monde with-greeting --greeting=Bonjour message
```

The result will be:

```
Bonjour, Monde!
```
