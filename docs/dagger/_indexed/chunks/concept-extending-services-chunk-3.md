---
doc_id: concept/extending/services
chunk_id: concept/extending/services#chunk-3
heading_path: ["services", "Bind services in functions"]
chunk_type: code
tokens: 213
summary: "A Dagger Function can create and return a service, which can then be used from another Dagger Fun..."
---
A Dagger Function can create and return a service, which can then be used from another Dagger Function or from the calling host. Services in Dagger Functions are returned using the `Service` type.

Here is an example of a Dagger Function that returns an HTTP service. This service is used by another Dagger Function, which creates a service binding using the alias `www` and then accesses the HTTP service using this alias.

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

Here is an example call for this Dagger Function:

```bash
dagger call get
```

The result will be:

```
Hello, world!
```
