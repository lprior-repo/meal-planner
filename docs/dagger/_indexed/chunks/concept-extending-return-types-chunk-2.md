---
doc_id: concept/extending/return-types
chunk_id: concept/extending/return-types#chunk-2
heading_path: ["return-types", "String return values"]
chunk_type: code
tokens: 176
summary: "Here is an example of a Dagger Function that returns operating system information for the contain..."
---
Here is an example of a Dagger Function that returns operating system information for the container as a string:

**Go:**
```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) OsInfo(ctx context.Context, ctr *dagger.Container) (string, error) {
	return ctr.
		WithExec([]string{"uname", "-a"}).
		Stdout(ctx)
}
```

**Python:**
```python
import dagger
from dagger import function, object_type


@object_type
class MyModule:
    @function
    async def os_info(self, ctr: dagger.Container) -> str:
        return await ctr.with_exec(["uname", "-a"]).stdout()
```

**TypeScript:**
```typescript
import { Container, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  @func()
  async osInfo(ctr: Container): Promise<string> {
    return ctr.withExec(["uname", "-a"]).stdout()
  }
}
```

Here is an example call for this Dagger Function:

```bash
dagger call os-info --ctr=ubuntu:latest
```

The result will look like this:

```
Linux dagger 6.1.0-22-cloud-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.94-1 (2024-06-21) x86_64 x86_64 x86_64 GNU/Linux
```
