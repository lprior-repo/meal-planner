---
doc_id: ops/features/observability
chunk_id: ops/features/observability#chunk-3
heading_path: ["observability", "Breakpoints"]
chunk_type: code
tokens: 130
summary: "You can also set one or more explicit breakpoints in your workflow, which then starts an interact..."
---
You can also set one or more explicit breakpoints in your workflow, which then starts an interactive terminal session at each breakpoint. This lets you inspect a directory or a container at any point in your workflow run, with all the necessary context available to you.

Here's another example, which opens an interactive terminal at two different points in a workflow run to inspect the built container (Go):

```go
package main

import (
    "context"
    "dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) Foo(ctx context.Context) *dagger.Container {
    return dag.Container().
        From("alpine:latest").
        Terminal().
        WithExec([]string{"sh", "-c", "echo hello world > /foo"}).
        Terminal()
}
```
