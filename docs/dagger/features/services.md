# Ephemeral Services

Dagger Functions support service containers, enabling users to spin up additional services (as containers) and communicate with those services from their workflows.

This makes it possible to:

- Instantiate and return services from a Dagger Function, and then:
  - Use those services in other Dagger Functions (container-to-container networking)
  - Use those services from the calling host (container-to-host networking)
- Expose host services for use in a Dagger Function (host-to-container networking).

## Use cases

Some common scenarios for using services with Dagger Functions are:

- Running a database service for local storage or testing
- Running end-to-end integration tests against a service
- Running sidecar services

## Service containers

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

## Host services

This also works in the opposite direction: containers in Dagger Functions can communicate with services running on the host.

### Example

Here's an example of how a workflow running in a Dagger Function can access and query a MariaDB database service running on the host (Go):

```go
package main

import (
    "context"
    "dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) UserList(
    ctx context.Context,
    svc *dagger.Service,
) (string, error) {
    return dag.Container().
        From("mariadb:10.11.2").
        WithServiceBinding("db", svc).
        WithExec([]string{"/usr/bin/mysql", "--user=root", "--password=secret", "--host=db", "-e", "SELECT Host, User FROM mysql.user"}).
        Stdout(ctx)
}
```

## Learn more

- Use services as function arguments
- Create and return services from a function
- Expose host services to a function
- Start and stop services
- Persist service state
