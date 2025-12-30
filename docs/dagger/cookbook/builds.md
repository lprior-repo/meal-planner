# Builds

This page contains practical examples for building artifacts (files and directories) with Dagger. Each section below provides code examples in multiple languages and demonstrates different approaches to building artifacts.

## Perform a multi-stage build

The following Dagger Function performs a multi-stage build.

### Go

```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Build and publish Docker container
func (m *MyModule) Build(
	ctx context.Context,
	// source code location
	// can be local directory or remote Git repository
	src *dagger.Directory,
) (string, error) {
	// build app
	builder := dag.Container().
		From("golang:latest").
		WithDirectory("/src", src).
		WithWorkdir("/src").
		WithEnvVariable("CGO_ENABLED", "0").
		WithExec([]string{"go", "build", "-o", "myapp"})

	// publish binary on alpine base
	prodImage := dag.Container().
		From("alpine").
		WithFile("/bin/myapp", builder.File("/src/myapp")).
		WithEntrypoint([]string{"/bin/myapp"})

	// publish to ttl.sh registry
	addr, err := prodImage.Publish(ctx, "ttl.sh/myapp:latest")
	if err != nil {
		return "", err
	}

	return addr, nil
}
```

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    def build(self, src: dagger.Directory) -> str:
        """Build and publish Docker container"""
        # build app
        builder = (
            dag.container()
            .from_("golang:latest")
            .with_directory("/src", src)
            .with_workdir("/src")
            .with_env_variable("CGO_ENABLED", "0")
            .with_exec(["go", "build", "-o", "myapp"])
        )

        # publish binary on alpine base
        prod_image = (
            dag.container()
            .from_("alpine")
            .with_file("/bin/myapp", builder.file("/src/myapp"))
            .with_entrypoint(["/bin/myapp"])
        )

        # publish to ttl.sh registry
        addr = prod_image.publish("ttl.sh/myapp:latest")

        return addr
```

### TypeScript

```typescript
import { dag, Container, Directory, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Build and publish Docker container
   */
  @func()
  build(src: Directory): Promise<string> {
    // build app
    const builder = dag
      .container()
      .from("golang:latest")
      .withDirectory("/src", src)
      .withWorkdir("/src")
      .withEnvVariable("CGO_ENABLED", "0")
      .withExec(["go", "build", "-o", "myapp"])

    // publish binary on alpine base
    const prodImage = dag
      .container()
      .from("alpine")
      .withFile("/bin/myapp", builder.file("/src/myapp"))
      .withEntrypoint(["/bin/myapp"])

    // publish to ttl.sh registry
    const addr = prodImage.publish("ttl.sh/myapp:latest")

    return addr
  }
}
```

### Example

Perform a multi-stage build of the source code in the `golang/example/hello` repository and publish the resulting image:

```bash
dagger call build --src="https://github.com/golang/example#master:hello"
```

## Perform a matrix build

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

## Build multi-arch image

The following Dagger Function builds a single image for different CPU architectures using native emulation.

### Go

```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Build and publish multi-platform image
func (m *MyModule) Build(
	ctx context.Context,
	// Source code location
	// can be local directory or remote Git repository
	src *dagger.Directory,
) (string, error) {
	// platforms to build for and push in a multi-platform image
	var platforms = []dagger.Platform{
		"linux/amd64", // a.k.a. x86_64
		"linux/arm64", // a.k.a. aarch64
		"linux/s390x", // a.k.a. IBM S/390
	}

	// container registry for the multi-platform image
	const imageRepo = "ttl.sh/myapp:latest"

	platformVariants := make([]*dagger.Container, 0, len(platforms))
	for _, platform := range platforms {
		// pull golang image for this platform
		ctr := dag.Container(dagger.ContainerOpts{Platform: platform}).
			From("golang:1.20-alpine").
			// mount source code
			WithDirectory("/src", src).
			// mount empty dir where built binary will live
			WithDirectory("/output", dag.Directory()).
			// ensure binary will be statically linked and thus executable
			// in the final image
			WithEnvVariable("CGO_ENABLED", "0").
			// build binary and put result at mounted output directory
			WithWorkdir("/src").
			WithExec([]string{"go", "build", "-o", "/output/hello"})

		// select output directory
		outputDir := ctr.Directory("/output")

		// wrap the output directory in the new empty container marked
		// with the same platform
		binaryCtr := dag.Container(dagger.ContainerOpts{Platform: platform}).
			WithRootfs(outputDir)

		platformVariants = append(platformVariants, binaryCtr)
	}

	// publish to registry
	imageDigest, err := dag.Container().
		Publish(ctx, imageRepo, dagger.ContainerPublishOpts{
			PlatformVariants: platformVariants,
		})
	if err != nil {
		return "", err
	}

	// return build directory
	return imageDigest, nil
}
```

### Example

Build and publish a multi-platform image:

```bash
dagger call build --src="https://github.com/golang/example#master:hello"
```

## Build image from Dockerfile

The following Dagger Function builds an image from a Dockerfile.

### Go

```go
package main

import (
	"context"
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Build and publish image from existing Dockerfile
func (m *MyModule) Build(
	ctx context.Context,
	// location of directory containing Dockerfile
	src *dagger.Directory,
) (string, error) {
	ref, err := src.
		DockerBuild(). // build from Dockerfile
		Publish(ctx, "ttl.sh/hello-dagger")
	if err != nil {
		return "", err
	}

	return ref, nil
}
```

### Python

```python
from typing import Annotated

import dagger
from dagger import Doc, function, object_type

@object_type
class MyModule:
    @function
    async def build(
        self,
        src: Annotated[
            dagger.Directory,
            Doc("location of directory containing Dockerfile"),
        ],
    ) -> str:
        """Build and publish image from existing Dockerfile"""
        ref = src.docker_build().publish("ttl.sh/hello-dagger")  # build from Dockerfile
        return await ref
```

### TypeScript

```typescript
import { dag, Directory, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Build and publish image from existing Dockerfile
   * @param src location of directory containing Dockerfile
   */
  @func()
  async build(src: Directory): Promise<string> {
    const ref = await src
      .dockerBuild() // build from Dockerfile
      .publish("ttl.sh/hello-dagger")
    return ref
  }
}
```

### Example

Build and publish an image from an existing Dockerfile

```bash
dagger call build --src="https://github.com/dockersamples/python-flask-redis"
```

## Cache application dependencies

The following Dagger Function uses a cache volume for application dependencies. This enables Dagger to reuse the contents of the cache across Dagger Function runs and reduce execution time.

### Go

```go
package main

import "dagger/my-module/internal/dagger"

type MyModule struct{}

// Build an application using cached dependencies
func (m *MyModule) Build(
	// Source code location
	source *dagger.Directory,
) *dagger.Container {
	return dag.Container().
		From("golang:1.21").
		WithDirectory("/src", source).
		WithWorkdir("/src").
		WithMountedCache("/go/pkg/mod", dag.CacheVolume("go-mod-121")).
		WithEnvVariable("GOMODCACHE", "/go/pkg/mod").
		WithMountedCache("/go/build-cache", dag.CacheVolume("go-build-121")).
		WithEnvVariable("GOCACHE", "/go/build-cache").
		WithExec([]string{"go", "build"})
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
    def build(
        self, source: Annotated[dagger.Directory, Doc("Source code location")]
    ) -> dagger.Container:
        """Build an application using cached dependencies"""
        return (
            dag.container()
            .from_("python:3.11")
            .with_directory("/src", source)
            .with_workdir("/src")
            # if using pip
            .with_mounted_cache("/root/.cache/pip", dag.cache_volume("pip_cache"))
            .with_exec(["pip", "install", "-r", "requirements.txt"])
            # if using poetry
            .with_mounted_cache(
                "/root/.cache/pypoetry", dag.cache_volume("poetry_cache")
            )
            .with_exec(
                [
                    "pip",
                    "install",
                    "--user",
                    "poetry==1.5.1",
                    "poetry-dynamic-versioning==0.23.0",
                ]
            )
            # No root first uses dependencies but not the project itself
            .with_exec(["poetry", "install", "--no-root", "--no-interaction"])
            .with_exec(["poetry", "install", "--no-interaction", "--only-root"])
        )
```

### TypeScript

```typescript
import { dag, Container, Directory, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Build an application using cached dependencies
   */
  @func()
  build(
    /**
     * Source code location
     */
    source: Directory,
  ): Container {
    return dag
      .container()
      .from("node:21")
      .withDirectory("/src", source)
      .withWorkdir("/src")
      .withMountedCache("/root/.npm", dag.cacheVolume("node-21"))
      .withExec(["npm", "install"])
  }
}
```

### Example

Build an application using cached dependencies:

```bash
dagger call build --source=.
```

## Invalidate cache

The following function demonstrates how to invalidate the Dagger layer cache and force execution of subsequent workflow steps, by introducing a volatile time variable at a specific point in the Dagger workflow.

> **Note**: This is a temporary workaround until cache invalidation support is officially added to Dagger. Changes in mounted cache volumes or secrets do not invalidate the Dagger layer cache.

### Go

```go
package main

import (
	"context"
	"time"
)

type MyModule struct{}

// Run a build with cache invalidation
func (m *MyModule) Build(
	ctx context.Context,
) (string, error) {
	output, err := dag.Container().
		From("alpine").
		// comment out the line below to see the cached date output
		WithEnvVariable("CACHEBUSTER", time.Now().String()).
		WithExec([]string{"date"}).
		Stdout(ctx)
	if err != nil {
		return "", err
	}

	return output, nil
}
```

### Python

```python
from datetime import datetime

from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    async def build(self) -> str:
        """Run a build with cache invalidation"""
        output = (
            dag.container()
            .from_("alpine")
            # comment out the line below to see the cached date output
            .with_env_variable("CACHEBUSTER", str(datetime.now()))
            .with_exec(["date"])
            .stdout()
        )

        return await output
```

### TypeScript

```typescript
import { dag, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Run a build with cache invalidation
   */
  @func()
  async build(): Promise<string> {
    const ref = await dag
      .container()
      .from("alpine")
      // comment out the line below to see the cached date output
      .withEnvVariable("CACHEBUSTER", Date.now().toString())
      .withExec(["date"])
      .stdout()
    return ref
  }
}
```

### Example

Print the date and time, invalidating the cache on each run. However, if the `CACHEBUSTER` environment variable is removed, the same value (the date and time on the first run) is printed on every run.

```bash
dagger call build
```
