# Services

This page contains practical examples for working with services in Dagger. Each section below provides code examples in multiple languages and demonstrates different approaches to service management.

## Bind and use services in Dagger Functions

The first Dagger Function below creates and returns an HTTP service. This service is bound and used from a different Dagger Function, via a service binding using an alias like `www`.

### Go

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

    @function
    async def get(self) -> str:
        """Send a request to an HTTP service and return the response."""
        return await (
            dag.container()
            .from_("alpine")
            .with_service_binding("www", self.http_service())
            .with_exec(["wget", "-O-", "http://www:8080"])
            .stdout()
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

  /**
   * Send a request to an HTTP service and return the response
   */
  @func()
  async get(): Promise<string> {
    return await dag
      .container()
      .from("alpine")
      .withServiceBinding("www", this.httpService())
      .withExec(["wget", "-O-", "http://www:8080"])
      .stdout()
  }
}
```

### Example

Send a request from one Dagger Function to a bound HTTP service instantiated by a different Dagger Function:

```bash
dagger call get
```

## Expose services in Dagger Functions to the host

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

## Expose host services to Dagger Functions

The following Dagger Function accepts a `Service` running on the host, binds it using an alias, and creates a client to access it via the service binding. This example uses a MariaDB database service running on host port 3306, aliased as `db` in the Dagger Function.

> **Note**: This implies that a service is already listening on a port on the host, out-of-band of Dagger.

### Go

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

### Python

```python
from typing import Annotated

import dagger
from dagger import Doc, dag, function, object_type

@object_type
class MyModule:
    @function
    async def user_list(
        self, svc: Annotated[dagger.Service, Doc("Host service")]
    ) -> str:
        """Send a query to a MariaDB service and return the response."""
        return await (
            dag.container()
            .from_("mariadb:10.11.2")
            .with_service_binding("db", svc)
            .with_exec(
                [
                    "/usr/bin/mysql",
                    "--user=root",
                    "--password=secret",
                    "--host=db",
                    "-e",
                    "SELECT Host, User FROM mysql.user",
                ]
            )
            .stdout()
        )
```

### TypeScript

```typescript
import { dag, object, func, Service } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Send a query to a MariaDB service and return the response
   */
  @func()
  async userList(
    /**
     * Host service
     */
    svc: Service,
  ): Promise<string> {
    return await dag
      .container()
      .from("mariadb:10.11.2")
      .withServiceBinding("db", svc)
      .withExec([
        "/usr/bin/mysql",
        "--user=root",
        "--password=secret",
        "--host=db",
        "-e",
        "SELECT Host, User FROM mysql.user",
      ])
      .stdout()
  }
}
```

### Example

Send a query to the database service listening on host port 3306 and return the result as a string:

```bash
dagger call user-list --svc=tcp://localhost:3306
```

## Create a transient service for unit tests

The following Dagger Function creates a service and binds it to an application container for unit testing. In this example, the application being tested is Drupal. Drupal includes a large number of unit tests, including tests which depend on an active database service. This database service is created on-the-fly by the Dagger Function.

### Go

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

### Python

```python
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    async def test(self) -> str:
        """Run unit tests against a database service."""
        # get MariaDB base image
        mariadb = (
            dag.container()
            .from_("mariadb:10.11.2")
            .with_env_variable("MARIADB_USER", "user")
            .with_env_variable("MARIADB_PASSWORD", "password")
            .with_env_variable("MARIADB_DATABASE", "drupal")
            .with_env_variable("MARIADB_ROOT_PASSWORD", "root")
            .with_exposed_port(3306)
            .as_service(use_entrypoint=True)
        )

        # get Drupal base image
        # install additional dependencies
        drupal = (
            dag.container()
            .from_("drupal:10.0.7-php8.2-fpm")
            .with_exec(
                [
                    "composer",
                    "require",
                    "drupal/core-dev",
                    "--dev",
                    "--update-with-all-dependencies",
                ]
            )
        )

        # add service binding for MariaDB
        # run kernel tests using PHPUnit
        return await (
            drupal.with_service_binding("db", mariadb)
            .with_env_variable("SIMPLETEST_DB", "mysql://user:password@db/drupal")
            .with_env_variable("SYMFONY_DEPRECATIONS_HELPER", "disabled")
            .with_workdir("/opt/drupal/web/core")
            .with_exec(["../../vendor/bin/phpunit", "-v", "--group", "KernelTests"])
            .stdout()
        )
```

### TypeScript

```typescript
import { dag, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Run unit tests against a database service
   */
  @func()
  async test(): Promise<string> {
    const mariadb = dag
      .container()
      .from("mariadb:10.11.2")
      .withEnvVariable("MARIADB_USER", "user")
      .withEnvVariable("MARIADB_PASSWORD", "password")
      .withEnvVariable("MARIADB_DATABASE", "drupal")
      .withEnvVariable("MARIADB_ROOT_PASSWORD", "root")
      .withExposedPort(3306)
      .asService({ useEntrypoint: true })

    // get Drupal base image
    // install additional dependencies
    const drupal = dag
      .container()
      .from("drupal:10.0.7-php8.2-fpm")
      .withExec([
        "composer",
        "require",
        "drupal/core-dev",
        "--dev",
        "--update-with-all-dependencies",
      ])

    // add service binding for MariaDB
    // run kernel tests using PHPUnit
    return await drupal
      .withServiceBinding("db", mariadb)
      .withEnvVariable("SIMPLETEST_DB", "mysql://user:password@db/drupal")
      .withEnvVariable("SYMFONY_DEPRECATIONS_HELPER", "disabled")
      .withWorkdir("/opt/drupal/web/core")
      .withExec(["../../vendor/bin/phpunit", "-v", "--group", "KernelTests"])
      .stdout()
  }
}
```

### Example

Run Drupal's unit tests, instantiating a database service during the process:

```bash
dagger call test
```

## Start and stop services

The following Dagger Function demonstrates how to control a service's lifecycle by explicitly starting and stopping a service. This example uses a Redis service.

### Go

```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Explicitly start and stop a Redis service
func (m *MyModule) RedisService(ctx context.Context) (string, error) {
	redisSrv := dag.Container().
		From("redis").
		WithExposedPort(6379).
		AsService(dagger.ContainerAsServiceOpts{UseEntrypoint: true})

	// start Redis ahead of time so it stays up for the duration of the test
	redisSrv, err := redisSrv.Start(ctx)
	if err != nil {
		return "", err
	}

	// stop the service when done
	defer redisSrv.Stop(ctx)

	// create Redis client container
	redisCLI := dag.Container().
		From("redis").
		WithServiceBinding("redis-srv", redisSrv)

	args := []string{"redis-cli", "-h", "redis-srv"}

	// set value
	setter, err := redisCLI.
		WithExec(append(args, "set", "foo", "abc")).
		Stdout(ctx)
	if err != nil {
		return "", err
	}

	// get value
	getter, err := redisCLI.
		WithExec(append(args, "get", "foo")).
		Stdout(ctx)
	if err != nil {
		return "", err
	}

	return setter + getter, nil
}
```

### Python

```python
import contextlib

import dagger
from dagger import dag, function, object_type

@contextlib.asynccontextmanager
async def managed_service(svc: dagger.Service):
    """Start and stop a service."""
    yield await svc.start()
    await svc.stop()

@object_type
class MyModule:
    @function
    async def redis_service(self) -> str:
        """Explicitly start and stop a Redis service."""
        redis_srv = dag.container().from_("redis").with_exposed_port(6379).as_service()

        # start Redis ahead of time so it stays up for the duration of the test
        # and stop when done
        async with managed_service(redis_srv) as redis_srv:
            # create Redis client container
            redis_cli = (
                dag.container()
                .from_("redis")
                .with_service_binding("redis-srv", redis_srv)
            )

            args = ["redis-cli", "-h", "redis-srv"]

            # set value
            setter = await redis_cli.with_exec([*args, "set", "foo", "abc"]).stdout()

            # get value
            getter = await redis_cli.with_exec([*args, "get", "foo"]).stdout()

            return setter + getter
```

### TypeScript

```typescript
import { dag, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Explicitly start and stop a Redis service
   */
  @func()
  async redisService(): Promise<string> {
    let redisSrv = dag
      .container()
      .from("redis")
      .withExposedPort(6379)
      .asService()

    // start Redis ahead of time so it stays up for the duration of the test
    redisSrv = await redisSrv.start()

    // stop the service when done
    await redisSrv.stop()

    // create Redis client container
    const redisCLI = dag
      .container()
      .from("redis")
      .withServiceBinding("redis-srv", redisSrv)

    const args = ["redis-cli", "-h", "redis-srv"]

    // set value
    const setter = await redisCLI
      .withExec([...args, "set", "foo", "abc"])
      .stdout()

    // get value
    const getter = await redisCLI.withExec([...args, "get", "foo"]).stdout()

    return setter + getter
  }
}
```

### Example

Start and stop a Redis service:

```bash
dagger call redis-service
```

## Create interdependent services

The following Dagger Function runs two services, service A and service B, that depend on each other. The services are set up with custom hostnames, `svca` and `svcb`, allowing each service to communicate with the other by hostname.

### Go

```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Run two services which are dependent on each other
func (m *MyModule) Services(ctx context.Context) (*dagger.Service, error) {
	svcA := dag.Container().From("nginx").
		WithExposedPort(80).
		AsService(dagger.ContainerAsServiceOpts{Args: []string{"sh", "-c", `nginx & while true; do curl svcb:80 && sleep 1; done`}}).
		WithHostname("svca")
	_, err := svcA.Start(ctx)
	if err != nil {
		return nil, err
	}

	svcB := dag.Container().From("nginx").
		WithExposedPort(80).
		AsService(dagger.ContainerAsServiceOpts{Args: []string{"sh", "-c", `nginx & while true; do curl svca:80 && sleep 1; done`}}).
		WithHostname("svcb")
	svcB, err = svcB.Start(ctx)
	if err != nil {
		return nil, err
	}

	return svcB, nil
}
```

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    async def services(self) -> dagger.Service:
        """Run two services which are dependent on each other"""
        svc_a = (
            dag.container()
            .from_("nginx")
            .with_exposed_port(80)
            .as_service(
                args=[
                    "sh",
                    "-c",
                    "nginx & while true; do curl svcb:80 && sleep 1; done",
                ]
            )
            .with_hostname("svca")
        )
        await svc_a.start()

        svc_b = (
            dag.container()
            .from_("nginx")
            .with_exposed_port(80)
            .as_service(
                args=[
                    "sh",
                    "-c",
                    "nginx & while true; do curl svca:80 && sleep 1; done",
                ]
            )
            .with_hostname("svcb")
        )
        await svc_b.start()

        return svc_b
```

### TypeScript

```typescript
import { dag, object, func, Service } from "@dagger.io/dagger"

@object()
class MyModule {
  // Run two services which are dependent on each other
  @func()
  async services(): Promise<Service> {
    const svcA = dag
      .container()
      .from("nginx")
      .withExposedPort(80)
      .asService({
        args: [
          "sh",
          "-c",
          `nginx & while true; do curl svcb:80 && sleep 1; done`,
        ],
      })
      .withHostname("svca")
    await svcA.start()

    const svcB = dag
      .container()
      .from("nginx")
      .withExposedPort(80)
      .asService({
        args: [
          "sh",
          "-c",
          `nginx & while true; do curl svca:80 && sleep 1; done`,
        ],
      })
      .withHostname("svcb")
    await svcB.start()

    return svcB
  }
}
```

### Example

Start two inter-dependent services:

```bash
dagger call services up --ports 8080:80
```
