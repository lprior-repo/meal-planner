---
doc_id: concept/extending/constructors
chunk_id: concept/extending/constructors#chunk-2
heading_path: ["constructors", "Simple constructor"]
chunk_type: code
tokens: 417
summary: "The default constructor for a module can be overridden by registering a custom constructor."
---
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
