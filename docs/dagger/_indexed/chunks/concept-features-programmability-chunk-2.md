---
doc_id: concept/features/programmability
chunk_id: concept/features/programmability#chunk-2
heading_path: ["programmability", "Functions"]
chunk_type: code
tokens: 136
summary: "Dagger Functions are the fundamental unit of computing in Dagger."
---
Dagger Functions are the fundamental unit of computing in Dagger. Dagger Functions let you encapsulate common project operations or workflows, such as "pull a container image", "copy a file", and "forward a TCP port", into portable, reusable program code with clear inputs and outputs.

### Example

Here's an example of a Dagger Function that builds and containerizes a Go application (Go):

```go
package main

import (
    "context"
    "dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) Build(
    ctx context.Context,
    src *dagger.Directory,
    arch string,
    os string,
) *dagger.Container {
    return dag.Container().
        From("golang:1.21").
        WithMountedDirectory("/src", src).
        WithWorkdir("/src").
        WithEnvVariable("GOARCH", arch).
        WithEnvVariable("GOOS", os).
        WithEnvVariable("CGO_ENABLED", "0").
        WithExec([]string{"go", "build", "-o", "build/"})
}
```
