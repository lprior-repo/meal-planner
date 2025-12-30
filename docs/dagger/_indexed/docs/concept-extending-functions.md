---
id: concept/extending/functions
title: "Functions"
category: concept
tags: ["ci", "module", "function", "container", "concept"]
---

# Functions

> **Context**: Dagger Functions are individual units of computation that perform a specific task by combining operations on components with custom logic. Dagger Func...


Dagger Functions are individual units of computation that perform a specific task by combining operations on components with custom logic. Dagger Functions are written in a programming language using a type-safe Dagger SDK, and packaged and shared in [Dagger modules](./meta-extending-modules.md).

Here's an example of a Dagger Function which calls a remote API method and returns the result:

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

This Dagger Function includes the context as input and error as return in its signature.

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

Dagger Functions are implemented as [@dagger.function](https://dagger-io.readthedocs.io/en/latest/module.html#dagger.function) decorated methods, of a [@dagger.object_type](https://dagger-io.readthedocs.io/en/latest/module.html#dagger.object_type) decorated class.

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

**PHP:**
```php
<?php

declare(strict_types=1);

namespace DaggerModule;

use Dagger\Attribute\{DaggerObject, DaggerFunction};

use function Dagger\dag;

#[DaggerObject]
class MyModule
{
    #[DaggerFunction]
    public function getUser(): string
    {
        return dag()
            ->container()
            ->from('alpine:latest')
            ->withExec(['apk', 'add', 'curl'])
            ->withExec(['apk', 'add', 'jq'])
            ->withExec([
                'sh',
                '-c',
                'curl https://randomuser.me/api/ | jq .results[0].name',
            ])
            ->stdout();
    }
}
```

**Java:**
```java
package io.dagger.modules.mymodule;

import static io.dagger.client.Dagger.dag;

import io.dagger.client.Container;
import io.dagger.client.Directory;
import io.dagger.client.exception.DaggerQueryException;
import io.dagger.module.annotation.Function;
import io.dagger.module.annotation.Object;
import java.util.List;
import java.util.concurrent.ExecutionException;

/** MyModule main object */
@Object
public class MyModule {
  @Function
  public String getUser() throws ExecutionException, DaggerQueryException, InterruptedException {
    return dag().container()
        .from("alpine:latest")
        .withExec(List.of("apk", "add", "curl"))
        .withExec(List.of("apk", "add", "jq"))
        .withExec(List.of("sh", "-c", "curl https://randomuser.me/api/ | jq .results[0].name"))
        .stdout();
  }
}
```

Dagger Functions must be public. The function must be decorated with the `@Function` annotation and the class containing the functions must be decorated with the `@Object` annotation.

In simple terms, here is what this Dagger Function does:

- It initializes a new container from an `alpine` base image.
- It executes the `apk add ...` command in the container to add the `curl` and `jq` utilities.
- It uses the `curl` utility to send an HTTP request to the URL `https://randomuser.me/api/` and parses the response using `jq`.
- It retrieves and returns the output stream of the last executed command as a string.

Here is an example call for this Dagger Function:

```bash
## System shell
dagger -c 'get-user'

## Dagger Shell
get-user

## Dagger CLI
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

When implementing Dagger Functions, you are free to write arbitrary code that will execute inside the Dagger module's container. You have access to the Dagger API to make calls to the core Dagger API or other Dagger modules you depend on, but you are also free to just use the language's standard library and/or imported third-party libraries.

The process your code executes in will currently be with the `root` user, but without a full set of Linux capabilities and other standard container sandboxing provided by `runc`.

The current working directory of your code will be an initially empty directory. You can write and read files and directories in this directory if needed. This includes using the `Container.export()`, `Directory.export()` or `File.export()` APIs to write those artifacts to this local directory if needed.

## See Also

- [Dagger modules](./meta-extending-modules.md)
