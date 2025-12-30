---
id: concept/extending/arguments
title: "Arguments"
category: concept
tags: ["ci", "module", "function", "container", "concept"]
---

# Arguments

> **Context**: Dagger Functions, just like regular functions, can accept arguments. In addition to basic types (string, boolean, integer, arrays...), Dagger also def...


Dagger Functions, just like regular functions, can accept arguments. In addition to basic types (string, boolean, integer, arrays...), Dagger also defines powerful core types which Dagger Functions can use for their arguments, such as `Directory`, `Container`, `Service`, `Secret`, and many more.

When calling a Dagger Function from the CLI, its arguments are exposed as command-line flags. How the flag is interpreted depends on the argument type.

> **Important:** Dagger Functions execute in containers and thus do not have default access to your host environment (host files, directories, environment variables, etc.). Access to these host resources can only be granted by explicitly passing them as argument values to the Dagger Function.

- **Files and directories**: Dagger Functions can accept arguments of type `File` or `Directory`. Pass files and directories on your host by specifying their path as the value of the argument.
- **Environment variables**: Pass environment variable values as argument values when invoking a function by just using the standard shell convention of using `$ENV_VAR_NAME`.
- **Local network services**: Dagger Functions that accept an argument of type `Service` can be passed local network services in the form `tcp://HOST:PORT`.
- **Sockets**: Dagger Functions that accept an argument of type `Socket` can be passed host sockets in the form `$SOCKET`.

> **Note:** When passing values to Dagger Functions within Dagger Shell, required arguments are positional, while flags can be placed anywhere.

## String arguments

Here is an example of a Dagger Function that accepts a string argument:

**Go:**
```go
package main

import (
	"context"
	"fmt"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) GetUser(ctx context.Context, gender string) (string, error) {
	return dag.Container().
		From("alpine:latest").
		WithExec([]string{"apk", "add", "curl"}).
		WithExec([]string{"apk", "add", "jq"}).
		WithExec([]string{"sh", "-c", fmt.Sprintf("curl https://randomuser.me/api/?gender=%s | jq .results[0].name", gender)}).
		Stdout(ctx)
}
```

Here is an example call for this Dagger Function:

```bash
dagger call get-user --gender=male
```

## Boolean arguments

Here is an example of a Dagger Function that accepts a Boolean argument:

**Go:**
```go
package main

import (
	"strings"
)

type MyModule struct{}

func (m *MyModule) Hello(shout bool) string {
	message := "Hello, world"
	if shout {
		return strings.ToUpper(message)
	}
	return message
}
```

Here is an example call for this Dagger Function:

```bash
dagger call hello --shout=true
```

The result will look like this:

```
HELLO, WORLD
```

> **Note:** When passing optional boolean flags:
> - To set the argument to true: `--foo=true` or `--foo`
> - To set the argument to false: `--foo=false`

## Directory arguments

You can also pass a directory argument from the command-line. To do so, add the corresponding flag, followed by a local filesystem path or a [remote Git reference](./tutorial-extending-remote-repositories.md). In both cases, the CLI will convert it to an object referencing the contents of that filesystem path or Git repository location, and pass the resulting `Directory` object as argument to the Dagger Function.

## File arguments

File arguments work in the same way as [directory arguments](#directory-arguments). To pass a file to a Dagger Function as an argument, add the corresponding flag, followed by a local filesystem path or a remote Git reference.

## Container arguments

Just like directories, you can pass a container to a Dagger Function from the command-line. To do so, add the corresponding flag, followed by the address of an OCI image. The CLI will dynamically pull the image, and pass the resulting `Container` object as argument to the Dagger Function.

## Secret arguments

Dagger allows you to utilize confidential information, such as passwords, API keys, SSH keys and so on, in your Dagger [modules](./ops-features-reusability.md) and Dagger Functions, without exposing those secrets in plaintext logs, writing them into the filesystem of containers you're building, or inserting them into the cache.

Secrets can be passed to Dagger Functions as arguments using the `Secret` type. When invoking the Dagger Function using the Dagger CLI, secrets can be sourced from multiple providers:

- Host environment: `env://VARIABLE_NAME`
- Host filesystem: `file://./path/to/file`
- Host command execution: `cmd://"command"`
- 1Password: `op://VAULT-NAME/ITEM-NAME/FIELD-NAME`
- Vault: `vault://PATH/TO/SECRET.ITEM`

## Service arguments

Host network services or sockets can be passed to Dagger Functions as arguments. To do so, add the corresponding flag, followed by a service or socket reference.

### TCP and UDP services

To pass host TCP or UDP network services as arguments when invoking a Dagger Function, specify them in the form `tcp://HOST:PORT` or `udp://HOST:PORT`.

### Unix sockets

Similar to host TCP/UDP services, Dagger Functions can also be granted access to host Unix sockets when the client is running on Linux or MacOS.

To pass host Unix sockets as arguments when invoking a Dagger Function, specify them by their path on the host.

## Optional arguments

Function arguments can be marked as optional. In this case, the Dagger CLI will not display an error if the argument is omitted in the function call.

## Default values

Function arguments can define a default value if no value is supplied for them.

## See Also

- [remote Git reference](./tutorial-extending-remote-repositories.md)
- [modules](./ops-features-reusability.md)
