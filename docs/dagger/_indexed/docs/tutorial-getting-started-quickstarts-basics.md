---
id: tutorial/getting-started/quickstarts-basics
title: "Basics"
category: tutorial
tags: ["tutorial", "ci", "module", "function", "container"]
---

# Basics

> **Context**: Welcome to Dagger, a general-purpose composition engine for containerized workflows.


Welcome to Dagger, a general-purpose composition engine for containerized workflows.

Dagger is a modular, composable platform designed to replace complex systems glued together with artisanal scripts - for example, complex integration testing environments, data processing pipelines, and AI agent workflows. It is open source and works with any compute platform or technology stack, automatically optimizing for speed and cost.

## Requirements

This quickstart will take you approximately 10 minutes to complete. You should be familiar with programming in Go, Python, TypeScript, PHP, or Java.

Before beginning, ensure that:

- you have [installed the Dagger CLI](./ops-getting-started-installation.md).
- you have a container runtime installed on your system and running. This can be Docker, Podman, nerdctl, Apple Container, or other Docker-like systems.
- you have a GitHub account (optional, only if configuring Dagger Cloud).

## Create containers

Dagger works by expressing workflows as combinations of functions from the Dagger API, which exposes a range of tools for working with containers, files, directories, network services, secrets. You call the Dagger API from the shell (Dagger Shell) or from code (custom Dagger Functions written in a programming language).

Dagger Shell is an interactive client for the Dagger API. You launch it by typing:

```bash
dagger
```

Here's an example of using it to build and return an Alpine container:

```
container | from alpine
```

You can open an interactive terminal session with the running container:

```
container | from alpine | terminal
```

## Execute commands

You can run commands in the container and return the output:

```
container | from alpine | with-exec uname | stdout
```

Here's an example of installing the `curl` package and using it to retrieve a webpage:

```
container | from alpine | with-exec apk add curl | with-exec curl https://dagger.io | stdout
```

### Getting Help

The Dagger API is extensively documented. Simply append `.help` to your in-progress workflow for context-sensitive assistance:

```
container | from alpine | .help
container | from alpine | .help with-directory
container | from alpine | .help with-exec
```

## Add files and directories

You can modify containers by adding files or directories:

```
container | from alpine | with-directory /src https://github.com/dagger/dagger
```

Here's another example, creating a new file in the container:

```
container | from alpine | with-new-file /hi.txt "Hello from Dagger!"
```

To look inside, request an interactive terminal session:

```
container | from alpine | with-new-file /hi.txt "Hello from Dagger!" | terminal
```

> **Tip:** The `terminal` function is very useful for debugging and experimenting, since it allows you to interact directly with containers and inspect their state.

## Chain functions in the shell

You can chain Dagger API function calls with the pipe (`|`) operator. This is one of Dagger's most powerful features, allowing you to create dynamic workflows in a single command.

Example: Creating an Alpine container, adding a text file, setting it to display that message when run, and publishing it to a temporary registry:

```
container | from alpine | with-new-file /hi.txt "Hello from Dagger!" |
  with-entrypoint cat /hi.txt | publish ttl.sh/hello
```

## Write custom functions

As your workflows become more complex, you can encapsulate them into custom Dagger Functions. These are just regular code consisting of a series of method/function calls.

Here's an example Dagger Function:

**Go:**
```go
func (m *Basics) Publish(ctx context.Context) (string, error) {
	return dag.Container().
		From("alpine:latest").
		WithNewFile("/hi.txt", "Hello from Dagger!").
		WithEntrypoint([]string{"cat", "/hi.txt"}).
		Publish(ctx, "ttl.sh/hello")
}
```

**Python:**
```python
@function
async def publish(self) -> str:
    return await (
        dag.container()
        .from_("alpine:latest")
        .with_new_file("/hi.txt", "Hello from Dagger!")
        .with_entrypoint(["cat", "/hi.txt"])
        .publish("ttl.sh/hello")
    )
```

**TypeScript:**
```typescript
@func()
async publish(): Promise<string> {
  return dag
    .container()
    .from("alpine:latest")
    .withNewFile("/hi.txt", "Hello from Dagger!")
    .withEntrypoint(["cat", "/hi.txt"])
    .publish("ttl.sh/hello")
}
```

To use this function, initialize a new Dagger module:

```bash
dagger init --sdk=go --name=basics  # or python, typescript
```

### Function Names

When calling Dagger Functions, all names (functions, arguments, fields, etc.) are converted into a shell-friendly "kebab-case" style. This is why a Dagger Function named `FooBar` in Go, `foo_bar` in Python and `fooBar` in TypeScript is called as `foo-bar` in Dagger Shell.

## Use arguments and return values

Dagger Functions accept arguments and return values. In addition to common types (string, boolean, integer, arrays...), the Dagger API also defines powerful types like `Directory`, `Container`, `Service`, `Secret`.

### Sandboxing

Dagger Functions are fully "sandboxed" and do not have direct access to the host system. Host resources such as directories, files, environment variables, network services must be explicitly passed as arguments.

## Install other modules

You can group Dagger Functions into modules and share them with others. The [Daggerverse](https://daggerverse.dev) is a free service that indexes all publicly available Dagger modules.

Example of installing and using modules:

```
dagger install github.com/purpleclay/daggerverse/wolfi
dagger install github.com/jpadams/daggerverse/trivy@v0.5.0
```

> **Cross-language collaboration:** Dagger Functions can call other Dagger Functions, across languages. For example, a Dagger Function written in Python can call a Dagger Function written in Go, which can call another one written in TypeScript.

## Speed things up

Dagger provides powerful caching features:

- **Layers**: Build instructions and the results of some API calls.
- **Volumes**: Contents of Dagger filesystem volumes.

Example using a cache volume for `apt` packages:

**Go:**
```go
func (m *Basics) Env(ctx context.Context) *dagger.Container {
	aptCache := dag.CacheVolume("apt-cache")
	return dag.Container().
		From("debian:latest").
		WithMountedCache("/var/cache/apt/archives", aptCache).
		WithExec([]string{"apt-get", "update"}).
		WithExec([]string{"apt-get", "install", "--yes", "maven", "mariadb-server"})
}
```

## Trace everything

Dagger provides two powerful real-time observability tools:

- **Dagger terminal UI (TUI)**: For local development
- **Dagger Cloud**: A browser-based interface for tracing and debugging

Sign up for Dagger Cloud (optional, free for single user):

```bash
dagger login
```

## Next steps

Now that you know the basics of Dagger, continue your journey:

- [Build a CI workflow](/getting-started/quickstarts/ci)
- [Build an AI Agent](/getting-started/quickstarts/agent)
- [Learn about the Dagger API](/extending)
- [Learn about Dagger Shell](./ops-features-shell.md)
- [Learn about Dagger Functions](./concept-extending-functions.md)
- [Visit the Daggerverse](https://daggerverse.dev/)
- [See more examples in the Cookbook](/cookbook)

## See Also

- [installed the Dagger CLI](./ops-getting-started-installation.md)
- [Learn about Dagger Shell](./ops-features-shell.md)
