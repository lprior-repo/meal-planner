# docker file

v1.27.0

The `moon docker file <project>` command can be used to generate a multi-staged `Dockerfile` for a project, that takes full advantage of Docker's layer caching, and is primarily for production deploys (this should not be used for development).

```
$ moon docker file <project>
```

As mentioned above, the generated `Dockerfile` uses a multi-stage approach, where each stage is broken up into the following:

-   `base` - The base stage, which simply installs moon for a chosen Docker image. This stage requires Bash.
-   `skeleton` - Scaffolds workspace and sources repository skeletons using [`moon docker scaffold`](/docs/commands/docker/scaffold).
-   `build` - Copies required sources, installs the toolchain using [`moon docker setup`](/docs/commands/docker/setup), optionally builds the project, and optionally prunes the image using [`moon docker prune`](/docs/commands/docker/prune).
-   `start` - Runs the project after it has been built. This is typically starting an HTTP server, or executing a binary.

> View the official [Docker usage guide](/docs/guides/docker) for a more in-depth example of how to utilize this command.

### Arguments

-   `<name>` - Name or alias of a project, as defined in [`projects`](/docs/config/workspace#projects).
-   `[dest]` - Destination to write the file, relative from the project root. Defaults to `Dockerfile`.

### Options

-   `--defaults` - Use default options instead of prompting in the terminal.
-   `--buildTask` - Name of a task to build the project. Defaults to the [`docker.file.buildTask`](/docs/config/project#buildtask) setting, or prompts in the terminal.
-   `--image` - Base Docker image to use. Defaults to an image derived from the toolchain, or prompts in the terminal.
-   `--no-prune` - Do not prune the workspace in the build stage.
-   `--no-toolchain` - Do not use the toolchain and instead use system binaries.
-   `--startTask` - Name of a task to start the project. Defaults to the [`docker.file.startTask`](/docs/config/project#starttask) setting, or prompts in the terminal.

### Configuration

-   [`docker.file`](/docs/config/project#file) in `moon.yml`
