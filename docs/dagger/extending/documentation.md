# Inline Documentation

Dagger modules and Dagger Functions should be documented so that descriptions are shown in the API and the CLI - for example, when calling `dagger functions`, `dagger call ... --help`, or `.help`.

**Go:**

The following code snippet shows how to add documentation for:
- The whole module
- Function methods
- Function arguments

```go
// A simple example module to say hello.
// Further documentation for the module here.

package main

import (
	"fmt"
	"strings"
)

type MyModule struct{}

// Return a greeting.
func (m *MyModule) Hello(
	// Who to greet
	name string,
	// The greeting to display
	greeting string,
) string {
	return fmt.Sprintf("%s, %s!", greeting, name)
}

// Return a loud greeting.
func (m *MyModule) LoudHello(
	// Who to greet
	name string,
	// The greeting to display
	greeting string,
) string {
	out := fmt.Sprintf("%s, %s!", greeting, name)
	return strings.ToUpper(out)
}
```

**Python:**

The following code snippet shows how to use Python's [documentation string conventions](https://peps.python.org/pep-0008/#documentation-strings) for adding descriptions to:
- The whole [module](https://docs.python.org/3/tutorial/modules.html) or [package](https://docs.python.org/3/tutorial/modules.html#packages)
- Object type classes (group of functions)
- Function methods
- Function arguments

For function arguments, [annotate](https://peps.python.org/pep-0727/#specification) with the [`dagger.Doc`](https://dagger-io.readthedocs.io/en/latest/module.html#dagger.Doc) metadata.

```python
"""A simple example module to say hello.

Further documentation for the module here.
"""

from typing import Annotated

from dagger import Doc, function, object_type


@object_type
class MyModule:
    """Simple hello functions."""

    @function
    def hello(
        self,
        name: Annotated[str, Doc("Who to greet")],
        greeting: Annotated[str, Doc("The greeting to display")],
    ) -> str:
        """Return a greeting."""
        return f"{greeting}, {name}!"

    @function
    def loud_hello(
        self,
        name: Annotated[str, Doc("Who to greet")],
        greeting: Annotated[str, Doc("The greeting to display")],
    ) -> str:
        """Return a loud greeting.

        Loud means all caps.
        """
        return f"{greeting.upper()}, {name.upper()}!"
```

**TypeScript:**

The following code snippet shows how to add documentation for:
- The whole module
- Function methods
- Function arguments

```typescript
/**
 * A simple example module to say hello.
 *
 * Further documentation for the module here.
 */

import { object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Return a greeting.
   *
   * @param name Who to greet
   * @param greeting The greeting to display
   */
  @func()
  hello(name: string, greeting: string): string {
    return `${greeting}, ${name}!`
  }

  /**
   * Return a loud greeting.
   *
   * @param name Who to greet
   * @param greeting The greeting to display
   */
  @func()
  loudHello(name: string, greeting: string): string {
    return `${greeting.toUpperCase()}, ${name.toUpperCase()}!`
  }
}
```

**PHP:**

The following code snippet shows how to add documentation for:
- The whole module
- Function methods
- Function arguments

```php
<?php

declare(strict_types=1);

namespace DaggerModule;

use Dagger\Attribute\{DaggerObject, DaggerFunction, Doc};

#[DaggerObject]
#[Doc('A simple example module to say hello.')]
class MyModule
{
    #[DaggerFunction]
    #[Doc('Return a greeting')]
    public function hello(
        #[Doc('Who to greet')]
        string $name,
        #[Doc('The greeting to display')]
        string $greeting
    ): string {
        return "{$greeting} {$name}";
    }

    #[DaggerFunction]
    #[Doc('Return a loud greeting')]
    public function loudHello(
        #[Doc('Who to greet')]
        string $name,
        #[Doc('The greeting to display')]
        string $greeting
    ): string {
        return strtoupper("{$greeting} {$name}");
    }
}
```

**Java:**

The following code snippet shows how to add documentation for:
- Function methods
- Function arguments

```java
package io.dagger.modules.mymodule;

import io.dagger.module.annotation.Function;
import io.dagger.module.annotation.Object;

@Object
public class MyModule {
  /**
   * Return a greeting.
   *
   * @param name Who to greet
   * @param greeting The greeting to display
   */
  @Function
  public String hello(String name, String greeting) {
    return greeting + " " + name;
  }

  /**
   * Return a loud greeting.
   *
   * @param name Who to greet
   * @param greeting The greeting to display
   */
  @Function
  public String loudHello(String name, String greeting) {
    return greeting.toUpperCase() + " " + name.toUpperCase();
  }
}
```

The documentation of the module is added in the `package-info.java` file.

```java
/**
 * A simple example module to say hello.
 *
 * Further documentation for the module here.
 */
@Module
package io.dagger.modules.mymodule;

import io.dagger.module.annotation.Module;
```

Here is an example of the result from `dagger functions`:

```
Name         Description
hello        Return a greeting.
loud-hello   Return a loud greeting.
```

Here is an example of the result from `dagger call hello --help`:

```
Return a greeting.

USAGE
  dagger call hello [arguments]

ARGUMENTS
      --greeting string   The greeting to display [required]
      --name string       Who to greet [required]
```
