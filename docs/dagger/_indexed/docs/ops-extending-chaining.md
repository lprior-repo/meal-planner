---
id: ops/extending/chaining
title: "Chaining"
category: ops
tags: ["ops", "ci", "module", "function", "container"]
---

# Chaining

> **Context**: Function chaining is one of Dagger's most powerful features, as it allows you to dynamically compose complex workflows by connecting one Dagger Functi...


Function chaining is one of Dagger's most powerful features, as it allows you to dynamically compose complex workflows by connecting one Dagger Function with another. The following sections demonstrate a few more examples of function chaining with the Dagger CLI.

## Execute commands in containers

The Dagger CLI can add follow-up processing to a just-in-time container, essentially enabling you to continue the workflow directly from the command-line. `Container` objects expose a `withExec()` API method, which lets you execute a command in the corresponding container.

Here is an example of chaining a `Container.withExec()` call to a container returned by a Wolfi container builder Dagger Function, to execute a command that displays the contents of the `/etc/` directory:

**System shell:**
```bash
dagger <<EOF
github.com/dagger/dagger/modules/wolfi@v0.16.2 |
  container |
  with-exec ls /etc/ |
  stdout
EOF
```

**Dagger Shell:**
```
github.com/dagger/dagger/modules/wolfi@v0.16.2 |
  container |
  with-exec ls /etc/ |
  stdout
```

**Dagger CLI:**
```bash
dagger -m github.com/dagger/dagger/modules/wolfi@v0.16.2 call \
  container \
  with-exec --args="ls","/etc/" \
  stdout
```

## Live-debug container builds

`Container` objects expose a `terminal()` API method, which lets you starting an ephemeral interactive terminal session in the corresponding container. This feature is very useful for debugging and experimenting since it allows you to inspect containers directly and at any stage of your Dagger Function execution.

Here is an example of chaining a `Container.terminal()` function call to start an interactive terminal in the container returned by a Wolfi container builder Dagger Function:

**System shell:**
```bash
dagger -c 'github.com/dagger/dagger/modules/wolfi@v0.16.2 | container --packages=cowsay | terminal'
```

**Dagger Shell:**
```
github.com/dagger/dagger/modules/wolfi@v0.16.2 | container --packages=cowsay | terminal
```

**Dagger CLI:**
```bash
dagger -m github.com/dagger/dagger/modules/wolfi@v0.16.2 call \
  container --packages="cowsay" \
  terminal
```

## Export directories, files and containers

When a host directory or file is copied or mounted to a container's filesystem, modifications made to it in the container do not automatically transfer back to the host. Data flows only one way between Dagger operations, because they are connected in a DAG. To transfer modifications back to the local host, you must explicitly export the directory or file back to the host filesystem.

Just-in-time artifacts such as containers, directories and files can be exported to the host filesystem from the Dagger Function that produced them using the `export` function. The destination path on the host is specified using the `--path` argument.

Here is an example of exporting the build directory returned by a Go builder Dagger Function to the `./my-build` directory on the host:

**System shell:**
```bash
dagger <<EOF
github.com/kpenfound/dagger-modules/golang@v0.2.1 |
  build ./cmd/dagger --source=https://github.com/dagger/dagger |
  export ./my-build
EOF
```

**Dagger Shell:**
```
github.com/kpenfound/dagger-modules/golang@v0.2.1 |
  build ./cmd/dagger --source=https://github.com/dagger/dagger |
  export ./my-build
```

**Dagger CLI:**
```bash
dagger -m github.com/kpenfound/dagger-modules/golang@v0.2.1 call \
  build --source=https://github.com/dagger/dagger --args=./cmd/dagger \
  export --path=./my-build
```

## Publish containers

Every `Container` object exposes a `Container.publish()` API method, which publishes the container as a new image to a specified container registry. The registry address is passed to the function using the `--address` argument, and the return value is a string referencing the container image address in the registry.

Here is an example of publishing the container returned by a Wolfi container builder Dagger Function to the `ttl.sh` registry, by chaining a `Container.publish()` call:

**System shell:**
```bash
dagger -c 'github.com/dagger/dagger/modules/wolfi@v0.16.2 | container | publish ttl.sh/my-wolfi'
```

**Dagger Shell:**
```
github.com/dagger/dagger/modules/wolfi@v0.16.2 | container | publish ttl.sh/my-wolfi
```

**Dagger CLI:**
```bash
dagger -m github.com/dagger/dagger/modules/wolfi@v0.16.2 call container publish --address=ttl.sh/my-wolfi
```

## Start containers as services

Every `Container` object exposes a `Container.asService()` API method, which turns the container into a `Service`. These services can then be spun up for use by other Dagger Functions or by clients on the Dagger host by forwarding their ports. This is akin to a "programmable docker-compose".

To start a `Service` returned by a Dagger Function and have it forward traffic to a specified address via the host, chain a call to the `Service.up()` API method.

Here is an example of starting an NGINX service on host port 80 by chaining calls to `Container.asService()` and `Service.up()`:

**System shell:**
```bash
dagger -c 'github.com/kpenfound/dagger-modules/nginx@v0.1.0 | container | as-service | up'
```

**Dagger Shell:**
```
github.com/kpenfound/dagger-modules/nginx@v0.1.0 | container | as-service | up
```

**Dagger CLI:**
```bash
dagger -m github.com/dagger/dagger/modules/wolfi@v0.16.2 call container as-service up
```

## Modify container filesystems

Here is an example of modifying a container by adding the current directory from the host to the container filesystem at `/src`, by chaining a call to the `Container.withDirectory()` method:

> **Warning:** The example below uploads the entire current directory to the container filesystem. This can take a significant amount of time with large directories. To reduce the time spent on upload, run this example from a directory containing only a few small files.

**System shell:**
```bash
dagger <<EOF
github.com/dagger/dagger/modules/wolfi@v0.16.2 |
  container |
  with-directory /src . |
  with-exec ls /src |
  stdout
EOF
```

**Dagger Shell:**
```
github.com/dagger/dagger/modules/wolfi@v0.16.2 |
  container |
  with-directory /src . |
  with-exec ls /src |
  stdout
```

**Dagger CLI:**
```bash
dagger -m github.com/dagger/dagger/modules/wolfi@v0.16.2 call \
  container \
  with-directory --path=/src --directory=. \
  with-exec --args="ls","/src" \
  stdout
```

## See Also

- [Documentation Overview](./COMPASS.md)
