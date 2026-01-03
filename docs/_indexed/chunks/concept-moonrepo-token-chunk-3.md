---
doc_id: concept/moonrepo/token
chunk_id: concept/moonrepo/token#chunk-3
heading_path: ["Tokens", "Variables"]
chunk_type: prose
tokens: 552
summary: "Variables"
---

## Variables

A token variable is a value that starts with `$` and is substituted to a value derived from the current workspace, project, and task. And unlike token functions, token variables can be placed *within* content when necessary, and supports multiple variables within the same content.

### Environment (v1.30.0)

-   `$arch` - The current host architecture, derived from the Rust [`ARCH` constant](https://doc.rust-lang.org/std/env/consts/constant.ARCH.html).
-   `$os` - The current operating system, derived from the Rust [`OS` constant](https://doc.rust-lang.org/std/env/consts/constant.OS.html).
-   `$osFamily` - The current operating system family, either `unix` or `windows`.

### Workspace

-   `$workingDir` - The current working directory.
-   `$workspaceRoot` - Absolute file path to the workspace root.

### Project

Most values are derived from settings in [`moon.yml`](/docs/config/project). When a setting is not defined, or does not have a config, the variable defaults to "unknown" (for enums) or an empty string.

-   `$language` Programming language the project is written in, as defined with [`language`](/docs/config/project#language).
-   `$project` - ID of the project that owns the currently running task, as defined in [`.moon/workspace.yml`](/docs/config/workspace).
-   `$projectAlias` - Alias of the project that owns the currently running task.
-   `$projectChannel` - The discussion channel for the project, as defined with [`project.channel`](/docs/config/project#channel). (v1.28.0)
-   `$projectLayer` - The project layer, as defined with [`layer`](/docs/config/project#layer). (v1.39.0)
-   `$projectName` - The human-readable name of the project, as defined with [`project.name`](/docs/config/project#name). (v1.28.0)
-   `$projectOwner` - The owner of the project, as defined with [`project.owner`](/docs/config/project#name). (v1.28.0)
-   `$projectRoot` - Absolute file path to the project root.
-   `$projectSource` - Relative file path from the workspace root to the project root, as defined in [`.moon/workspace.yml`](/docs/config/workspace).
-   `$projectStack` - The stack of the project, as defined with [`stack`](/docs/config/project#stack). (v1.22.0)
-   `$projectType` - The type of project, as defined with [`type`](/docs/config/project#layer). Deprecated, use `$projectLayer` instead.

### Task

-   `$target` - Fully-qualified target that is currently running.
-   `$task` - ID of the task that is currently running. Does not include the project ID.
-   `$taskToolchain` - The toolchain that task will run against, as defined in [`moon.yml`](/docs/config/project). (v1.31.0)
-   `$taskType` - The [type of task](/docs/concepts/task#types), based on its configured settings.

### Date/Time

-   `$date` - The current date in the format of `YYYY-MM-DD`.
-   `$datetime` - The current date and time in the format of `YYYY-MM-DD_HH:MM:SS`.
-   `$time` - The current time in the format of `HH:MM:SS`.
-   `$timestamp` - The current date and time as a UNIX timestamp in seconds.

### VCS (v1.30.0)

-   `$vcsBranch` - The current branch.
-   `$vcsRepository` - The repository slug, in the format of `owner/repo`.
-   `$vcsRevision` - The current revision (commit, etc).
