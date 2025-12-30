---
doc_id: concept/extending/arguments
chunk_id: concept/extending/arguments#chunk-1
heading_path: ["arguments"]
chunk_type: prose
tokens: 330
summary: "> **Context**: Dagger Functions, just like regular functions, can accept arguments."
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
