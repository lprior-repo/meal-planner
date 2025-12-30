---
doc_id: ops/cookbook/services
chunk_id: ops/cookbook/services#chunk-3
heading_path: ["services", "Expose services in Dagger Functions to the host"]
chunk_type: code
tokens: 280
summary: "The Dagger Function below creates and returns an HTTP service."
---
The Dagger Function below creates and returns an HTTP service. This service can be used from the host.

### Go

```go
package main

import (
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Start and return an HTTP service
func (m *MyModule) HttpService() *dagger.Service {
	return dag.Container().
		From("python").
		WithWorkdir("/srv").
		WithNewFile("index.html", "Hello, world!").
		WithExposedPort(8080).
		AsService(dagger.ContainerAsServiceOpts{Args: []string{"python", "-m", "http.server", "8080"}})
}
```

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    def http_service(self) -> dagger.Service:
        """Start and return an HTTP service."""
        return (
            dag.container()
            .from_("python")
            .with_workdir("/srv")
            .with_new_file("index.html", "Hello, world!")
            .with_exposed_port(8080)
            .as_service(args=["python", "-m", "http.server", "8080"])
        )
```

### TypeScript

```typescript
import { dag, object, func, Service } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Start and return an HTTP service
   */
  @func()
  httpService(): Service {
    return dag
      .container()
      .from("python")
      .withWorkdir("/srv")
      .withNewFile("index.html", "Hello, world!")
      .withExposedPort(8080)
      .asService({ args: ["python", "-m", "http.server", "8080"] })
  }
}
```

### Examples

Expose the HTTP service instantiated by a Dagger Function to the host on the default port:

```bash
dagger call http-service up
```

Access the service from the host:

```bash
curl localhost:8080
```

Expose the HTTP service instantiated by a Dagger Function to the host on a different host port:

```bash
dagger call http-service up --ports 9000:8080
```

Access the service from the host:

```bash
curl localhost:9000
```
