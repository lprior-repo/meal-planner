# Types

In addition to basic types (string, boolean, integer, arrays...), the Dagger API also provides powerful types which you can use as both arguments and return values for Dagger Functions.

> **Note:** The types listed on this page are indicative and not exhaustive. For a complete list of supported types and their fields, refer to the [Dagger API reference](https://docs.dagger.io/api/reference).

The following table lists some of the available types and what they represent:

| Type | Description |
|------|-------------|
| [`CacheVolume`](/getting-started/types/cachevolume) | A directory whose contents persist across runs |
| [`Container`](/getting-started/types/container) | An OCI-compatible container |
| `CurrentModule` | The current Dagger module and its context |
| `Engine` | The Dagger Engine configuration and state |
| [`Directory`](/getting-started/types/directory) | A directory (local path or Git reference) |
| `EnvVariable` | An environment variable name and value |
| [`Env`](/getting-started/types/env) | An environment variable name and value |
| [`File`](/getting-started/types/file) | A file |
| [`GitRepository`](/getting-started/types/git) | A Git repository |
| `GitRef` | A Git reference (tag, branch, or commit) |
| `Host` | The Dagger host environment |
| [`LLM`](/getting-started/types/llm) | A Large Language Model (LLM) |
| `Module` | A Dagger module |
| `Port` | A port exposed by a container |
| [`Secret`](/getting-started/types/secret) | A secret credential like a password, access token or key |
| [`Service`](/getting-started/types/service) | A content-addressed service providing TCP connectivity |
| `Socket` | A Unix or TCP/IP socket that can be mounted into a container |
| `Terminal` | An interactive terminal session |

Each type exposes additional fields. Some of these are discussed below.

## Container

The `Container` type represents the state of an OCI-compatible container. This `Container` object is not merely a string referencing an image on a remote registry. It is the actual state of a container, managed by the Dagger Engine, and passed to a Dagger Function's code as if it were just another variable.

### Common operations

| Field | Description |
|-------|-------------|
| `from` | Initializes the container from a specified base image |
| `asService` | Turns the container into a `Service` |
| `asTarball` | Returns a serialized tarball of the container as a `File` |
| `export` / `import` | Writes / reads the container as an OCI tarball to / from a file path on the host |
| `publish` | Publishes the container image to a registry |
| `stdout` / `stderr` | Returns the output / error stream of the last executed command |
| `withDirectory` / `withMountedDirectory` | Returns the container plus a directory copied / mounted at the given path |
| `withEntrypoint` | Returns the container with a custom entrypoint command |
| `withExec` | Returns the container after executing a command inside it |
| `withFile` / `withMountedFile` | Returns the container plus a file copied / mounted at the given path |
| `withMountedCache` | Returns the container plus a cache volume mounted at the given path |
| `withRegistryAuth` | Returns the container with registry authentication configured |
| `withWorkdir` | Returns the container configured with a specific working directory |
| `withServiceBinding` | Returns the container with runtime dependency on another `Service` |
| `terminal` | Opens an interactive terminal for this container |

## CurrentModule

The `CurrentModule` type provides capabilities to introspect the Dagger Function's module and interface between the current execution environment and the Dagger API.

### Common operations

| Field | Description |
|-------|-------------|
| `source` | Returns the directory containing the module's source code |
| `workdir` | Loads and returns a directory from the module's working directory, including any changes that may have been made to it during function execution |
| `workdirFile` | Loads and returns a file from the module's working directory, including any changes that may have been made to it during function execution |

## Directory

Dagger Functions do not have access to the filesystem of the host you invoke the Dagger Function from (i.e. the host you execute a CLI command like `dagger` from). Instead, host files and directories need to be explicitly passed as command-line arguments to Dagger Functions.

There are two important reasons for this:

- **Reproducibility**: By providing a call-time mechanism to define and control the files available to a Dagger Function, Dagger guards against creating hidden dependencies on ambient properties of the host filesystem that could change at any moment.
- **Security**: By forcing you to explicitly specify which host files and directories a Dagger Function "sees" on every call, Dagger ensures that you're always 100% in control. This reduces the risk of third-party Dagger Functions gaining access to your data.

The `Directory` type represents the state of a directory. This could be either a local directory path or a remote Git reference.

### Common operations

| Field | Description |
|-------|-------------|
| `dockerBuild` | Builds a new Docker container from the directory |
| `entries` | Returns a list of files and directories in the directory |
| `export` | Writes the contents of the directory to a path on the host |
| `file` | Returns a file at the given path as a `File` |
| `withFile` / `withFiles` | Returns the directory plus the file(s) copied to the given path |

## File

The `File` type represents a single file.

### Common operations

| Field | Description |
|-------|-------------|
| `contents` | Returns the contents of the file |
| `export` | Writes the file to a path on the host |

## Env

The `Env` type represents an environment consisting of inputs and desired outputs, for use by an `LLM`. For example, an environment might provide a `Directory`, a `Container`, a custom module, and a string variable as inputs, and request a `Container` as output.

### Common operations

| Field | Description |
|-------|-------------|
| `input` | Retrieves an input value by name |
| `inputs` | Retrieves all input values |
| `output` | Retrieves an output value by name |
| `outputs` | Retrieves all output values |
| `withContainerInput` | Creates or updates an input of type `Container` |
| `withContainerOutput` | Declare a desired output of type `Container` |
| `withDirectoryInput` | Creates or updates an input of type `Directory` |
| `withDirectoryOutput` | Declare a desired output of type `Directory` |
| `withFileInput` | Creates or updates an input of type `File` |
| `withFileOutput` | Declare a desired output of type `File` |
| `with[Object]Input` | Creates or updates an input of type `Object` |
| `with[Object]Output` | Declare a desired output of type `Object` |

## Secret

Dagger allows you to utilize confidential information ("secrets") such as passwords, API keys, SSH keys and so on, without exposing those secrets in plaintext logs, writing them into the filesystem of containers you're building, or inserting them into the cache. The `Secret` type is used to represent these secret values.

### Common operations

| Field | Description |
|-------|-------------|
| `name` | Returns the name of the secret |
| `plaintext` | Returns the plaintext value of the secret |

## Service

The `Service` type represents a content-addressed service providing TCP connectivity.

### Common operations

| Field | Description |
|-------|-------------|
| `endpoint` | Returns a URL or host:port pair to reach the service |
| `hostname` | Returns a hostname to reach the service |
| `ports` | Returns the list of ports provided by the service |
| `up` | Creates a tunnel that forwards traffic from the caller's network to the service |

## CacheVolume

Volume caching involves caching specific parts of the filesystem and reusing them on subsequent function calls if they are unchanged. This is especially useful when dealing with package managers such as `npm`, `maven`, `pip` and similar. Since these dependencies are usually locked to specific versions in the application's manifest, re-downloading them on every session is inefficient and time-consuming.

The `CacheVolume` type represents a directory whose contents persist across Dagger sessions. By using a cache volume for dependencies, Dagger can reuse the cached contents across Dagger workflow runs and reduce execution time.

## GitRepository

The `GitRepository` type represents a Git repository.

### Common operations

| Field | Description |
|-------|-------------|
| `branch` | Returns details of a branch |
| `commit` | Returns details of a commit |
| `head` | Returns details of the current HEAD |
| `ref` | Returns details of a ref |
| `tag` | Returns details of a tag |
| `tags` | Returns tags that match a given pattern |
| `branches` | Returns branches that match a given pattern |

> **Tip:** In addition to the default Dagger types, you can create and add your own custom types to Dagger. These custom types can be used in Dagger modules and can be composed with other types to create complex workflows. Learn more about [creating custom types and developing Dagger modules](/extending).
