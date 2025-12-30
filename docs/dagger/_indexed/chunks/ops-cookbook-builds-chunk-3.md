---
doc_id: ops/cookbook/builds
chunk_id: ops/cookbook/builds#chunk-3
heading_path: ["builds", "Perform a matrix build"]
chunk_type: code
tokens: 590
summary: "The following Dagger Function performs a matrix build."
---
The following Dagger Function performs a matrix build.

### Go

```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
	"fmt"
)

type MyModule struct{}

// Build and return directory of go binaries
func (m *MyModule) Build(
	ctx context.Context,
	// Source code location
	src *dagger.Directory,
) *dagger.Directory {
	// define build matrix
	gooses := []string{"linux", "darwin"}
	goarches := []string{"amd64", "arm64"}

	// create empty directory to put build artifacts
	outputs := dag.Directory()

	golang := dag.Container().
		From("golang:latest").
		WithDirectory("/src", src).
		WithWorkdir("/src")

	for _, goos := range gooses {
		for _, goarch := range goarches {
			// create directory for each OS and architecture
			path := fmt.Sprintf("build/%s/%s/", goos, goarch)

			// build artifact
			build := golang.
				WithEnvVariable("GOOS", goos).
				WithEnvVariable("GOARCH", goarch).
				WithExec([]string{"go", "build", "-o", path})

			// add build to outputs
			outputs = outputs.WithDirectory(path, build.Directory(path))
		}
	}

	// return build directory
	return outputs
}
```

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    async def build(self, src: dagger.Directory) -> dagger.Directory:
        """Build and return directory of go binaries"""
        # define build matrix
        gooses = ["linux", "darwin"]
        goarches = ["amd64", "arm64"]

        # create empty directory to put build artifacts
        outputs = dag.directory()

        golang = (
            dag.container()
            .from_("golang:latest")
            .with_directory("/src", src)
            .with_workdir("/src")
        )

        for goos in gooses:
            for goarch in goarches:
                # create directory for each OS and architecture
                path = f"build/{goos}/{goarch}/"

                # build artifact
                build = (
                    golang.with_env_variable("GOOS", goos)
                    .with_env_variable("GOARCH", goarch)
                    .with_exec(["go", "build", "-o", path])
                )

                # add build to outputs
                outputs = outputs.with_directory(path, build.directory(path))

        return await outputs
```

### TypeScript

```typescript
import { dag, Container, Directory, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Build and return directory of go binaries
   */
  @func()
  build(src: Directory): Directory {
    // define build matrix
    const gooses = ["linux", "darwin"]
    const goarches = ["amd64", "arm64"]

    // create empty directory to put build artifacts
    let outputs = dag.directory()

    const golang = dag
      .container()
      .from("golang:latest")
      .withDirectory("/src", src)
      .withWorkdir("/src")

    for (const goos of gooses) {
      for (const goarch of goarches) {
        // create a directory for each OS and architecture
        const path = `build/${goos}/${goarch}/`

        // build artifact
        const build = golang
          .withEnvVariable("GOOS", goos)
          .withEnvVariable("GOARCH", goarch)
          .withExec(["go", "build", "-o", path])

        // add build to outputs
        outputs = outputs.withDirectory(path, build.directory(path))
      }
    }

    return outputs
  }
}
```

### Example

Perform a matrix build of the source code in the `golang/example/hello` repository and export build directory with go binaries for different operating systems and architectures.

```bash
dagger call \
    build --src="https://github.com/golang/example#master:hello" \
    export --path=/tmp/matrix-builds
```

Inspect the contents of the exported directory with `tree /tmp/matrix-builds`. The output should look like this:

```
/tmp/matrix-builds
└── build
    ├── darwin
    │   ├── amd64
    │   │   └── hello
    │   └── arm64
    │       └── hello
    └── linux
        ├── amd64
        │   └── hello
        └── arm64
            └── hello

8 directories, 4 files
```
