---
doc_id: concept/extending/functions
chunk_id: concept/extending/functions#chunk-1
heading_path: ["functions"]
chunk_type: code
tokens: 586
summary: "> **Context**: Dagger Functions are individual units of computation that perform a specific task ..."
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
