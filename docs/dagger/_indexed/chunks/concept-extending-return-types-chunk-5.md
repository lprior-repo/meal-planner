---
doc_id: concept/extending/return-types
chunk_id: concept/extending/return-types#chunk-5
heading_path: ["return-types", "Chaining"]
chunk_type: code
tokens: 395
summary: "So long as a Dagger Function returns an object that can be JSON-serialized, its state will be pre..."
---
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
