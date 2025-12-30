---
doc_id: concept/extending/interfaces
chunk_id: concept/extending/interfaces#chunk-2
heading_path: ["interfaces", "Declaration"]
chunk_type: code
tokens: 620
summary: "**Go:**

The Go SDK supports interfaces, which allow you to define Go-style interface definitions..."
---
**Go:**

The Go SDK supports interfaces, which allow you to define Go-style interface definitions so that your module can accept arbitrary values from other modules without being tightly coupled to the concrete type underneath.

To use an interface, define a Go interface that embeds `DaggerObject` and use it in a function argument.

Here is an example of the definition of an interface `Fooer` with a single function `foo`:

```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

type Fooer interface {
	DaggerObject
	Foo(ctx context.Context, bar int) (string, error)
}

func (m *MyModule) Foo(ctx context.Context, fooer Fooer) (string, error) {
	return fooer.Foo(ctx, 42)
}
```

Functions defined in interface definitions must match the client-side API signature style. If they return a scalar value or an array, they must accept a `context.Context` argument and return an `error` return value. If they return a chainable object value, they must not return an `error` value, and they do not need to include a `context.Context` argument.

**Python:**

The Python SDK supports interfaces, which allow you to define protocol based subtypes so that your module can accept arbitrary values from other modules without being tightly coupled to the concrete type underneath.

To use an interface, define a Python protocol that decorates `@dagger.interface` and use it in a function argument.

Here is an example of the definition of an interface `Fooer` with a single function `foo`:

```python
import typing

import dagger


@dagger.interface
class Fooer(typing.Protocol):
    @dagger.function
    async def foo(self, bar: int) -> str: ...


@dagger.object_type
class MyModule:
    @dagger.function
    async def foo(self, fooer: Fooer) -> str:
        return await fooer.foo(42)
```

Functions defined in interface definitions must match the client-side API signature style. If they don't return a chainable object, they must be coroutines (`async`).

**TypeScript:**

The TypeScript SDK supports interfaces, which allow you to define a set of functions that an object must implement to be considered a valid instance of that interface. That way, your module can accept arbitrary values from other modules without being tightly coupled to the concrete type underneath.

To use an interface, use the TypeScript `interface` keyword and use it as a function argument.

Here is an example of the definition of an interface `Fooer` with a single function `foo`:

```typescript
import { func, object } from "@dagger.io/dagger"

export interface Fooer {
  // You can also declare it as a method signature (e.g., `foo(): Promise<string>`)
  foo: (bar: number) => Promise<string>
}

@object()
export class MyModule {
  @func()
  async foo(fooer: Fooer): Promise<string> {
    return await fooer.foo(42)
  }
}
```

Functions defined in interface definitions must match the client-side API signature style:

- Always define `async` functions in interfaces (wrap the return type in a `Promise<T>`).
- Declare it as a method signature (e.g., `foo(): Promise<string>`) or a property signature (e.g., `foo: () => Promise<string>`).
- Parameters must be properly named since they directly translate to the GraphQL field argument names.
