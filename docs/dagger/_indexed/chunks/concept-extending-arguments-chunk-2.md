---
doc_id: concept/extending/arguments
chunk_id: concept/extending/arguments#chunk-2
heading_path: ["arguments", "String arguments"]
chunk_type: code
tokens: 92
summary: "Here is an example of a Dagger Function that accepts a string argument:

**Go:**
```go
package ma..."
---
Here is an example of a Dagger Function that accepts a string argument:

**Go:**
```go
package main

import (
	"context"
	"fmt"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) GetUser(ctx context.Context, gender string) (string, error) {
	return dag.Container().
		From("alpine:latest").
		WithExec([]string{"apk", "add", "curl"}).
		WithExec([]string{"apk", "add", "jq"}).
		WithExec([]string{"sh", "-c", fmt.Sprintf("curl https://randomuser.me/api/?gender=%s | jq .results[0].name", gender)}).
		Stdout(ctx)
}
```

Here is an example call for this Dagger Function:

```bash
dagger call get-user --gender=male
```
