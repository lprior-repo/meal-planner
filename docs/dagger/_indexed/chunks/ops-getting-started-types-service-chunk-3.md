---
doc_id: ops/getting-started/types-service
chunk_id: ops/getting-started/types-service#chunk-3
heading_path: ["types-service", "Examples"]
chunk_type: code
tokens: 207
summary: "The first Dagger Function creates and returns an HTTP service."
---
### Bind and use services in Dagger Functions

The first Dagger Function creates and returns an HTTP service. This service is bound and used from a different Dagger Function via a service binding.

**Go:**
```go
package main

import (
	"context"
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

// Send a request to an HTTP service and return the response
func (m *MyModule) Get(ctx context.Context) (string, error) {
	return dag.Container().
		From("alpine").
		WithServiceBinding("www", m.HttpService()).
		WithExec([]string{"wget", "-O-", "http://www:8080"}).
		Stdout(ctx)
}
```

**Example:**
```bash
dagger call get
```

### Expose services in Dagger Functions to the host

**Go:**
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

**Examples:**
```bash
