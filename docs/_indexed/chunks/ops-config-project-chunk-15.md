---
doc_id: ops/config/project
chunk_id: ops/config/project#chunk-15
heading_path: ["moon.{pkl,yml}", "`tasks`"]
chunk_type: code
tokens: 1355
summary: "`tasks`"
---

## `tasks`

Tasks are actions that are ran within the context of a [project](/docs/concepts/project), and commonly wrap an npm binary or system command. This setting requires a map, where the key is a unique name for the task, and the value is an object of task parameters.

moon.yml

```yaml
tasks:
  format:
    command: 'prettier'
  lint:
    command: 'eslint'
  test:
    command: 'jest'
  typecheck:
    command: 'tsc'
```

### `extends` (v1.12.0)

The `extends` field can be used to extend the settings from a sibling task within the same project, or [inherited from the global scope](/docs/concepts/task-inheritance). This is useful for composing similar tasks with different arguments or options.

When extending another task, the same [merge strategies](/docs/concepts/task-inheritance#merge-strategies) used for inheritance are applied.

moon.yml

```yaml
tasks:
  lint:
    command: 'eslint .'
    inputs:
      - 'src/**/*'
  lint-fix:
    extends: 'lint'
    args: '--fix'
    local: true
```

### `description` (v1.22.0)

A human-readable description of what the task does. This information is displayed within the [`moon project`](/docs/commands/project) and [`moon task`](/docs/commands/task) commands.

moon.yml

```yaml
tasks:
  build:
    description: 'Builds the project using Vite'
    command: 'vite build'
```

### `command`

The `command` field is a *single* command to execute for the task, including the command binary/name (must be first) and any optional [arguments](#args). This field supports task inheritance and merging of arguments.

This setting can be defined using a string, or an array of strings. We suggest using arrays when dealing with many args, or the args string cannot be parsed easily.

moon.yml

```yaml
tasks:
  format:
    # Using a string
    command: 'prettier --check .'
    # Using an array
    command:
      - 'prettier'
      - '--check'
      - '.'
```

> If you need to support pipes, redirects, or multiple commands, use [`script`](#script) instead. Learn more about [commands vs scripts](/docs/concepts/task#commands-vs-scripts).

### `args`

The `args` field is a collection of *additional* arguments to append to the [`command`](#command) when executing the task. This field exists purely to provide arguments for [inherited tasks](/docs/config/tasks#tasks).

This setting can be defined using a string, or an array of strings. We suggest using arrays when dealing with many args, or the args string cannot be parsed easily.

moon.yml

```yaml
tasks:
  test:
    command: 'jest'
    # Using a string
    args: '--color --maxWorkers 3'
    # Using an array
    args:
      - '--color'
      - '--maxWorkers'
      - '3'
```

### `deps`

The `deps` field is a list of other tasks (known as [targets](/docs/concepts/target)), either within this project or found in another project, that will be executed *before* this task. It achieves this by generating a directed task graph based on the project graph.

moon.yml

```yaml
tasks:
  build:
    command: 'webpack'
    deps:
      - 'apiClients:build'
      - 'designSystem:build'
      # A task within the current project
      - 'codegen'
```

### `env`

The `env` field is map of strings that are passed as environment variables when running the command. Variables defined here will take precedence over those loaded with [`envFile`](#envfile).

moon.yml

```yaml
tasks:
  build:
    command: 'webpack'
    env:
      NODE_ENV: 'production'
```

### `inputs`

The `inputs` field is a list of sources that calculate whether to execute this task based on the environment and files that have been touched since the last time the task has been ran. If *not* defined or inherited, then all files within a project are considered an input (`**/*`), excluding root-level tasks.

Inputs support the following source types:

-   Environment variables
-   Environment variable wildcards (v1.22.0)
-   Files, folders, and globs
-   [Token functions and variables](/docs/concepts/token)

moon.yml

```yaml
tasks:
  lint:
    command: 'eslint'
    inputs:
      # Config files anywhere within the project
      - '**/.eslintignore'
      - '**/.eslintrc.js'
      # Config files at the workspace root
      - '/.eslintignore'
      - '/.eslintrc.js'
      # Tokens
      - '$projectRoot'
      - '@group(sources)'
```

### `local`

> This setting is deprecated and will be removed in v2. We suggest using [`preset`](#preset) instead.

Marks the task as local only. This should primarily be enabled for long-running or never-ending tasks, like development servers and watch mode. Defaults to `true` if the task name is "dev", "start", or "serve", and `false` otherwise.

This is a convenience setting for local development that sets the following task options:

-   [`cache`](#cache) -> Turned off
-   [`outputStyle`](#outputstyle) -> Set to "stream"
-   [`persistent`](#persistent) -> Turned on
-   [`runInCI`](#runinci) -> Turned off

moon.yml

```yaml
tasks:
  dev:
    command: 'webpack server'
    local: true
```

### `outputs`

The `outputs` field is a list of [files and folders](/docs/concepts/file-pattern#project-relative) that are *created* as a result of executing this task, typically from a build or compilation related task. Outputs are necessary for [incremental caching and hydration](/docs/concepts/cache). If you'd prefer to avoid that functionality, omit this field.

### `preset` (v1.28.0)

Applies the chosen preset to the task. A preset defines a collection of task options that will be inherited as the default, and can then be overridden within the task itself. The following presets are available:

-   `server`
    -   [`cache`](#cache) -> Turned off
    -   [`outputStyle`](#outputstyle) -> Set to "stream"
    -   [`persistent`](#persistent) -> Turned on
    -   [`runInCI`](#runinci) -> Turned off
-   `watcher`
    -   Inherits `server` options
    -   [`interactive`](#interactive) -> Turned on

Tasks named "dev", "start", or "serve" are marked as `server` automatically.

moon.yml

```yaml
tasks:
  dev:
    command: 'webpack server'
    preset: 'server'
```

### `script` (v1.27.0)

The `script` field is *one or many* commands to execute for the task, with support for pipes, redirects, and more. This field does *not* support task inheritance merging, and can only be defined with a string.

If defined, will supersede [`command`](#command) and [`args`](#args).

moon.yml

```yaml
tasks:
  exec:
    # Single command
    script: 'cp ./in ./out'
    # Multiple commands
    script: 'rm -rf ./out && cp ./in ./out'
    # Pipes
    script: 'ps aux | grep 3000'
    # Redirects
    script: './gen.sh > out.json'
```

> If you need to support merging during task inheritance, use [`command`](#command) instead. Learn more about [commands vs scripts](/docs/concepts/task#commands-vs-scripts).

### `toolchain` (v1.31.0)

The `toolchain` field defines additional [toolchain(s)](/docs/concepts/toolchain) the command runs on, where to locate its executable, and more. By default, moon will set to a value based on the project's [`language`](#language), default [`toolchain.default`](#toolchain-1), or via detection.

moon.yml

```yaml
tasks:
  env:
    command: 'printenv'
    toolchain: 'system'
```

This setting also supports multiple values.

moon.yml

```yaml
tasks:
  build:
    command: 'npm run build'
    toolchain: ['javascript', 'node', 'npm']
```

### `options`

The `options` field is an object of configurable options that can be used to modify the task and its execution. The following fields can be provided, with merge related fields supporting all [merge strategies](/docs/concepts/task-inheritance#merge-strategies).

moon.yml

```yaml
tasks:
  typecheck:
    command: 'tsc --noEmit'
    options:
      mergeArgs: 'replace'
      runFromWorkspaceRoot: true
```
