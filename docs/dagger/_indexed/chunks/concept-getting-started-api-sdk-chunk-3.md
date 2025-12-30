---
doc_id: concept/getting-started/api-sdk
chunk_id: concept/getting-started/api-sdk#chunk-3
heading_path: ["api-sdk", "Example Dagger Function"]
chunk_type: code
tokens: 547
summary: "Here's an example of a Dagger Function that calls a remote API method and returns the result:

**..."
---
Here's an example of a Dagger Function that calls a remote API method and returns the result:

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) GetUser(ctx context.Context) (string, error) {
	return dag.Container().
		From("alpine:latest").
		WithExec([]string{"apk", "add", "curl"}).
		WithExec([]string{"apk", "add", "jq"}).
		WithExec([]string{"sh", "-c", "curl https://randomuser.me/api/ | jq .results[0].name"}).
		Stdout(ctx)
}
```

**Python:**
```python
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    async def get_user(self) -> str:
        return await (
            dag.container()
            .from_("alpine:latest")
            .with_exec(["apk", "add", "curl"])
            .with_exec(["apk", "add", "jq"])
            .with_exec(
                ["sh", "-c", "curl https://randomuser.me/api/ | jq .results[0].name"]
            )
            .stdout()
        )
```

**TypeScript:**
```typescript
import { dag, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  @func()
  async getUser(): Promise<string> {
    return await dag
      .container()
      .from("alpine:latest")
      .withExec(["apk", "add", "curl"])
      .withExec(["apk", "add", "jq"])
      .withExec([
        "sh",
        "-c",
        "curl https://randomuser.me/api/ | jq .results[0].name",
      ])
      .stdout()
  }
}
```

In simple terms, this Dagger Function:

- initializes a new container from an `alpine` base image.
- executes the `apk add ...` command in the container to add the `curl` and `jq` utilities.
- uses the `curl` utility to send an HTTP request to the URL `https://randomuser.me/api/` and parses the response using `jq`.
- retrieves and returns the output stream of the last executed command as a string.

> **Important:** Every Dagger Function has access to the `dag` client, which is a pre-initialized Dagger API client. This client contains all the core types (like `Container`, `Directory`, etc.), as well as bindings to any dependencies your Dagger module has declared.

Here is an example call for this Dagger Function:

```bash
dagger call get-user
```

Here's what you should see:

```json
{
  "title": "Mrs",
  "first": "Beatrice",
  "last": "Lavigne"
}
```

> **Important:** Dagger Functions execute within containers spawned by the Dagger Engine. This "sandboxing" serves a few important purposes:
> 
> 1. **Reproducibility**: Executing in a well-defined and well-controlled container ensures that a Dagger Function runs the same way every time it is invoked. It also guards against creating "hidden dependencies" on ambient properties of the execution environment that could change at any moment.
> 2. **Caching**: A reproducible containerized environment makes it possible to cache the result of Dagger Function execution, which in turn allows Dagger to automatically speed up operations.
> 3. **Security**: Even when running third-party Dagger Functions sourced from a Git repository, those Dagger Functions will not have default access to your host environment (host files, directories, environment variables, etc.). Access to these host resources can only be granted by explicitly passing them as argument values to the Dagger Function.
