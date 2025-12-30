---
doc_id: concept/features/services
chunk_id: concept/features/services#chunk-4
heading_path: ["services", "Host services"]
chunk_type: code
tokens: 113
summary: "This also works in the opposite direction: containers in Dagger Functions can communicate with se..."
---
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
