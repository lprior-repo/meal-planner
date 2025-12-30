---
doc_id: concept/extending/state
chunk_id: concept/extending/state#chunk-1
heading_path: ["state"]
chunk_type: code
tokens: 826
summary: "> **Context**: Object state can be exposed as a Dagger Function, without having to create a gette..."
---
# State and Getters

> **Context**: Object state can be exposed as a Dagger Function, without having to create a getter function explicitly. Depending on the language used, this state is...


Object state can be exposed as a Dagger Function, without having to create a getter function explicitly. Depending on the language used, this state is exposed using struct fields (Go), object attributes (Python) or object properties (TypeScript).

**Go:**

> **Warning:** Dagger only exposes a struct's public fields; private fields will not be exposed.

Here's an example where one struct field is exposed as a Dagger Function, while the other is not:

```go
package main

import "fmt"

type MyModule struct {
	// The greeting to use
	Greeting string
	// Who to greet
	// +private
	Name string
}

func New(
	// The greeting to use
	// +default="Hello"
	greeting string,
	// Who to greet
	// +default="World"
	name string,
) *MyModule {
	return &MyModule{
		Greeting: greeting,
		Name:     name,
	}
}

// Return the greeting message
func (m *MyModule) Message() string {
	str := fmt.Sprintf("%s, %s!", m.Greeting, m.Name)
	return str
}
```

**Python:**

The [`dagger.field`](https://dagger-io.readthedocs.io/en/latest/module.html#dagger.field) descriptor is a wrapper of [`dataclasses.field`](https://docs.python.org/3/library/dataclasses.html#mutable-default-values). It creates a getter function for the attribute as well so that it's accessible from the Dagger API.

Here's an example where one attribute is exposed as a Dagger Function, while the other is not:

```python
"""An example exposing Dagger Functions for object attributes."""

from typing import Annotated

from dagger import Doc, field, function, object_type


@object_type
class MyModule:
    """Functions for greeting the world"""

    greeting: Annotated[str, Doc("The greeting to use")] = field(default="Hello")
    name: Annotated[str, Doc("Who to greet")] = "World"

    @function
    def message(self) -> str:
        """Return the greeting message"""
        return f"{self.greeting}, {self.name}!"
```

**TypeScript:**

TypeScript already offers `private`, `protected` and `public` keywords to handle member visibility in a class. However, Dagger will only expose those members of a Dagger module that are explicitly decorated with the `@func()` decorator. Others will remain private.

Here's an example where one field is exposed as a Dagger Function, while the other is not:

```typescript
import { object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * The greeting to use
   */
  @func()
  greeting: string

  /**
   * Who to greet
   */
  name: string

  constructor(
    /**
     * The greeting to use
     */
    greeting: string = "Hello",
    /**
     * Who to greet
     */
    name: string = "World",
  ) {
    this.greeting = greeting
    this.name = name
  }

  /**
   * Return the greeting message
   */
  @func()
  message(): string {
    return `${this.greeting}, ${this.name}!`
  }
}
```

**PHP:**

The PHP SDK doesn't yet support state getters. You can follow [issue #10882](https://github.com/dagger/dagger/issues/10882) for updates.

**Java:**

Dagger will automatically expose all public fields of a class as Dagger Functions. It's also possible to expose a package, `protected` or `private` field by annotating it with the `@Function` annotation.

In case of a field that shouldn't be serialized at all, this can be achieved by marking it as `transient` in Java.

Here's an example where one field is exposed as a Dagger Function, while the other is not:

```java
package io.dagger.modules.mymodule;

import io.dagger.module.annotation.Default;
import io.dagger.module.annotation.Function;
import io.dagger.module.annotation.Object;

@Object
public class MyModule {
  /** The greeting to use */
  public String greeting;

  /** Who to greet */
  private String name;

  public MyModule() {}

  /**
   * @param greeting The greeting to use
   * @param name Who to greet
   */
  public MyModule(@Default("Hello") String greeting, @Default("World") String name) {
    this.greeting = greeting;
    this.name = name;
  }

  /** Return the greeting message */
  @Function
  public String message() {
    return greeting + ", " + name;
  }
}
```

Confirm with `dagger call --help` or `.help my-module` that only the `greeting` function was created, with `name` remaining only a constructor argument:

```
FUNCTIONS
  greeting      The greeting to use
  message       Return the greeting message

ARGUMENTS
      --greeting string   The greeting to use (default "Hello")
      --name string       Who to greet (default "World")
```
