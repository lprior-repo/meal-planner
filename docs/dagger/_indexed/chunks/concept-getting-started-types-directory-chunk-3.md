---
doc_id: concept/getting-started/types-directory
chunk_id: concept/getting-started/types-directory#chunk-3
heading_path: ["types-directory", "Default paths"]
chunk_type: code
tokens: 164
summary: "It is possible to assign a default path for a `Directory` or `File` argument in a Dagger Function."
---
It is possible to assign a default path for a `Directory` or `File` argument in a Dagger Function. Dagger will automatically use this default path when no value is specified.

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) ReadDir(
	ctx context.Context,
	// +defaultPath="/"
	source *dagger.Directory,
) ([]string, error) {
	return source.Entries(ctx)
}
```

**Python:**
```python
from typing import Annotated
import dagger
from dagger import DefaultPath, function, object_type

@object_type
class MyModule:
    @function
    async def read_dir(
        self,
        source: Annotated[dagger.Directory, DefaultPath("/")],
    ) -> list[str]:
        return await source.entries()
```

**TypeScript:**
```typescript
import { Directory, File, argument, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  @func()
  async readDir(
    @argument({ defaultPath: "/" }) source: Directory,
  ): Promise<string[]> {
    return await source.entries()
  }
}
```
