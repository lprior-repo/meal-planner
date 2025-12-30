# Class: Container

An OCI-compatible container, also known as a Docker container.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Container**(`ctx?`, `_id?`, `_combinedOutput?`, `_envVariable?`, `_exists?`, `_exitCode?`, `_export?`, `_exportImage?`, `_imageRef?`, `_label?`, `_platform?`, `_publish?`, `_stderr?`, `_stdout?`, `_sync?`, `_up?`, `_user?`, `_workdir?`): `Container`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`ContainerID`](/reference/typescript/api/client.gen/type-aliases/ContainerID)

##### \_combinedOutput?

`string`

##### \_envVariable?

`string`

##### \_exists?

`boolean`

##### \_exitCode?

`number`

##### \_export?

`string`

##### \_exportImage?

[`Void`](/reference/typescript/api/client.gen/type-aliases/Void)

##### \_imageRef?

`string`

##### \_label?

`string`

##### \_platform?

[`Platform`](/reference/typescript/api/client.gen/type-aliases/Platform)

##### \_publish?

`string`

##### \_stderr?

`string`

##### \_stdout?

`string`

##### \_sync?

[`ContainerID`](/reference/typescript/api/client.gen/type-aliases/ContainerID)

##### \_up?

[`Void`](/reference/typescript/api/client.gen/type-aliases/Void)

##### \_user?

`string`

##### \_workdir?

`string`

#### Returns

`Container`

#### Overrides

`BaseClient.constructor`

## Methods

### asService()

> **asService**(`opts?`): [`Service`](/reference/typescript/api/client.gen/classes/Service)

Turn the container into a Service.

Be sure to set any exposed ports before this conversion.

#### Parameters

##### opts?

[`ContainerAsServiceOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerAsServiceOpts)

#### Returns

[`Service`](/reference/typescript/api/client.gen/classes/Service)

---

### asTarball()

> **asTarball**(`opts?`): [`File`](/reference/typescript/api/client.gen/classes/File)

Package the container state as an OCI image, and return it as a tar archive

#### Parameters

##### opts?

[`ContainerAsTarballOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerAsTarballOpts)

#### Returns

[`File`](/reference/typescript/api/client.gen/classes/File)

---

### combinedOutput()

> **combinedOutput**(): `Promise`<`string`\>

The combined buffered standard output and standard error stream of the last executed command

Returns an error if no command was executed

#### Returns

`Promise`<`string`\>

---

### defaultArgs()

> **defaultArgs**(): `Promise`<`string`\[\]>

Return the container's default arguments.

#### Returns

`Promise`<`string`\[\]>

---

### directory()

> **directory**(`path`, `opts?`): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

Retrieve a directory from the container's root filesystem

Mounts are included.

#### Parameters

##### path

`string`

The path of the directory to retrieve (e.g., "./src").

##### opts?

[`ContainerDirectoryOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerDirectoryOpts)

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### entrypoint()

> **entrypoint**(): `Promise`<`string`\[\]>

Return the container's OCI entrypoint.

#### Returns

`Promise`<`string`\[\]>

---

### envVariable()

> **envVariable**(`name`): `Promise`<`string`\>

Retrieves the value of the specified environment variable.

#### Parameters

##### name

`string`

The name of the environment variable to retrieve (e.g., "PATH").

#### Returns

`Promise`<`string`\>

---

### envVariables()

> **envVariables**(): `Promise`<[`EnvVariable`](/reference/typescript/api/client.gen/classes/EnvVariable)\[\]>

Retrieves the list of environment variables passed to commands.

#### Returns

`Promise`<[`EnvVariable`](/reference/typescript/api/client.gen/classes/EnvVariable)\[\]>

---

### exists()

> **exists**(`path`, `opts?`): `Promise`<`boolean`\>

check if a file or directory exists

#### Parameters

##### path

`string`

Path to check (e.g., "/file.txt").

##### opts?

[`ContainerExistsOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerExistsOpts)

#### Returns

`Promise`<`boolean`\>

---

### exitCode()

> **exitCode**(): `Promise`<`number`\>

The exit code of the last executed command

Returns an error if no command was executed

#### Returns

`Promise`<`number`\>

---

### experimentalWithAllGPUs()

> **experimentalWithAllGPUs**(): `Container`

EXPERIMENTAL API! Subject to change/removal at any time.

Configures all available GPUs on the host to be accessible to this container.

This currently works for Nvidia devices only.

#### Returns

`Container`

---

### experimentalWithGPU()

> **experimentalWithGPU**(`devices`): `Container`

EXPERIMENTAL API! Subject to change/removal at any time.

Configures the provided list of devices to be accessible to this container.

This currently works for Nvidia devices only.

#### Parameters

##### devices

`string`\[\]

List of devices to be accessible to this container.

#### Returns

`Container`

---

### export()

> **export**(`path`, `opts?`): `Promise`<`string`\>

Writes the container as an OCI tarball to the destination file path on the host.

It can also export platform variants.

#### Parameters

##### path

`string`

Host's destination path (e.g., "./tarball").

Path can be relative to the engine's workdir or absolute.

##### opts?

[`ContainerExportOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerExportOpts)

#### Returns

`Promise`<`string`\>

---

### exportImage()

> **exportImage**(`name`, `opts?`): `Promise`<`void`\>

Exports the container as an image to the host's container image store.

#### Parameters

##### name

`string`

Name of image to export to in the host's store

##### opts?

[`ContainerExportImageOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerExportImageOpts)

#### Returns

`Promise`<`void`\>

---

### exposedPorts()

> **exposedPorts**(): `Promise`<[`Port`](/reference/typescript/api/client.gen/classes/Port)\[\]>

Retrieves the list of exposed ports.

This includes ports already exposed by the image, even if not explicitly added with dagger.

#### Returns

`Promise`<[`Port`](/reference/typescript/api/client.gen/classes/Port)\[\]>

---

### file()

> **file**(`path`, `opts?`): [`File`](/reference/typescript/api/client.gen/classes/File)

Retrieves a file at the given path.

Mounts are included.

#### Parameters

##### path

`string`

The path of the file to retrieve (e.g., "./README.md").

##### opts?

[`ContainerFileOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerFileOpts)

#### Returns

[`File`](/reference/typescript/api/client.gen/classes/File)

---

### from()

> **from**(`address`): `Container`

Download a container image, and apply it to the container state. All previous state will be lost.

#### Parameters

##### address

`string`

Address of the container image to download, in standard OCI ref format. Example:"registry.dagger.io/engine:latest"

#### Returns

`Container`

---

### id()

> **id**(): `Promise`<[`ContainerID`](/reference/typescript/api/client.gen/type-aliases/ContainerID)\>

A unique identifier for this Container.

#### Returns

`Promise`<[`ContainerID`](/reference/typescript/api/client.gen/type-aliases/ContainerID)\>

---

### imageRef()

> **imageRef**(): `Promise`<`string`\>

The unique image reference which can only be retrieved immediately after the 'Container.From' call.

#### Returns

`Promise`<`string`\>

---

### import\_()

> **import\_**(`source`, `opts?`): `Container`

Reads the container from an OCI tarball.

#### Parameters

##### source

[`File`](/reference/typescript/api/client.gen/classes/File)

File to read the container from.

##### opts?

[`ContainerImportOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerImportOpts)

#### Returns

`Container`

---

### label()

> **label**(`name`): `Promise`<`string`\>

Retrieves the value of the specified label.

#### Parameters

##### name

`string`

The name of the label (e.g., "org.opencontainers.artifact.created").

#### Returns

`Promise`<`string`\>

---

### labels()

> **labels**(): `Promise`<[`Label`](/reference/typescript/api/client.gen/classes/Label)\[\]>

Retrieves the list of labels passed to container.

#### Returns

`Promise`<[`Label`](/reference/typescript/api/client.gen/classes/Label)\[\]>

---

### mounts()

> **mounts**(): `Promise`<`string`\[\]>

Retrieves the list of paths where a directory is mounted.

#### Returns

`Promise`<`string`\[\]>

---

### platform()

> **platform**(): `Promise`<[`Platform`](/reference/typescript/api/client.gen/type-aliases/Platform)\>

The platform this container executes and publishes as.

#### Returns

`Promise`<[`Platform`](/reference/typescript/api/client.gen/type-aliases/Platform)\>

---

### publish()

> **publish**(`address`, `opts?`): `Promise`<`string`\>

Package the container state as an OCI image, and publish it to a registry

Returns the fully qualified address of the published image, with digest

#### Parameters

##### address

`string`

The OCI address to publish to

Same format as "docker push". Example: "registry.example.com/user/repo:tag"

##### opts?

[`ContainerPublishOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerPublishOpts)

#### Returns

`Promise`<`string`\>

---

### rootfs()

> **rootfs**(): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

Return a snapshot of the container's root filesystem. The snapshot can be modified then written back using withRootfs. Use that method for filesystem modifications.

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### stderr()

> **stderr**(): `Promise`<`string`\>

The buffered standard error stream of the last executed command

Returns an error if no command was executed

#### Returns

`Promise`<`string`\>

---

### stdout()

> **stdout**(): `Promise`<`string`\>

The buffered standard output stream of the last executed command

Returns an error if no command was executed

#### Returns

`Promise`<`string`\>

---

### sync()

> **sync**(): `Promise`<`Container`\>

Forces evaluation of the pipeline in the engine.

It doesn't run the default command if no exec has been set.

#### Returns

`Promise`<`Container`\>

---

### terminal()

> **terminal**(`opts?`): `Container`

Opens an interactive terminal for this container using its configured default terminal command if not overridden by args (or sh as a fallback default).

#### Parameters

##### opts?

[`ContainerTerminalOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerTerminalOpts)

#### Returns

`Container`

---

### up()

> **up**(`opts?`): `Promise`<`void`\>

Starts a Service and creates a tunnel that forwards traffic from the caller's network to that service.

Be sure to set any exposed ports before calling this api.

#### Parameters

##### opts?

[`ContainerUpOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerUpOpts)

#### Returns

`Promise`<`void`\>

---

### user()

> **user**(): `Promise`<`string`\>

Retrieves the user to be set for all commands.

#### Returns

`Promise`<`string`\>

---

### with()

> **with**(`arg`): `Container`

Call the provided function with current Container.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

##### arg

(`param`) => `Container`

#### Returns

`Container`

---

### withAnnotation()

> **withAnnotation**(`name`, `value`): `Container`

Retrieves this container plus the given OCI anotation.

#### Parameters

##### name

`string`

The name of the annotation.

##### value

`string`

The value of the annotation.

#### Returns

`Container`

---

### withDefaultArgs()

> **withDefaultArgs**(`args`): `Container`

Configures default arguments for future commands. Like CMD in Dockerfile.

#### Parameters

##### args

`string`\[\]

Arguments to prepend to future executions (e.g., \["-v", "--no-cache"\]).

#### Returns

`Container`

---

### withDefaultTerminalCmd()

> **withDefaultTerminalCmd**(`args`, `opts?`): `Container`

Set the default command to invoke for the container's terminal API.

#### Parameters

##### args

`string`\[\]

The args of the command.

##### opts?

[`ContainerWithDefaultTerminalCmdOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithDefaultTerminalCmdOpts)

#### Returns

`Container`

---

### withDirectory()

> **withDirectory**(`path`, `source`, `opts?`): `Container`

Return a new container snapshot, with a directory added to its filesystem

#### Parameters

##### path

`string`

Location of the written directory (e.g., "/tmp/directory").

##### source

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

Identifier of the directory to write

##### opts?

[`ContainerWithDirectoryOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithDirectoryOpts)

#### Returns

`Container`

---

### withEntrypoint()

> **withEntrypoint**(`args`, `opts?`): `Container`

Set an OCI-style entrypoint. It will be included in the container's OCI configuration. Note, withExec ignores the entrypoint by default.

#### Parameters

##### args

`string`\[\]

Arguments of the entrypoint. Example: \["go", "run"\].

##### opts?

[`ContainerWithEntrypointOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithEntrypointOpts)

#### Returns

`Container`

---

### withEnvVariable()

> **withEnvVariable**(`name`, `value`, `opts?`): `Container`

Set a new environment variable in the container.

#### Parameters

##### name

`string`

Name of the environment variable (e.g., "HOST").

##### value

`string`

Value of the environment variable. (e.g., "localhost").

##### opts?

[`ContainerWithEnvVariableOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithEnvVariableOpts)

#### Returns

`Container`

---

### withError()

> **withError**(`err`): `Container`

Raise an error.

#### Parameters

##### err

`string`

Message of the error to raise. If empty, the error will be ignored.

#### Returns

`Container`

---

### withExec()

> **withExec**(`args`, `opts?`): `Container`

Execute a command in the container, and return a new snapshot of the container state after execution.

#### Parameters

##### args

`string`\[\]

Command to execute. Must be valid exec() arguments, not a shell command. Example: \["go", "run", "main.go"\].

To run a shell command, execute the shell and pass the shell command as argument. Example: \["sh", "-c", "ls -l | grep foo"\]

Defaults to the container's default arguments (see "defaultArgs" and "withDefaultArgs").

##### opts?

[`ContainerWithExecOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithExecOpts)

#### Returns

`Container`

---

### withExposedPort()

> **withExposedPort**(`port`, `opts?`): `Container`

Expose a network port. Like EXPOSE in Dockerfile (but with healthcheck support)

Exposed ports serve two purposes:

- For health checks and introspection, when running services
    
- For setting the EXPOSE OCI field when publishing the container

#### Parameters

##### port

`number`

Port number to expose. Example: 8080

##### opts?

[`ContainerWithExposedPortOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithExposedPortOpts)

#### Returns

`Container`

---

### withFile()

> **withFile**(`path`, `source`, `opts?`): `Container`

Return a container snapshot with a file added

#### Parameters

##### path

`string`

Path of the new file. Example: "/path/to/new-file.txt"

##### source

[`File`](/reference/typescript/api/client.gen/classes/File)

File to add

##### opts?

[`ContainerWithFileOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithFileOpts)

#### Returns

`Container`

---

### withFiles()

> **withFiles**(`path`, `sources`, `opts?`): `Container`

Retrieves this container plus the contents of the given files copied to the given path.

#### Parameters

##### path

`string`

Location where copied files should be placed (e.g., "/src").

##### sources

[`File`](/reference/typescript/api/client.gen/classes/File)\[\]

Identifiers of the files to copy.

##### opts?

[`ContainerWithFilesOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithFilesOpts)

#### Returns

`Container`

---

### withLabel()

> **withLabel**(`name`, `value`): `Container`

Retrieves this container plus the given label.

#### Parameters

##### name

`string`

The name of the label (e.g., "org.opencontainers.artifact.created").

##### value

`string`

The value of the label (e.g., "2023-01-01T00:00:00Z").

#### Returns

`Container`

---

### withMountedCache()

> **withMountedCache**(`path`, `cache`, `opts?`): `Container`

Retrieves this container plus a cache volume mounted at the given path.

#### Parameters

##### path

`string`

Location of the cache directory (e.g., "/root/.npm").

##### cache

[`CacheVolume`](/reference/typescript/api/client.gen/classes/CacheVolume)

Identifier of the cache volume to mount.

##### opts?

[`ContainerWithMountedCacheOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithMountedCacheOpts)

#### Returns

`Container`

---

### withMountedDirectory()

> **withMountedDirectory**(`path`, `source`, `opts?`): `Container`

Retrieves this container plus a directory mounted at the given path.

#### Parameters

##### path

`string`

Location of the mounted directory (e.g., "/mnt/directory").

##### source

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

Identifier of the mounted directory.

##### opts?

[`ContainerWithMountedDirectoryOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithMountedDirectoryOpts)

#### Returns

`Container`

---

### withMountedFile()

> **withMountedFile**(`path`, `source`, `opts?`): `Container`

Retrieves this container plus a file mounted at the given path.

#### Parameters

##### path

`string`

Location of the mounted file (e.g., "/tmp/file.txt").

##### source

[`File`](/reference/typescript/api/client.gen/classes/File)

Identifier of the mounted file.

##### opts?

[`ContainerWithMountedFileOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithMountedFileOpts)

#### Returns

`Container`

---

### withMountedSecret()

> **withMountedSecret**(`path`, `source`, `opts?`): `Container`

Retrieves this container plus a secret mounted into a file at the given path.

#### Parameters

##### path

`string`

Location of the secret file (e.g., "/tmp/secret.txt").

##### source

[`Secret`](/reference/typescript/api/client.gen/classes/Secret)

Identifier of the secret to mount.

##### opts?

[`ContainerWithMountedSecretOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithMountedSecretOpts)

#### Returns

`Container`

---

### withMountedTemp()

> **withMountedTemp**(`path`, `opts?`): `Container`

Retrieves this container plus a temporary directory mounted at the given path. Any writes will be ephemeral to a single withExec call; they will not be persisted to subsequent withExecs.

#### Parameters

##### path

`string`

Location of the temporary directory (e.g., "/tmp/temp\_dir").

##### opts?

[`ContainerWithMountedTempOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithMountedTempOpts)

#### Returns

`Container`

---

### withNewFile()

> **withNewFile**(`path`, `contents`, `opts?`): `Container`

Return a new container snapshot, with a file added to its filesystem with text content

#### Parameters

##### path

`string`

Path of the new file. May be relative or absolute. Example: "README.md" or "/etc/profile"

##### contents

`string`

Contents of the new file. Example: "Hello world!"

##### opts?

[`ContainerWithNewFileOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithNewFileOpts)

#### Returns

`Container`

---

### withoutAnnotation()

> **withoutAnnotation**(`name`): `Container`

Retrieves this container minus the given OCI annotation.

#### Parameters

##### name

`string`

The name of the annotation.

#### Returns

`Container`

---

### withoutDefaultArgs()

> **withoutDefaultArgs**(): `Container`

Remove the container's default arguments.

#### Returns

`Container`

---

### withoutDirectory()

> **withoutDirectory**(`path`, `opts?`): `Container`

Return a new container snapshot, with a directory removed from its filesystem

#### Parameters

##### path

`string`

Location of the directory to remove (e.g., ".github/").

##### opts?

[`ContainerWithoutDirectoryOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithoutDirectoryOpts)

#### Returns

`Container`

---

### withoutEntrypoint()

> **withoutEntrypoint**(`opts?`): `Container`

Reset the container's OCI entrypoint.

#### Parameters

##### opts?

[`ContainerWithoutEntrypointOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithoutEntrypointOpts)

#### Returns

`Container`

---

### withoutEnvVariable()

> **withoutEnvVariable**(`name`): `Container`

Retrieves this container minus the given environment variable.

#### Parameters

##### name

`string`

The name of the environment variable (e.g., "HOST").

#### Returns

`Container`

---

### withoutExposedPort()

> **withoutExposedPort**(`port`, `opts?`): `Container`

Unexpose a previously exposed port.

#### Parameters

##### port

`number`

Port number to unexpose

##### opts?

[`ContainerWithoutExposedPortOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithoutExposedPortOpts)

#### Returns

`Container`

---

### withoutFile()

> **withoutFile**(`path`, `opts?`): `Container`

Retrieves this container with the file at the given path removed.

#### Parameters

##### path

`string`

Location of the file to remove (e.g., "/file.txt").

##### opts?

[`ContainerWithoutFileOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithoutFileOpts)

#### Returns

`Container`

---

### withoutFiles()

> **withoutFiles**(`paths`, `opts?`): `Container`

Return a new container spanshot with specified files removed

#### Parameters

##### paths

`string`\[\]

Paths of the files to remove. Example: \["foo.txt, "/root/.ssh/config"

##### opts?

[`ContainerWithoutFilesOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithoutFilesOpts)

#### Returns

`Container`

---

### withoutLabel()

> **withoutLabel**(`name`): `Container`

Retrieves this container minus the given environment label.

#### Parameters

##### name

`string`

The name of the label to remove (e.g., "org.opencontainers.artifact.created").

#### Returns

`Container`

---

### withoutMount()

> **withoutMount**(`path`, `opts?`): `Container`

Retrieves this container after unmounting everything at the given path.

#### Parameters

##### path

`string`

Location of the cache directory (e.g., "/root/.npm").

##### opts?

[`ContainerWithoutMountOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithoutMountOpts)

#### Returns

`Container`

---

### withoutRegistryAuth()

> **withoutRegistryAuth**(`address`): `Container`

Retrieves this container without the registry authentication of a given address.

#### Parameters

##### address

`string`

Registry's address to remove the authentication from.

Formatted as \[host\]/\[user\]/\[repo\]:\[tag\] (e.g. docker.io/dagger/dagger:main).

#### Returns

`Container`

---

### withoutSecretVariable()

> **withoutSecretVariable**(`name`): `Container`

Retrieves this container minus the given environment variable containing the secret.

#### Parameters

##### name

`string`

The name of the environment variable (e.g., "HOST").

#### Returns

`Container`

---

### withoutUnixSocket()

> **withoutUnixSocket**(`path`, `opts?`): `Container`

Retrieves this container with a previously added Unix socket removed.

#### Parameters

##### path

`string`

Location of the socket to remove (e.g., "/tmp/socket").

##### opts?

[`ContainerWithoutUnixSocketOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithoutUnixSocketOpts)

#### Returns

`Container`

---

### withoutUser()

> **withoutUser**(): `Container`

Retrieves this container with an unset command user.

Should default to root.

#### Returns

`Container`

---

### withoutWorkdir()

> **withoutWorkdir**(): `Container`

Unset the container's working directory.

Should default to "/".

#### Returns

`Container`

---

### withRegistryAuth()

> **withRegistryAuth**(`address`, `username`, `secret`): `Container`

Attach credentials for future publishing to a registry. Use in combination with publish

#### Parameters

##### address

`string`

The image address that needs authentication. Same format as "docker push". Example: "registry.dagger.io/dagger:latest"

##### username

`string`

The username to authenticate with. Example: "alice"

##### secret

[`Secret`](/reference/typescript/api/client.gen/classes/Secret)

The API key, password or token to authenticate to this registry

#### Returns

`Container`

---

### withRootfs()

> **withRootfs**(`directory`): `Container`

Change the container's root filesystem. The previous root filesystem will be lost.

#### Parameters

##### directory

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

The new root filesystem.

#### Returns

`Container`

---

### withSecretVariable()

> **withSecretVariable**(`name`, `secret`): `Container`

Set a new environment variable, using a secret value

#### Parameters

##### name

`string`

Name of the secret variable (e.g., "API\_SECRET").

##### secret

[`Secret`](/reference/typescript/api/client.gen/classes/Secret)

Identifier of the secret value.

#### Returns

`Container`

---

### withServiceBinding()

> **withServiceBinding**(`alias`, `service`): `Container`

Establish a runtime dependency from a container to a network service.

The service will be started automatically when needed and detached when it is no longer needed, executing the default command if none is set.

The service will be reachable from the container via the provided hostname alias.

The service dependency will also convey to any files or directories produced by the container.

#### Parameters

##### alias

`string`

Hostname that will resolve to the target service (only accessible from within this container)

##### service

[`Service`](/reference/typescript/api/client.gen/classes/Service)

The target service

#### Returns

`Container`

---

### withSymlink()

> **withSymlink**(`target`, `linkName`, `opts?`): `Container`

Return a snapshot with a symlink

#### Parameters

##### target

`string`

Location of the file or directory to link to (e.g., "/existing/file").

##### linkName

`string`

Location where the symbolic link will be created (e.g., "/new-file-link").

##### opts?

[`ContainerWithSymlinkOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithSymlinkOpts)

#### Returns

`Container`

---

### withUnixSocket()

> **withUnixSocket**(`path`, `source`, `opts?`): `Container`

Retrieves this container plus a socket forwarded to the given Unix socket path.

#### Parameters

##### path

`string`

Location of the forwarded Unix socket (e.g., "/tmp/socket").

##### source

[`Socket`](/reference/typescript/api/client.gen/classes/Socket)

Identifier of the socket to forward.

##### opts?

[`ContainerWithUnixSocketOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithUnixSocketOpts)

#### Returns

`Container`

---

### withUser()

> **withUser**(`name`): `Container`

Retrieves this container with a different command user.

#### Parameters

##### name

`string`

The user to set (e.g., "root").

#### Returns

`Container`

---

### withWorkdir()

> **withWorkdir**(`path`, `opts?`): `Container`

Change the container's working directory. Like WORKDIR in Dockerfile.

#### Parameters

##### path

`string`

The path to set as the working directory (e.g., "/app").

##### opts?

[`ContainerWithWorkdirOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithWorkdirOpts)

#### Returns

`Container`

---

### workdir()

> **workdir**(): `Promise`<`string`\>

Retrieves the working directory for all commands.

#### Returns

`Promise`<`string`\>
