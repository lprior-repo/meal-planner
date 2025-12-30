---
doc_id: ops/features/observability
chunk_id: ops/features/observability#chunk-2
heading_path: ["observability", "Interactive terminal"]
chunk_type: code
tokens: 179
summary: "Workflow failures can be both frustrating and lead to wasted resources as the team seeks to under..."
---
Workflow failures can be both frustrating and lead to wasted resources as the team seeks to understand what went wrong and why. Dagger's interactive debugging feature is an invaluable tool in this situation.

Dagger lets users drop in to an interactive shell when a workflow run fails, with all the context at the point of failure. This is similar to a debugger experience, but without needing to set breakpoints explicitly. No changes are required to your code.

Here's an example of a workflow run failing, and Dagger opening an interactive terminal at the point of failure (Go):

```go
package main

import "context"

type MyModule struct{}

func (m *MyModule) Foo(ctx context.Context) (string, error) {
    return dag.Container().
        From("alpine:latest").
        WithExec([]string{"sh", "-c", "echo hello world > /foo"}).
        WithExec([]string{"cat", "/FOO"}). // deliberate error
        Stdout(ctx)
}

// run with dagger call --interactive foo
```
