---
doc_id: ops/cookbook/services
chunk_id: ops/cookbook/services#chunk-4
heading_path: ["services", "Expose host services to Dagger Functions"]
chunk_type: code
tokens: 367
summary: "The following Dagger Function accepts a `Service` running on the host, binds it using an alias, a..."
---
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
