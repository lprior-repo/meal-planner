---
doc_id: concept/cookbook/filesystems
chunk_id: concept/cookbook/filesystems#chunk-5
heading_path: ["filesystems", "Request a file over HTTP/HTTPS and save it in a container"]
chunk_type: code
tokens: 207
summary: "```go
package main

import (
	\"context\"

	\"dagger/my-module/internal/dagger\"
)

type MyModule str..."
---
### Go

```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) ReadFileHttp(
	ctx context.Context,
	url string,
) *dagger.Container {
	file := dag.HTTP(url)
	return dag.Container().
		From("alpine:latest").
		WithFile("/src/myfile", file)
}
```

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    def read_file_http(self, url: str) -> dagger.Container:
        file = dag.http(url)
        return dag.container().from_("alpine:latest").with_file("/src/myfile", file)
```

### TypeScript

```typescript
import { dag, object, func, Container } from "@dagger.io/dagger"

@object()
class MyModule {
  @func()
  readFileHttp(url: string): Container {
    const file = dag.http(url)
    return dag.container().from("alpine:latest").withFile("/src/myfile", file)
  }
}
```

### Examples

Request the `README.md` file from the public `dagger/dagger` GitHub repository over HTTPS, save it as `/src/myfile` in the container, and return the container:

```bash
dagger call read-file-http --url=https://raw.githubusercontent.com/dagger/dagger/refs/heads/main/README.md
```

Request the `README.md` file from the public `dagger/dagger` GitHub repository over HTTPS, save it as `/src/myfile` in the container, and display its contents:

```bash
dagger call \
  read-file-http --url=https://raw.githubusercontent.com/dagger/dagger/refs/heads/main/README.md \
  file --path=/src/myfile \
  contents
```
