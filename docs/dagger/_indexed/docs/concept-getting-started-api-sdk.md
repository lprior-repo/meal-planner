---
id: concept/getting-started/api-sdk
title: "Using Dagger SDKs"
category: concept
tags: ["ci", "module", "function", "container", "concept"]
---

# Using Dagger SDKs

> **Context**: Dagger SDKs make it easy to call the Dagger API from your favorite programming language, by developing Dagger Functions or custom applications.


Dagger SDKs make it easy to call the Dagger API from your favorite programming language, by developing Dagger Functions or custom applications.

A Dagger SDK provides two components:

- A client library to call the Dagger API from your code
- Tooling to extend the Dagger API with your own Dagger Functions (bundled in a Dagger module)

The Dagger API uses GraphQL as its low-level language-agnostic framework, and can also be accessed using any standard GraphQL client. However, you do not need to know GraphQL to call the Dagger API; the translation to underlying GraphQL API calls is handled internally by the Dagger SDKs.

Official Dagger SDKs are currently available for Go, TypeScript and Python. There are also [experimental and community SDKs contributed by the Dagger community](https://github.com/dagger/dagger/tree/main/sdk).

> **Custom applications:** Dagger SDKs can also be used to build custom applications that use the Dagger API. These applications can be standalone or integrated into existing systems, allowing you to leverage Dagger's capabilities in your own software solutions.

## Dagger Functions

The recommended, and most common way, to interact with the Dagger API is through Dagger Functions. Dagger Functions are just regular code, written in your usual language using a type-safe Dagger SDK.

Dagger Functions are packaged, shared and reused using Dagger modules. A new Dagger module is initialized by calling `dagger init`. This creates a new `dagger.json` configuration file in the current working directory, together with sample Dagger Function source code. The configuration file will default the name of the module to the current directory name, unless an alternative is specified with the `--name` argument.

Once a module is initialized, `dagger develop --sdk=...` sets up or updates all the resources needed to develop the module locally using a Dagger SDK. By default, the module source code will be stored in the current working directory, unless an alternative is specified with the `--source` argument.

Here is an example of initializing a Dagger module:

**Go:**
```bash
dagger init --name=my-module
dagger develop --sdk=go
```

**Python:**
```bash
dagger init --name=my-module
dagger develop --sdk=python
```

**TypeScript:**
```bash
dagger init --name=my-module
dagger develop --sdk=typescript
```

**PHP:**
```bash
dagger init --name=my-module
dagger develop --sdk=php
```

**Java:**
```bash
dagger init --name=my-module
dagger develop --sdk=java
```

> **Warning:** Running `dagger develop` regenerates the module's code based on dependencies, the current state of the module, and the current Dagger API version. This can result in unexpected results if there are significant changes between the previous and latest installed Dagger API versions. Always refer to the [changelog](https://github.com/dagger/dagger/blob/main/CHANGELOG.md) for a complete list of changes (including breaking changes) in each Dagger release before running `dagger develop`, or use the `--compat=skip` option to bypass updating the Dagger API version.

## Example Dagger Function

Here's an example of a Dagger Function that calls a remote API method and returns the result:

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) GetUser(ctx context.Context) (string, error) {
	return dag.Container().
		From("alpine:latest").
		WithExec([]string{"apk", "add", "curl"}).
		WithExec([]string{"apk", "add", "jq"}).
		WithExec([]string{"sh", "-c", "curl https://randomuser.me/api/ | jq .results[0].name"}).
		Stdout(ctx)
}
```

**Python:**
```python
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    async def get_user(self) -> str:
        return await (
            dag.container()
            .from_("alpine:latest")
            .with_exec(["apk", "add", "curl"])
            .with_exec(["apk", "add", "jq"])
            .with_exec(
                ["sh", "-c", "curl https://randomuser.me/api/ | jq .results[0].name"]
            )
            .stdout()
        )
```

**TypeScript:**
```typescript
import { dag, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  @func()
  async getUser(): Promise<string> {
    return await dag
      .container()
      .from("alpine:latest")
      .withExec(["apk", "add", "curl"])
      .withExec(["apk", "add", "jq"])
      .withExec([
        "sh",
        "-c",
        "curl https://randomuser.me/api/ | jq .results[0].name",
      ])
      .stdout()
  }
}
```

In simple terms, this Dagger Function:

- initializes a new container from an `alpine` base image.
- executes the `apk add ...` command in the container to add the `curl` and `jq` utilities.
- uses the `curl` utility to send an HTTP request to the URL `https://randomuser.me/api/` and parses the response using `jq`.
- retrieves and returns the output stream of the last executed command as a string.

> **Important:** Every Dagger Function has access to the `dag` client, which is a pre-initialized Dagger API client. This client contains all the core types (like `Container`, `Directory`, etc.), as well as bindings to any dependencies your Dagger module has declared.

Here is an example call for this Dagger Function:

```bash
dagger call get-user
```

Here's what you should see:

```json
{
  "title": "Mrs",
  "first": "Beatrice",
  "last": "Lavigne"
}
```

> **Important:** Dagger Functions execute within containers spawned by the Dagger Engine. This "sandboxing" serves a few important purposes:
> 
> 1. **Reproducibility**: Executing in a well-defined and well-controlled container ensures that a Dagger Function runs the same way every time it is invoked. It also guards against creating "hidden dependencies" on ambient properties of the execution environment that could change at any moment.
> 2. **Caching**: A reproducible containerized environment makes it possible to cache the result of Dagger Function execution, which in turn allows Dagger to automatically speed up operations.
> 3. **Security**: Even when running third-party Dagger Functions sourced from a Git repository, those Dagger Functions will not have default access to your host environment (host files, directories, environment variables, etc.). Access to these host resources can only be granted by explicitly passing them as argument values to the Dagger Function.

## See Also

- [Documentation Overview](./COMPASS.md)
