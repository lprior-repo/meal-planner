# Service

The `Service` type represents a content-addressed service providing TCP connectivity.

## Common operations

| Field | Description |
|-------|-------------|
| `endpoint` | Returns a URL or host:port pair to reach the service |
| `hostname` | Returns a hostname to reach the service |
| `ports` | Returns the list of ports provided by the service |
| `up` | Creates a tunnel that forwards traffic from the caller's network to the service |

## Examples

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
# Expose on default port
dagger call http-service up

# Access from host
curl localhost:8080

# Expose on different host port
dagger call http-service up --ports 9000:8080

# Access from host
curl localhost:9000
```

### Expose host services to Dagger Functions

The following Dagger Function accepts a `Service` running on the host and binds it.

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Send a query to a MariaDB service and return the response
func (m *MyModule) UserList(
	ctx context.Context,
	// Host service
	svc *dagger.Service,
) (string, error) {
	return dag.Container().
		From("mariadb:10.11.2").
		WithServiceBinding("db", svc).
		WithExec([]string{"/usr/bin/mysql", "--user=root", "--password=secret", "--host=db", "-e", "SELECT Host, User FROM mysql.user"}).
		Stdout(ctx)
}
```

**Example:**
```bash
dagger call user-list --svc=tcp://localhost:3306
```

### Use service endpoints

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) Get(ctx context.Context) (string, error) {
	// Start NGINX service
	service := dag.Container().From("nginx").WithExposedPort(80).AsService()
	service, err := service.Start(ctx)
	if err != nil {
		return "", err
	}

	// Wait for service endpoint
	endpoint, err := service.Endpoint(ctx, dagger.ServiceEndpointOpts{Scheme: "http", Port: 80})
	if err != nil {
		return "", err
	}

	// Send HTTP request to service endpoint
	return dag.HTTP(endpoint).Contents(ctx)
}
```

### Create a transient service for unit tests

**Go:**
```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Run unit tests against a database service
func (m *MyModule) Test(ctx context.Context) (string, error) {
	mariadb := dag.Container().
		From("mariadb:10.11.2").
		WithEnvVariable("MARIADB_USER", "user").
		WithEnvVariable("MARIADB_PASSWORD", "password").
		WithEnvVariable("MARIADB_DATABASE", "drupal").
		WithEnvVariable("MARIADB_ROOT_PASSWORD", "root").
		WithExposedPort(3306).
		AsService(dagger.ContainerAsServiceOpts{UseEntrypoint: true})

	// get Drupal base image
	// install additional dependencies
	drupal := dag.Container().
		From("drupal:10.0.7-php8.2-fpm").
		WithExec([]string{"composer", "require", "drupal/core-dev", "--dev", "--update-with-all-dependencies"})

	// add service binding for MariaDB
	// run kernel tests using PHPUnit
	return drupal.
		WithServiceBinding("db", mariadb).
		WithEnvVariable("SIMPLETEST_DB", "mysql://user:password@db/drupal").
		WithEnvVariable("SYMFONY_DEPRECATIONS_HELPER", "disabled").
		WithWorkdir("/opt/drupal/web/core").
		WithExec([]string{"../../vendor/bin/phpunit", "-v", "--group", "KernelTests"}).
		Stdout(ctx)
}
```

**Example:**
```bash
dagger call test
```
