---
doc_id: concept/features/services
chunk_id: concept/features/services#chunk-3
heading_path: ["services", "Service containers"]
chunk_type: code
tokens: 143
summary: "Services instantiated by a Dagger Function run in service containers, which have the following ch..."
---
Services instantiated by a Dagger Function run in service containers, which have the following characteristics:

- Each service container has a canonical, content-addressed hostname and an optional set of exposed ports.
- Service containers are started just-in-time, de-duplicated, and stopped when no longer needed.
- Service containers are health checked prior to running clients.

### Example

Here is an example of a Dagger Function that returns an HTTP service, which can then be accessed from the calling host (Go):

```go
package main

import (
    "dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) HttpService() *dagger.Service {
    return dag.Container().
        From("python").
        WithWorkdir("/srv").
        WithNewFile("index.html", "Hello, world!").
        WithExposedPort(8080).
        AsService(dagger.ContainerAsServiceOpts{Args: []string{"python", "-m", "http.server", "8080"}})
}
```
