---
doc_id: concept/extending/return-types
chunk_id: concept/extending/return-types#chunk-3
heading_path: ["return-types", "Directory return values"]
chunk_type: code
tokens: 233
summary: "Directory return values might be produced by a Dagger Function that:
- Builds language-specific b..."
---
Directory return values might be produced by a Dagger Function that:
- Builds language-specific binaries
- Downloads source code from git or another remote source
- Processes source code (for example, generating documentation or linting code)
- Downloads or processes datasets
- Downloads machine learning models

Here is an example of a Go builder Dagger Function that accepts a remote Git address as a `Directory` argument, builds a Go binary from the source code in that repository, and returns the build directory containing the compiled binary:

**Go:**
```go
package main

import (
	"context"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) GoBuilder(ctx context.Context, src *dagger.Directory, arch string, os string) *dagger.Directory {
	return dag.Container().
		From("golang:1.21").
		WithMountedDirectory("/src", src).
		WithWorkdir("/src").
		WithEnvVariable("GOARCH", arch).
		WithEnvVariable("GOOS", os).
		WithEnvVariable("CGO_ENABLED", "0").
		WithExec([]string{"go", "build", "-o", "build/"}).
		Directory("/src/build")
}
```

Here is an example call for this Dagger Function:

```bash
dagger call go-builder --src=https://github.com/golang/example#master:/hello --arch=amd64 --os=linux
```

Once the command completes, you should see this output:

```
_type: Directory
entries:
    - hello
```

This means that the build succeeded, and a `Directory` type representing the build directory was returned.
