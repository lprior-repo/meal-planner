---
doc_id: concept/extending/interfaces
chunk_id: concept/extending/interfaces#chunk-3
heading_path: ["interfaces", "Implementation"]
chunk_type: code
tokens: 146
summary: "Here is an example of a module `Example` that implements the `Fooer` interface:

**Go:**
```go
pa..."
---
Here is an example of a module `Example` that implements the `Fooer` interface:

**Go:**
```go
package main

import (
	"context"
	"fmt"
)

type Example struct{}

func (m *Example) Foo(ctx context.Context, bar int) (string, error) {
	return fmt.Sprintf("number is: %d", bar), nil
}
```

**Python:**
```python
import dagger


@dagger.object_type
class Example:
    @dagger.function
    def foo(self, bar: int) -> str:
        return f"number is: {bar}"
```

**TypeScript:**
```typescript
import { func, object } from "@dagger.io/dagger"

export interface Fooer {
  // You can also declare it as a method signature (e.g., `foo(): Promise<string>`)
  foo: (bar: number) => Promise<string>
}

@object()
export class Example {
  @func()
  async foo(bar: number): Promise<string> {
    return `number is: ${bar}`
  }
}
```
