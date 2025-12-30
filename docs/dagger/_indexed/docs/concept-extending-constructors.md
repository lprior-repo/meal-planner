---
id: concept/extending/constructors
title: "Constructors"
category: concept
tags: ["directory", "module", "function", "container", "concept"]
---

# Constructors

> **Context**: Every Dagger module has a constructor. The default one is generated automatically and has no arguments.


Every Dagger module has a constructor. The default one is generated automatically and has no arguments.

It's possible to write a custom constructor. The mechanism to do this is SDK-specific.

This is a simple way to accept module-wide configuration, or just to set a few attributes without having to create setter functions for them.

> **Important:** Dagger modules have only one constructor. Constructors of [custom types](./concept-extending-custom-types.md) are not registered; they are constructed by the function that chains them.

## Simple constructor

The default constructor for a module can be overridden by registering a custom constructor. Its parameters are available as flags in the `dagger` command directly.

> **Important:** If you plan to use constructor fields in other module functions, ensure that they are declared as public (in Go and TypeScript). This is because Dagger stores fields using serialization and private fields are omitted during the serialization process. As a result, if a field is not declared as public, calling methods that use it will produce unexpected results.

Here is an example module with a custom constructor:

**Go:**
```go
// A Dagger module for saying hello world!

package main

import (
	"fmt"
)

func New(
	// +default="Hello"
	greeting string,
	// +default="World"
	name string,
) *MyModule {
	return &MyModule{
		Greeting: greeting,
		Name:     name,
	}
}

type MyModule struct {
	Greeting string
	Name     string
}

func (hello *MyModule) Message() string {
	return fmt.Sprintf("%s, %s!", hello.Greeting, hello.Name)
}
```

**Python:**
```python
from dagger import function, object_type


@object_type
class MyModule:
    greeting: str = "Hello"
    name: str = "World"

    @function
    def message(self) -> str:
        return f"{self.greeting}, {self.name}!"
```

**TypeScript:**
```typescript
import { object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  greeting: string
  name: string

  constructor(greeting = "Hello", name = "World") {
    this.greeting = greeting
    this.name = name
  }

  @func()
  message(): string {
    return `${this.greeting} ${this.name}`
  }
}
```

**PHP:**
```php
<?php

declare(strict_types=1);

namespace DaggerModule;

use Dagger\Attribute\{DaggerObject, DaggerFunction};

#[DaggerObject]
class MyModule
{
    #[DaggerFunction]
    public function __construct(
        private readonly string $greeting = 'Hello',
        private readonly string $name = 'World',
    ) {
    }

    #[DaggerFunction]
    public function message(): string
    {
        return "{$this->greeting} {$this->message}";
    }
}
```

**Java:**
```java
package io.dagger.modules.mymodule;

import static io.dagger.client.Dagger.dag;

import io.dagger.client.Container;
import io.dagger.client.DaggerQueryException;
import io.dagger.client.Directory;
import io.dagger.module.annotation.Function;
import io.dagger.module.annotation.Ignore;
import io.dagger.module.annotation.Object;
import java.util.concurrent.ExecutionException;

@Object
public class MyModule {
  @Function
  public Container foo(@Ignore({"*", "!src/**/*.java", "!pom.xml"}) Directory source)
      throws ExecutionException, DaggerQueryException, InterruptedException {
    return dag().container().from("alpine:latest").withDirectory("/src", source).sync();
  }
}
```

Here is an example call for this Dagger Function:

```bash
## System shell
dagger -c '. --name=Foo | message'

## Dagger Shell
. --name=Foo | message

## Dagger CLI
dagger call --name=Foo message
```

The result will be:

```
Hello, Foo!
```

## Default values for complex types

Constructors can be passed both simple and complex types (such as `Container`, `Directory`, `Service` etc.) as arguments. Default values can be assigned in both cases.

> **Important:** Explicitly declare the type even when it can be inferred, so that the Dagger SDK can extend the GraphQL schema correctly.

Here is an example of a Dagger module with a default constructor argument of type `Container`:

**Go:**
```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

func New(
	// +optional
	ctr *dagger.Container,
) *MyModule {
	if ctr == nil {
		ctr = dag.Container().From("alpine:3.14.0")
	}
	return &MyModule{
		Ctr: *ctr,
	}
}

type MyModule struct {
	Ctr dagger.Container
}

func (m *MyModule) Version(ctx context.Context) (string, error) {
	c := m.Ctr
	return c.
		WithExec([]string{"/bin/sh", "-c", "cat /etc/os-release | grep VERSION_ID"}).
		Stdout(ctx)
}
```

**Python:**
```python
import dagger
from dagger import dag, function, object_type


@object_type
class MyModule:
    ctr: dagger.Container = dag.container().from_("alpine:3.14.0")

    @function
    async def version(self) -> str:
        return await self.ctr.with_exec(
            ["/bin/sh", "-c", "cat /etc/os-release | grep VERSION_ID"]
        ).stdout()
```

**TypeScript:**
```typescript
import { dag, Container, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  ctr: Container

  constructor(ctr?: Container) {
    this.ctr = ctr ?? dag.container().from("alpine:3.14.0")
  }

  @func()
  async version(): Promise<string> {
    return await this.ctr
      .withExec(["/bin/sh", "-c", "cat /etc/os-release | grep VERSION_ID"])
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
use Dagger\Container;

use function Dagger\dag;

#[DaggerObject]
class MyModule
{
    private Container $ctr;

    #[DaggerFunction]
    public function __construct(
        ?Container $ctr,
    ) {
        $this->ctr = $ctr ?? dag()->container()->from('alpine:3.14.0');
    }

    #[DaggerFunction]
    public function version(): string
    {
        return $this->ctr
            ->withExec(['/bin/sh', '-c', 'cat /etc/os-release | grep VERSION_ID'])
            ->stdout();
    }
}
```

**Java:**
```java
package io.dagger.modules.mymodule;

import static io.dagger.client.Dagger.dag;

import io.dagger.client.Container;
import io.dagger.client.exception.DaggerQueryException;
import io.dagger.module.annotation.Function;
import io.dagger.module.annotation.Object;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ExecutionException;

@Object
public class MyModule {
  public Container ctr;

  public MyModule() {}

  public MyModule(Optional<Container> ctr) {
    this.ctr = ctr.orElseGet(() -> dag().container().from("alpine:3.14.0"));
  }

  @Function
  public String version() throws ExecutionException, DaggerQueryException, InterruptedException {
    return ctr.withExec(List.of("/bin/sh", "-c", "cat /etc/os-release | grep VERSION_ID")).stdout();
  }
}
```

Here is an example call for this Dagger Function:

```bash
dagger call version
```

The result will be:

```
VERSION_ID=3.14.0
```

## See Also

- [custom types](./concept-extending-custom-types.md)
