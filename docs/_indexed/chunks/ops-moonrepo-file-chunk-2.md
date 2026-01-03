---
doc_id: ops/moonrepo/file
chunk_id: ops/moonrepo/file#chunk-2
heading_path: ["docker file", "Arguments"]
chunk_type: prose
tokens: 180
summary: "Arguments"
---

## Arguments

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
