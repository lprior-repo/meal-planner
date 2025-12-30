---
id: concept/getting-started/concepts
title: "Key Concepts"
category: concept
tags: ["service", "module", "function", "container", "concept"]
---

# Key Concepts

> **Context**: The Dagger API is an unified interface for composing Dagger workflows. It provides a set of functions and types for creating and managing application...


The Dagger API is an unified interface for composing Dagger workflows. It provides a set of functions and types for creating and managing application delivery workflows, including types for containers, files, directories, network services, secrets, and more. You can call these functions from `dagger`, the Dagger CLI, or from custom functions written in any supported programming language.

## Functions

To create a workflow with the Dagger API, you call multiple functions, combining them together in sequence to form a workflow. Here's an example:

**System shell:**
```bash
dagger <<EOF
container |
  from alpine |
  file /etc/os-release |
  contents
EOF
```

**Dagger Shell:**
```
container |
  from alpine |
  file /etc/os-release |
  contents
```

**Dagger CLI:**
```bash
dagger core container \
  from --address=alpine \
  file --path=/etc/os-release \
  contents
```

This example calls multiple functions from the Dagger API in sequence to create a workflow that builds an image from an `alpine` container and returns the contents of the `/etc/os-release` file to the caller.

## Types

Like regular functions, Dagger functions can accept arguments. You can see this in the previous example: the `from` function accepts a container image address (`--address`) as argument, the file function accepts a filesystem location (`--path`) as argument, and so on.

In addition to supporting basic types (string, boolean, integer, array...), the Dagger API also provides [powerful types](./concept-getting-started-types.md) for working with workflows, such as `Container`, `GitRepository`, `Directory`, `Service`, `Secret`. You can use these types as arguments to Dagger functions.

## Chaining

Each of Dagger's types comes with functions of its own, which can be used to interact with the corresponding object.

When calling a Dagger function that returns a type, the Dagger API lets you follow up by calling one of that type's functions, which itself can return another type, and so on. This is called "function chaining", and is a core feature of Dagger.

For example, if a Dagger function returns a `Directory`, the caller can continue the chain by calling a function from the `Directory` type to export it to the local filesystem, modify it, mount it into a container, and so on.

Here is an example that chains multiple function calls into a workflow that builds the Dagger CLI from source and exports it to the Dagger host:

**System shell:**
```bash
dagger <<EOF
container |
  from golang:latest |
  with-directory /src https://github.com/dagger/dagger#main |
  with-workdir /src/cmd/dagger |
  with-exec -- go build -o dagger . |
  file ./dagger |
  export ./dagger.bin
EOF
```

In this workflow:
- `from` returns a `golang` container image as a `Container` type
- `with-directory` adds the Dagger open source repository to the container image filesystem
- `with-workdir` sets the working directory to the Dagger repository
- `with-exec` compiles the Dagger CLI
- `file` returns the built binary as a `File` type
- `export` exports the binary artifact to the Dagger host as `./dagger.bin`

Functions can be chained with the CLI, or programmatically in a [custom Dagger function](./concept-extending-functions.md) using a Dagger SDK.

## Modules

Dagger [modules](./meta-extending-modules.md) are collections of Dagger Functions, packaged together for easy sharing and consumption. They are portable and reusable across languages.

## Calling the Dagger API

You can call the Dagger API from code using a type-safe Dagger SDK, or from the command line using the Dagger CLI or the Dagger Shell.

The different ways to call the Dagger API are:

- From the Dagger CLI
  - [`dagger`, `dagger core` and `dagger call`](/getting-started/api/cli)
- From a custom application created with a Dagger SDK
  - [`dagger run`](/extending/custom-applications/go)
- From a [language-native GraphQL client](/getting-started/api/http#language-native-http-clients)
- From a command-line HTTP or GraphQL client
  - [`curl`](/getting-started/api/http#command-line-http-clients)
  - [`dagger query`](/getting-started/api/http#dagger-cli)

> **Note:** The Dagger CLI can call any Dagger function, either from your local filesystem or from a remote Git repository. They can be used interactively, from a shell script, or from a CI configuration. Apart from the Dagger CLI, no other infrastructure or tooling is required to call Dagger functions.

## Extending the Dagger API

The Dagger API is extensible and shareable by design. You can extend the API by creating Dagger [modules](./meta-extending-modules.md). You are encouraged to write your own Dagger modules and share them with others.

Dagger also lets you import and reuse modules developed by your team, your organization or the broader Dagger community. The [Daggerverse](https://daggerverse.dev) is a free service run by Dagger, which indexes all publicly available Dagger modules and Dagger functions, and lets you easily search and consume them.

When a Dagger module is loaded, the Dagger API is [dynamically extended](/reference/api/internals#dynamic-api-extension) with new Dagger Functions served by that module. So, after loading a Dagger module, an API client can now call all of the original core functions, plus the new Dagger Functions provided by that module.

You can also embed a Dagger SDK directly into your application using [Go](/extending/custom-applications/go).

## See Also

- [powerful types](./concept-getting-started-types.md)
- [custom Dagger function](./concept-extending-functions.md)
- [modules](./meta-extending-modules.md)
