---
doc_id: concept/extending/return-types
chunk_id: concept/extending/return-types#chunk-4
heading_path: ["return-types", "Container return values"]
chunk_type: code
tokens: 135
summary: "Just-in-time containers are produced by calling a Dagger Function that returns the `Container` type."
---
Just-in-time containers are produced by calling a Dagger Function that returns the `Container` type. This type provides a complete API for building, running and distributing containers.

Here's an example of a Dagger Function that returns a base `alpine` container image with a list of additional specified packages:

**Go:**
```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) AlpineBuilder(ctx context.Context, packages []string) *dagger.Container {
	ctr := dag.Container().
		From("alpine:latest")
	for _, pkg := range packages {
		ctr = ctr.WithExec([]string{"apk", "add", pkg})
	}
	return ctr
}
```

Here is an example call for this Dagger Function:

```bash
dagger call alpine-builder --packages=curl,openssh
```
