---
id: ops/config/project
title: "moon.{pkl,yml}"
category: ops
tags: ["operations", "config", "advanced", "moonpklyml"]
---

# moon.{pkl,yml}

> **Context**: The `moon.yml` configuration file *is not required* but can be used to define additional metadata for a project, override inherited tasks, and more at

The `moon.yml` configuration file *is not required* but can be used to define additional metadata for a project, override inherited tasks, and more at the project-level. When used, this file must exist in a project's root, as configured in [`projects`](/docs/config/workspace#projects).

moon.yml

```yaml
$schema: 'https://moonrepo.dev/schemas/project.json'
```

> Project configuration can also be written in [Pkl](/docs/guides/pkl-config) instead of YAML.

## `dependsOn`

Explicitly defines *other* projects that *this* project depends on, primarily when generating the project and task graphs. The most common use case for this is building those projects *before* building this one. When defined, this setting requires an array of project names, which are the keys found in the [`projects`](/docs/config/workspace#projects) map.

moon.yml

```yaml
dependsOn:
  - 'apiClients'
  - 'designSystem'
```

A dependency object can also be defined, where a specific `scope` can be assigned, which accepts "production" (default), "development", "build", or "peer".

moon.yml

```yaml
dependsOn:
  - id: 'apiClients'
    scope: 'production'
  - id: 'designSystem'
    scope: 'peer'
```

> Learn more about [implicit and explicit dependencies](/docs/concepts/project#dependencies).

## Metadata

## `id` (v1.18.0)

Overrides the name (identifier) of the project, which was configured in or derived from the [`projects`](/docs/config/workspace#projects) setting in [`.moon/workspace.yml`](/docs/config/workspace). This setting is useful when using glob based project location, and want to avoid using the folder name as the project name.

moon.yml

```yaml
id: 'custom-id'
```

> All references to the project must use the new identifier, including project and task dependencies.

## `language`

The primary programming language the project is written in. This setting is required for [task inheritance](/docs/config/tasks), editor extensions, and more. Supports the following values:

-   `bash` - A Bash based project (Unix only).
-   `batch` - A Batch/PowerShell based project (Windows only).
-   `go` - A Go based project.
-   `javascript` - A JavaScript based project.
-   `php` - A PHP based project.
-   `python` - A Python based project.
-   `ruby` - A Ruby based project.
-   `rust` - A Rust based project.
-   `typescript` - A TypeScript based project.
-   `unknown` (default) - When not configured or inferred.
-   `*` - A custom language. Values will be converted to kebab-case.

moon.yml

```yaml
language: 'javascript'

## Custom
language: 'kotlin'
```

> For convenience, when this setting is not defined, moon will attempt to detect the language based on configuration files found in the project root. This only applies to non-custom languages!

## `layer`

> This was previously known as `type` and was renamed to `layer` in v1.39.

The layer within a [stack](#stack). Supports the following values:

-   `application` - An application of any kind.
-   `automation` - An automated testing suite, like E2E, integration, or visual tests. (v1.16.0)
-   `configuration` - Configuration files or infrastructure. (v1.22.0)
-   `library` - A self-contained, shareable, and publishable set of code.
-   `scaffolding` - Templates or generators for scaffolding. (v1.22.0)
-   `tool` - An internal tool, CLI, one-off script, etc.
-   `unknown` (default) - When not configured.

moon.yml

```yaml
layer: 'application'
```

> The project layer is used in [task inheritance](/docs/concepts/task-inheritance), [constraints and boundaries](/docs/config/workspace#constraints), editor extensions, and more!

## `project`

The `project` setting defines metadata about the project itself.

moon.yml

```yaml
project:
  name: 'moon'
  description: 'A monorepo management tool.'
  channel: '#moon'
  owner: 'infra.platform'
  maintainers: ['miles.johnson']
```

The information listed within `project` is purely informational and primarily displayed within the CLI. However, this setting exists for you, your team, and your company, as a means to identify and organize all projects. Feel free to build your own tooling around these settings!

### `channel`

The Slack, Discord, Teams, IRC, etc channel name (with leading #) in which to discuss the project.

### `description` (Required)

A description of what the project does and aims to achieve. Be as descriptive as possible, as this is the kind of information search engines would index on.

### `maintainers`

A list of people/developers that maintain the project, review code changes, and can provide support. Can be a name, email, LDAP name, GitHub username, etc, the choice is yours.

### `metadata` (v1.27.0)

A map of custom metadata to associate to this project. Supports all value types that are valid JSON.

moon.yml

```yaml
project:
  # ...
  metadata:
    deprecated: true
```

### `name`

A human readable name of the project. This is *different* from the unique project name configured in [`projects`](/docs/config/workspace#projects).

### `owner`

The team or organization that owns the project. Can be a title, LDAP name, GitHub team, etc. We suggest *not* listing people/developers as the owner, use [maintainers](#maintainers) instead.

## `stack` (v1.22.0)

The technology stack this project belongs to, primarily for categorization. Supports the following values:

-   `frontend` - Client-side user interfaces, etc.
-   `backend` - Server-side APIs, database layers, etc.
-   `infrastructure` - Cloud/server infrastructure, Docker, etc.
-   `systems` - Low-level systems programming.
-   `unknown` (default) - When not configured.

moon.yml

```yaml
stack: 'frontend'
```

> The project stack is also used in [constraints and boundaries](/docs/config/workspace#constraints)!

## `tags`

Tags are a simple mechanism for categorizing projects. They can be used to group projects together for [easier querying](/docs/commands/query/projects), enforcing of [project boundaries and constraints](/docs/config/workspace#constraints), [task inheritance](/docs/concepts/task-inheritance), and more.

moon.yml

```yaml
tags:
  - 'react'
  - 'prisma'
```

## Tasks

## `env`

The `env` field is map of strings that are passed as environment variables to *all tasks* within the current project. Project-level variables will not override task-level variables of the same name.

moon.yml

```yaml
env:
  NODE_ENV: 'production'
```

> View the task [`env`](#env-1) setting for more usage examples and information.

## `fileGroups`

Defines [file groups](/docs/concepts/file-group) to be used by local tasks. By default, this setting *is not required* for the following reasons:

-   File groups are an optional feature, and are designed for advanced use cases.
-   File groups defined in [`.moon/tasks.yml`](/docs/config/tasks) will be inherited by all projects.

When defined this setting requires a map, where the key is the file group name, and the value is a list of [globs or file paths](/docs/concepts/file-pattern), or environment variables. Globs and paths are [relative to a project](/docs/concepts/file-pattern#project-relative) (even when defined [globally](/docs/config/tasks)).

moon.yml

```yaml
## Example groups
fileGroups:
  configs:
    - '*.config.{js,cjs,mjs}'
    - '*.json'
  sources:
    - 'src/**/*'
    - 'types/**/*'
  tests:
    - 'tests/**/*'
    - '**/__tests__/**/*'
  assets:
    - 'assets/**/*'
    - 'images/**/*'
    - 'static/**/*'
    - '**/*.{scss,css}'
```

Once your groups have been defined, you can reference them within [`args`](#args), [`inputs`](#inputs), [`outputs`](#outputs), and more, using [token functions and variables](/docs/concepts/token).

moon.yml

```yaml
tasks:
  build:
    command: 'vite build'
    inputs:
      - '@group(configs)'
      - '@group(sources)'
```

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

## Overrides

Dictates how a project interacts with settings defined at the top-level.

## `toolchain`

### `default` (v1.31.0)

The default [`toolchain`](#toolchain-1) for all task's within the current project. When a task's `toolchain` has *not been* explicitly configured, the toolchain will fallback to this configured value, otherwise the toolchain will be detected from the project's environment.

moon.yml

```yaml
toolchain:
  default: 'node'
```

### `bun`

Configures Bun for this project and overrides the top-level [`bun`](/docs/config/toolchain#bun) setting.

#### `version`

Defines the explicit Bun [version specification](/docs/concepts/toolchain#version-specification) to use when *running tasks* for this project.

moon.yml

```yaml
toolchain:
  bun:
    version: '1.0.0'
```

### `deno`

Configures Deno for this project and overrides the top-level [`deno`](/docs/config/toolchain#deno) setting.

#### `version`

Defines the explicit Deno [version specification](/docs/concepts/toolchain#version-specification) to use when *running tasks* for this project.

moon.yml

```yaml
toolchain:
  deno:
    version: '1.40.0'
```

### `node`

Configures Node.js for this project and overrides the top-level [`node`](/docs/config/toolchain#node) setting. Currently, only the Node.js version can be overridden per-project, not the package manager.

#### `version`

Defines the explicit Node.js [version specification](/docs/concepts/toolchain#version-specification) to use when *running tasks* for this project.

moon.yml

```yaml
toolchain:
  node:
    version: '12.12.0'
```

### `python`

Configures Python for this project and overrides the top-level [`python`](/docs/config/toolchain#python) setting.

#### `version`

Defines the explicit Python [version/channel specification](/docs/concepts/toolchain#version-specification) to use when *running tasks* for this project.

moon.yml

```yaml
toolchain:
  python:
    version: '3.12.0'
```

### `rust`

Configures Rust for this project and overrides the top-level [`rust`](/docs/config/toolchain#rust) setting.

#### `version`

Defines the explicit Rust [version/channel specification](/docs/concepts/toolchain#version-specification) to use when *running tasks* for this project.

moon.yml

```yaml
toolchain:
  rust:
    version: '1.68.0'
```

### `typescript`

#### `disabled`

Disables [TypeScript support](/docs/config/toolchain#typescript) entirely for this project. Defaults to `false`.

moon.yml

```yaml
toolchain:
  typescript:
    disabled: true
```

## `workspace`

### `inheritedTasks`

Provides a layer of control when inheriting tasks from [`.moon/tasks.yml`](/docs/config/tasks).

#### `exclude`

The optional `exclude` setting permits a project to exclude specific tasks from being inherited. It accepts a list of strings, where each string is the name of a global task to exclude.

moon.yml

```yaml
workspace:
  inheritedTasks:
    # Exclude the inherited `test` task for this project
    exclude: ['test']
```

> Exclusion is applied after inclusion and before renaming.

#### `include`

The optional `include` setting permits a project to *only* include specific inherited tasks (works like an allow/white list). It accepts a list of strings, where each string is the name of a global task to include.

When this field is not defined, the project will inherit all tasks from the global project config.

moon.yml

```yaml
workspace:
  inheritedTasks:
    # Include *no* tasks (works like a full exclude)
    include: []
    # Only include the `lint` and `test` tasks for this project
    include:
      - 'lint'
      - 'test'
```

> Inclusion is applied before exclusion and renaming.

#### `rename`

The optional `rename` setting permits a project to rename the inherited task within the current project. It accepts a map of strings, where the key is the original name (found in the global project config), and the value is the new name to use.

For example, say we have 2 tasks in the global project config called `buildPackage` and `buildApplication`, but we only need 1, and since we're an application, we should omit and rename.

moon.yml

```yaml
workspace:
  inheritedTasks:
    exclude: ['buildPackage']
    rename:
      buildApplication: 'build'
```

> Renaming occurs after inclusion and exclusion.


## See Also

- [`projects`](/docs/config/workspace#projects)
- [Pkl](/docs/guides/pkl-config)
- [`projects`](/docs/config/workspace#projects)
- [implicit and explicit dependencies](/docs/concepts/project#dependencies)
- [`projects`](/docs/config/workspace#projects)
