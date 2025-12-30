---
id: meta/extending/modules
title: "Module Initialization"
category: meta
tags: ["ci", "docker", "meta", "module", "container"]
---

# Module Initialization

> **Context**: A new Dagger module is initialized by calling `dagger init`. This creates a new `dagger.json` configuration file in the current working directory, tog...


A new Dagger module is initialized by calling `dagger init`. This creates a new `dagger.json` configuration file in the current working directory, together with sample Dagger Function source code. The configuration file will default the name of the module to the current directory name, unless an alternative is specified with the `--name` argument.

Once a module is initialized, `dagger develop --sdk=...` sets up or updates all the resources needed to develop the module locally. By default, the module source code will be stored in the current working directory, unless an alternative is specified with the `--source` argument.

> **Warning:** Running `dagger develop` regenerates the module's code based on dependencies, the current state of the module, and the current Dagger API version. This can result in unexpected results if there are significant changes between the previous and latest installed Dagger API versions. Always refer to the [changelog](https://github.com/dagger/dagger/blob/main/CHANGELOG.md) for a complete list of changes (including breaking changes) in each Dagger release before running `dagger develop`, or use the `--compat=skip` option to bypass updating the Dagger API version.

The default template from `dagger develop` creates the following structure:

**Go:**
```
.
├── LICENSE
├── dagger.gen.go
├── go.mod
├── go.sum
├── internal
│   ├── dagger
│   ├── querybuilder
│   └── telemetry
└── main.go
└── dagger.json
```

**Python:**
```
.
├── LICENSE
├── pyproject.toml
├── uv.lock
├── sdk
├── src
│   └── my_module
│       ├── __init__.py
│       └── main.py
└── dagger.json
```

**TypeScript:**
```
.
├── LICENSE
├── package.json
├── sdk
├── src
│   └── index.ts
└── tsconfig.json
└── dagger.json
```

**PHP:**
```
.
├── composer.json
├── composer.lock
├── dagger.json
├── LICENSE
├── README.md
├── sdk
├── src
│    └── MyModule.php
└── vendor
```

**Java:**
```
.
├── dagger.json
├── pom.xml
├── src
│   └── main
│       └── java
│           └── io
│               └── dagger
│                   └── modules
│                       └── mymodule
│                           ├── MyModule.java
│                           └── package-info.java
└── target
    └── generated-sources
        ├── dagger-io
        ├── dagger-module
        └── entrypoint
```

> **Note:** While you can use the utilities defined in the automatically-generated code above, you *cannot* edit these files. Even if you edit them locally, any changes will not be persisted when you run the module.

## File layout

### Multiple files

**Go:**

You can split your Dagger module into multiple files, not just `main.go`. To do this, you can just create another file beside `main.go` (for example, `utils.go`):

```
.
│── ...
│── main.go
│── utils.go
└── dagger.json
```

This file should be inside the same package as `main.go`, and as such, can access any private variables/functions/types inside the package.

Additionally, you can also split your Dagger module into Go subpackages (for example, `utils`):

```
.
│── ...
│── main.go
|── utils
│   └── utils.go
└── dagger.json
```

Because this is a separate package, you can only use the variables/functions/types that are exported from this package in `main.go` (you can't access types from `main.go` in the `utils` package).

> **Note:** Only types and functions in the top-level package are part of the public-facing API for the module.

**Python:**

The Dagger module's code in Python can be split into multiple files by making a [package](https://docs.python.org/3/tutorial/modules.html#packages) and ensuring the *main object* is imported in `__init__.py`. All the other object types should already be imported from there.

**TypeScript:**

Due to TypeScript limitations, it is not possible to split your main class module (`index.ts`) into multiple files. However, it is possible to create sub-classes in different files and access them from your main class module.

**PHP:**

Only functions from your main class (`MyModule.php`) can initially be called by Dagger. However, it is possible to create other classes and access them from your main class.

**Java:**

The Dagger module's code in Java can be split into multiple classes, in multiple files. A few constraints apply:
- The main Dagger object must be represented by a class using the same name as the module, in PascalCase.
- The exposed objects must be annotated with `@Object` and the exposed functions with `@Function`.

## Runtime container

Dagger modules run in a runtime container that's bootstrapped by the Dagger Engine, with the necessary environment to run the Dagger module's code.

- **Go:** The runtime container is currently hardcoded to run in Go 1.21 (although this may be configurable in future).
- **Python:** The runtime container is based on the [python:3.13-slim](https://hub.docker.com/_/python/tags?name=3.13-slim) base image by default, but it can be overridden by setting `requires-python`, or pinned with a `.python-version` file.
- **TypeScript:** The runtime container is currently hardcoded to run in Node.js 22.11.0. [Bun](https://bun.sh/) 1.1.38 and [Deno](https://deno.com/) 2.2.4 are experimentally supported.
- **PHP:** The runtime container is currently hardcoded to run in [php:8.3-cli-alpine](https://hub.docker.com/_/php/tags?name=8.3-cli-alpine).
- **Java:** Two containers are used by the runtime, one to build the module into a JAR file, one to run it. They are currently hardcoded to run in [maven:3.9.9-eclipse-temurin-17](https://hub.docker.com/_/maven/tags?name=3.9.9-eclipse-temurin-17) and [eclipse-temurin:23-jre-noble](https://hub.docker.com/_/eclipse-temurin/tags?name=23-jre-noble) respectively.

## Language-native packaging

The structure of a Dagger module mimics that of each language's conventional packaging mechanisms and tools.

- **Go:** Dagger modules written for use with the Go SDK are automatically created as [Go modules](https://go.dev/ref/mod).
- **Python:** Dagger modules in Python are built to be installed, like libraries. At module creation time, a `pyproject.toml` and `uv.lock` file will automatically be created.
- **TypeScript:** Dagger modules in Typescript are built to be installed, like libraries. The runtime container installs the module code with `yarn install --production`.
- **PHP:** Dagger modules in PHP are built to be installed, like libraries. The runtime container installs the module code with `composer install`.
- **Java:** Dagger modules in Java are built as JAR files, using Maven. The runtime container builds the module code with `mvn clean package`.

## Remote modules

Dagger can use [remote repositories](./tutorial-extending-remote-repositories.md) as Dagger [modules](./ops-features-reusability.md). This feature is compatible with all major Git hosting platforms such as GitHub, GitLab, BitBucket, Azure DevOps, Codeberg, and Sourcehut. Dagger supports authentication via both HTTPS (using Git credential managers) and SSH (using a unified authentication approach).

Here is an example of using a Go builder Dagger module from a public repository over HTTPS:

```bash
dagger -m github.com/kpenfound/dagger-modules/golang@v0.2.0 call \
  build --source=https://github.com/dagger/dagger --args=./cmd/dagger \
  export --path=./build
```

Here is the same example using SSH authentication. Note that this requires [SSH authentication to be properly configured](./tutorial-extending-remote-repositories.md#ssh-authentication) on your Dagger host.

```bash
dagger -m git@github.com:kpenfound/dagger-modules/golang@v0.2.0 call \
  build --source=https://github.com/dagger/dagger --args=./cmd/dagger \
  export --path=./build
```

For more information, refer to the documentation on [remote repository access](./tutorial-extending-remote-repositories.md).

## See Also

- [remote repositories](./tutorial-extending-remote-repositories.md)
- [modules](./ops-features-reusability.md)
- [SSH authentication to be properly configured](./tutorial-extending-remote-repositories.md)
- [remote repository access](./tutorial-extending-remote-repositories.md)
