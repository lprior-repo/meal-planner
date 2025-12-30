---
doc_id: concept/extending/interfaces
chunk_id: concept/extending/interfaces#chunk-4
heading_path: ["interfaces", "Usage"]
chunk_type: code
tokens: 250
summary: "Any object module that implements the interface method can be passed as an argument to the functi..."
---
Any object module that implements the interface method can be passed as an argument to the function that uses the interface.

Dagger automatically detects if an object coming from the module itself or one of its dependencies implements an interface defined in the module or its dependencies. If so, it will add new conversion functions to the object that implement the interface so it can be passed as argument.

Here is an example of a module that uses the `Example` module defined above and passes it as argument to the `foo` function of the `MyModule` object:

**Go:**
```go
package main

import (
	"context"
)

type Usage struct{}

func (m *Usage) Test(ctx context.Context) (string, error) {
	// Because `Example` implements `Fooer`, the conversion function 
	// `AsMyModuleFooer` has been generated.
	return dag.MyModule().Foo(ctx, dag.Example().AsMyModuleFooer())
}
```

**Python:**
```python
import dagger
from dagger import dag


@dagger.object_type
class Usage:
    @dagger.function
    async def test(self) -> str:
        return await dag.my_module().foo(dag.example().as_my_module_fooer())
```

**TypeScript:**
```typescript
import { dag, func, object } from "@dagger.io/dagger"

@object()
export class Usage {
  @func()
  async test(): Promise<string> {
    // Because `Example` implements `Fooer`, the conversion function
    // `AsMyModuleFooer` has been generated.
    return dag.myModule().foo(dag.example().asMyModuleFooer())
  }
}
```
