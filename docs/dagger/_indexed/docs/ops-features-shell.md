---
id: ops/features/shell
title: "Interactive Shell"
category: ops
tags: ["ops", "pipeline", "module", "function", "container"]
---

# Interactive Shell

> **Context**: The Dagger CLI includes an interactive shell that translates the familiar Bash syntax to Dagger API requests. It's the simplest and fastest way to run...


The Dagger CLI includes an interactive shell that translates the familiar Bash syntax to Dagger API requests. It's the simplest and fastest way to run Dagger workflows directly from the command-line.

You can use it for builds, tests, ephemeral environments, deployments, or any other task you want to automate from the terminal.

> **Important:** Dagger Shell commands run as sandboxed functions, accessing host resources (files, secrets, services) only when explicitly provided as arguments. This can make commands slightly more verbose, but also more repeatable, giving you confidence to iterate quickly without second-guessing.

Here's an example of Dagger Shell in action:

```bash
container | from alpine | with-exec apk add curl | with-exec -- curl -L https://dagger.io | stdout
```

Here's another, more complex example:

```bash
container |
  from cgr.dev/chainguard/wolfi-base |
  with-exec apk add go |
  with-directory /src https://github.com/golang/example#master |
  with-workdir /src/hello |
  with-exec -- go build -o hello . |
  file ./hello |
  export ./hello-from-dagger
```

## Behavior

Dagger Shell uses the Bash syntax as a frontend, but its behavior is quite different in the backend:

- Instead of executing UNIX commands, you execute Dagger Functions
- Instead of passing text streams from command to command, you pass typed objects from function to function
- Instead of available commands being the same everywhere in the pipeline, each command is executed in the context of the previous command's output object. For example, `foo | bar` really means `foo().bar()`
- Instead of using the local host as an execution environment, you use containerized runtimes
- Instead of being mixed with regular commands, shell builtins are prefixed with `.` (similar to SQLite)

Besides these differences, all the features of the Bash syntax are available in Dagger Shell, including:

- **Shell variables**: `container=$(container | from alpine)`
- **Shell functions**: `container() { container | from alpine; }`
- **Job control**: `frontend | test & backend | test & .wait`
- **Quoting**: single quotes and double quotes have the same meaning as in Bash

## Input modes

Dagger Shell supports multiple ways to input commands:

- Inline execution
- Standard input
- Script
- Interactive REPL

```bash
dagger -c 'container | from alpine | terminal'
```

```bash
dagger <<EOF
container | from alpine | terminal
EOF
```

```bash
#!/usr/bin/env dagger
container |
from alpine |
with-exec cat /etc/os-release |
stdout
```

Interactive mode (type 'dagger' for interactive mode):
```bash
container | from alpine | terminal
```

## Modules

Dagger Shell can load modules, inspect their types, and run their functions. This works for both local and remote modules.

For example, try running this command:

```bash
dagger -m github.com/dagger/dagger/docs@v0.18.5
```

This loads the module `github.com/dagger/dagger/docs` at version `v0.18.5`. Wait for the Dagger Shell interactive prompt, then:

```bash
.help
```

We see new commands available, loaded from the module. Let's try running one:

```bash
server | up
```

This builds the docs server defined in the module, and runs it as an ephemeral service [on your machine](http://localhost:8080).

You can load multiple modules in the same session, each scoped to a single pipeline, then combine those pipelines into a bigger pipeline. For example:

```bash
dagger <<.
github.com/dagger/dagger/modules/wolfi | container --packages=nginx | with-directory /var/www $(
  github.com/dagger/dagger/docs | site
)
.
```

This loads `github.com/dagger/dagger/docs` into one pipeline, `github.com/dagger/dagger/modules/wolfi` into another, then combines them.

This works by executing the module's [constructor function](./concept-extending-constructors.md). It works exactly like executing any other function:

- You can inspect it for arguments: `.help MODULE`
- You can pass arguments: `MODULE --foo=bar --baz`
- You can save it to a variable: `foo=$(MODULE)`
- You can use it in a pipeline: `MODULE | foo | bar`
- You can use that pipeline as a sub-pipeline: `foo --bar=$(MODULE | foo | bar)`

## Variables

Dagger Shell lets you save the result of any command to a variable, using the standard bash syntax. Values of any type can be saved to a variable, including objects.

Here's an example:

```bash
dagger <<'.'
repo=$(git https://github.com/dagger/hello-dagger | head | tree)
env=$(container | from node:23 | with-directory /app $repo | with-workdir /app)
build=$($env | with-exec npm install | with-exec npm run build | directory ./dist)
container | from nginx | with-directory /usr/share/nginx/html $build | terminal --cmd=/bin/bash
.
```

Or in interactive mode:

```bash
repo=$(git https://github.com/dagger/hello-dagger | head | tree)
env=$(container | from node:23 | with-directory /app $repo | with-workdir /app)
build=$($env | with-exec npm install | with-exec npm run build | directory ./dist)
container | from nginx | with-directory /usr/share/nginx/html $build | terminal --cmd=/bin/bash
```

## See Also

- [constructor function](./concept-extending-constructors.md)
