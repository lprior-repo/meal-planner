# Build a CI Workflow

CI workflows often start simple, but eventually transform into a labyrinth of artisanal shell scripts and/or unmanageable YAML code. Dagger lets you replace those artisanal scripts and YAML with a modern API and cross-language scripting engine.

> **Note:** This quickstart will guide you through building a CI workflow for an application using Dagger.

## Requirements

This quickstart will take you approximately 10 minutes to complete. You should be familiar with programming in Go, Python, TypeScript, PHP, or Java.

Before beginning, ensure that:

- you have [installed the Dagger CLI](/getting-started/installation).
- you know [the basics of Dagger](/getting-started/quickstarts/basics).
- you have Git and a container runtime installed on your system and running.
- you have a GitHub account (optional, only if configuring Dagger Cloud)

> **Tip:** Dagger SDKs generate native code-bindings for all dependencies from the Dagger API. Setting up your IDE to work with Dagger is highly recommended.

## Get the example application

The example application is a skeleton Vue framework application that returns a "Hello from Dagger!" welcome page. Create a Github repository from the [hello-dagger-template](https://github.com/dagger/hello-dagger-template):

With the `gh` CLI:

```bash
gh repo create hello-dagger --template dagger/hello-dagger-template --public --clone
cd hello-dagger
```

## Configure Dagger Cloud (optional)

> **Important:** This step is optional and will create a Dagger Cloud account, which is free of charge for a single user.

Dagger Cloud is an online visualization tool for Dagger workflows.

```bash
dagger login
```

## Initialize a Dagger module

Bootstrap a new Dagger module by running `dagger init` in the application's root directory:

**Go:**
```bash
dagger init --sdk=go --name=hello-dagger
```

**Python:**
```bash
dagger init --sdk=python --name=hello-dagger
```

**TypeScript:**
```bash
dagger init --sdk=typescript --name=hello-dagger
```

**PHP:**
```bash
dagger init --sdk=php --name=hello-dagger
```

**Java:**
```bash
dagger init --sdk=java --name=hello-dagger
```

This will generate a `dagger.json` module metadata file and a `.dagger` directory containing boilerplate Dagger Functions.

To see the generated Dagger Functions, run:

```bash
dagger functions
```

## Construct a workflow

Replace the generated Dagger module files with code that adds four Dagger Functions:

- The `publish` Dagger Function tests, builds and publishes a container image of the application to a registry.
- The `test` Dagger Function runs the application's unit tests and returns the results.
- The `build` Dagger Function performs a multi-stage build and returns a final container image with the production-ready application and an NGINX Web server.
- The `build-env` Dagger Function creates a container with the build environment for the application.

**Go (`main.go`):**
```go
package main

import (
	"context"
	"fmt"
	"math"
	"math/rand"

	"dagger/hello-dagger/internal/dagger"
)

type HelloDagger struct{}

// Publish the application container after building and testing it on-the-fly
func (m *HelloDagger) Publish(
	ctx context.Context,
	// +defaultPath="/"
	source *dagger.Directory,
) (string, error) {
	_, err := m.Test(ctx, source)
	if err != nil {
		return "", err
	}
	return m.Build(source).
		Publish(ctx, fmt.Sprintf("ttl.sh/hello-dagger-%.0f", math.Floor(rand.Float64()*10000000)))
}

// Build the application container
func (m *HelloDagger) Build(
	// +defaultPath="/"
	source *dagger.Directory,
) *dagger.Container {
	build := m.BuildEnv(source).
		WithExec([]string{"npm", "run", "build"}).
		Directory("./dist")
	return dag.Container().From("nginx:1.25-alpine").
		WithDirectory("/usr/share/nginx/html", build).
		WithExposedPort(80)
}

// Return the result of running unit tests
func (m *HelloDagger) Test(
	ctx context.Context,
	// +defaultPath="/"
	source *dagger.Directory,
) (string, error) {
	return m.BuildEnv(source).
		WithExec([]string{"npm", "run", "test:unit", "run"}).
		Stdout(ctx)
}

// Build a ready-to-use development environment
func (m *HelloDagger) BuildEnv(
	// +defaultPath="/"
	source *dagger.Directory,
) *dagger.Container {
	nodeCache := dag.CacheVolume("node")
	return dag.Container().
		From("node:21-slim").
		WithDirectory("/src", source).
		WithMountedCache("/root/.npm", nodeCache).
		WithWorkdir("/src").
		WithExec([]string{"npm", "install"})
}
```

## Run the workflow

Type `dagger` to launch Dagger Shell in interactive mode:

```
publish
```

This single command runs the application's tests, then builds and publishes it as a container image to the ttl.sh container registry.

You can test the published container image by pulling and running it with `docker run`.

## Interact with the build environment

The `build-env` Dagger Function returns a `Container` type. Use `terminal` to open an interactive terminal session:

```
build-env | terminal --cmd=bash
```

This command builds the container image and then drops you into an interactive terminal running the `bash` shell.

## Run a container as a local service

The `build` Dagger Function returns a `Container` type. Use `as-service` to start a container as a local service:

```
build | as-service | up --ports=8080:80
```

By default, Dagger will map each exposed container service port to the same port on the host. Since NGINX operates on port 80, the additional `--ports 8080:80` argument re-maps container port 80 to host port 8080.

You should now be able to access the application by browsing to `http://localhost:8080`.

## Next steps

Congratulations! You've created your first CI workflow with Dagger.

Now you have the tools to successfully take the next step:

- [adopting Dagger in your project](/reference/best-practices/adopting)
- [Use a Blueprint Module](/getting-started/quickstarts/blueprint)
- [Build an AI Agent](/getting-started/quickstarts/agent-in-project)
