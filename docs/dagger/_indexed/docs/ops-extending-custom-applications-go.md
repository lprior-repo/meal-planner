---
id: ops/extending/custom-applications-go
title: "Go Custom Application"
category: ops
tags: ["ops", "directory", "module", "sdk", "go"]
---

# Go Custom Application

> **Context**: > **Note:** The Dagger Go SDK requires [Go 1.22 or later](https://go.dev/doc/install).


> **Note:** The Dagger Go SDK requires [Go 1.22 or later](https://go.dev/doc/install).

From an existing Go module, install the Dagger Go SDK using the commands below:

```bash
go get dagger.io/dagger@latest
```

After importing `dagger.io/dagger` in your Go module code, run the following command to update `go.sum`:

```bash
go mod tidy
```

This example demonstrates how to build a Go application for multiple architectures and Go versions using the Go SDK.

Clone an example project and create a new Go module in the project directory:

```bash
git clone https://go.googlesource.com/example
cd example/hello
mkdir multibuild && cd multibuild
go mod init multibuild
```

Create a new file in the `multibuild` directory named `main.go` and add the following code to it:

```go
package main

import (
	"context"
	"fmt"

	"dagger.io/dagger/dag"
)

func main() {
	if err := build(context.Background()); err != nil {
		fmt.Println(err)
	}
}

func build(ctx context.Context) error {
	fmt.Println("Building with Dagger")

	// define build matrix
	oses := []string{"linux", "darwin"}
	arches := []string{"amd64", "arm64"}
	goVersions := []string{"1.22", "1.23"}

	defer dag.Close()

	// get reference to the local project
	src := dag.Host().Directory(".")

	// create empty directory to put build outputs
	outputs := dag.Directory()

	for _, version := range goVersions {
		// get `golang` image for specified Go version
		imageTag := fmt.Sprintf("golang:%s", version)
		golang := dag.Container().From(imageTag)
		// mount cloned repository into `golang` image
		golang = golang.WithDirectory("/src", src).WithWorkdir("/src")

		for _, goos := range oses {
			for _, goarch := range arches {
				// create a directory for each os, arch and version
				path := fmt.Sprintf("build/%s/%s/%s/", version, goos, goarch)

				// set GOARCH and GOOS in the build environment
				build := golang.WithEnvVariable("GOOS", goos)
				build = build.WithEnvVariable("GOARCH", goarch)

				// build application
				build = build.WithExec([]string{"go", "build", "-o", path})

				// get reference to build output directory in container
				outputs = outputs.WithDirectory(path, build.Directory(path))
			}
		}
	}
	// write build artifacts to host
	_, err := outputs.Export(ctx, ".")
	if err != nil {
		return err
	}

	return nil
}
```

This Go program imports the Dagger SDK and defines two functions. The `build()` function represents the workflow and creates a Dagger client, which provides an interface to the Dagger API. It also defines the build matrix, consisting of two OSs (`darwin` and `linux`) and two architectures (`amd64` and `arm64`), and builds the Go application for each combination. The Go build process is instructed via the `GOOS` and `GOARCH` build variables, which are reset for each case.

Try the Go program by executing the command below from the project directory:

```bash
dagger run go run multibuild/main.go
```

The `dagger run` command executes the specified command in a Dagger session and displays live progress. The Go program builds the application for each OS/architecture combination and writes the build results to the host. You will see the build process run four times, once for each combination. Note that the builds are happening concurrently, because the builds do not depend on eachother.

Use the `tree` command to see the build artifacts on the host, as shown below:

```
tree build
build
├── 1.22
│   ├── darwin
│   │   ├── amd64
│   │   │   └── hello
│   │   └── arm64
│   │       └── hello
│   └── linux
│       ├── amd64
│       │   └── hello
│       └── arm64
│           └── hello
└── 1.23
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
```

## See Also

- [Documentation Overview](./COMPASS.md)
