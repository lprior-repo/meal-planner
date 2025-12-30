# Services

Dagger Functions support service containers, enabling users to spin up additional long-running services (as containers) and communicate with those services from Dagger Functions.

This makes it possible to:

- Instantiate and return services from a Dagger Function, and then:
  - Use those services in other Dagger Functions (container-to-container networking)
  - Use those services from the calling host (container-to-host networking)
- Expose host services for use in a Dagger Function (host-to-container networking).

Some common scenarios for using services with Dagger Functions are:

- Running a database service for local storage or testing
- Running end-to-end integration tests against a service
- Running sidecar services

## Service containers

Services instantiated by a Dagger Function run in service containers, which have the following characteristics:

- Each service container has a canonical, content-addressed hostname and an optional set of exposed ports.
- Service containers are started just-in-time, de-duplicated, and stopped when no longer needed.
- Service containers are health checked prior to running clients.

## Bind services in functions

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

## Expose services returned by functions to the host

Services returned by Dagger Functions can also be exposed directly to the host. This enables clients on the host to communicate with services running in Dagger.

Here is another example call for the Dagger Function shown previously, this time exposing the HTTP service on the host:

```bash
dagger call http-service up
```

By default, each service port maps to the same port on the host - in this case, port 8080. The service can then be accessed by clients on the host:

```bash
curl localhost:8080
```

The result will be:

```
Hello, world!
```

To specify a different mapping, use the additional `--ports` argument with a list of host/service port mappings. Here's an example, which exposes the service on host port 9000:

```bash
dagger call http-service up --ports 9000:8080
```

> **Note:** To bind ports randomly, use the `--random` argument.

## Expose host services to functions

Dagger Functions can also receive host services as function arguments of type `Service`, in the form `tcp://<host>:<port>`. This enables client containers in Dagger Functions to communicate with services running on the host.

> **Note:** This implies that a service is already listening on a port on the host, out-of-band of Dagger.

Here is an example of how a container running in a Dagger Function can access and query a MariaDB database service (bound using the alias `db`) running on the host.

Before calling this Dagger Function, use the following command to start a MariaDB database service on the host:

```bash
docker run --rm --detach -p 3306:3306 --name my-mariadb --env MARIADB_ROOT_PASSWORD=secret  mariadb:10.11.2
```

Here is an example call for this Dagger Function:

```bash
dagger call user-list --svc=tcp://localhost:3306
```

The result will be:

```
Host    User
%       root
localhost       mariadb.sys
localhost       root
```

## Create interdependent services

Global hostnames can be assigned to services. This feature is especially valuable for complex networking configurations, such as circular dependencies between services, by allowing services to reference each other by predefined hostnames, without requiring an explicit service binding.

Custom hostnames follow a structured format (`<host>.<module id>.<session id>.dagger.local`), ensuring unique identifiers across modules and sessions.

## Use service endpoints

Every service has an endpoint, and this endpoint can be obtained via the Dagger API. This feature is typically useful in two scenarios:

- When a target container (which you bind the service to) is unable to resolve the service with the bound alias.
- When a service needs to be accessible (for example, over standard HTTP) without needing another container to access it.

## Persist service state

Dagger cancels each service run after a 10 second grace period to avoid frequent restarts. To avoid relying on the grace period, use a cache volume to persist a service's data.

## Start and stop services

Services are designed to be expressed as a Directed Acyclic Graph (DAG) with explicit bindings allowing services to be started lazily, just like every other DAG node. But sometimes, you may need to explicitly manage the lifecycle in a Dagger Function.

For example, this may be needed if the application in the service has certain behavior on shutdown (such as flushing data) that needs careful coordination with the rest of your logic.
