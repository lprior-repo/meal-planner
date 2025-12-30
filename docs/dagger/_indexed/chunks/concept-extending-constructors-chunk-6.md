---
doc_id: concept/extending/constructors
chunk_id: concept/extending/constructors#chunk-6
heading_path: ["constructors", "Default values for complex types"]
chunk_type: code
tokens: 447
summary: "Constructors can be passed both simple and complex types (such as `Container`, `Directory`, `Serv..."
---
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
