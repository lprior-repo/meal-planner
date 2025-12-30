# .moon/tasks\[/\*\*/\*\].{pkl,yml}

The `.moon/tasks.yml` file configures file groups and tasks that are inherited by *every* project in the workspace, while `.moon/tasks/**/*.yml` configures for projects based on their language or type. [Learn more about task inheritance!](/docs/concepts/task-inheritance)

Projects can override or merge with these settings within their respective [`moon.yml`](/docs/config/project).

.moon/tasks.yml

```yaml
$schema: 'https://moonrepo.dev/schemas/tasks.json'
```

> Inherited tasks configuration can also be written in [Pkl](/docs/guides/pkl-config) instead of YAML.

## `extends`

Defines one or many external `.moon/tasks.yml`'s to extend and inherit settings from. Perfect for reusability and sharing configuration across repositories and projects. When defined, this setting must be an HTTPS URL *or* relative file system path that points to a valid YAML document!

.moon/tasks.yml

```yaml
extends: 'https://raw.githubusercontent.com/organization/repository/master/.moon/tasks.yml'
```

> **Caution**: For map-based settings, `fileGroups` and `tasks`, entries from both the extended configuration and local configuration are merged into a new map, with the values of the local taking precedence. Map values *are not* deep merged!

## `fileGroups`

> For more information on file group configuration, refer to the [`fileGroups`](/docs/config/project#filegroups) section in the [`moon.yml`](/docs/config/project) doc.

Defines [file groups](/docs/concepts/file-group) that will be inherited by projects, and also enables enforcement of organizational patterns and file locations. For example, encourage projects to place source files in a `src` folder, and all test files in `tests`.

.moon/tasks.yml

```yaml
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

> File paths and globs used within a file group are relative from the inherited project's root, and not the workspace root.

## `implicitDeps`

Defines task [`deps`](/docs/config/project#deps) that are implicitly inserted into *all* inherited tasks within a project. This is extremely useful for pre-building projects that are used extensively throughout the repo, or always building project dependencies. Defaults to an empty list.

.moon/tasks.yml

```yaml
implicitDeps:
  - '^:build'
```

> Implicit dependencies are *always* inherited, regardless of the [`mergeDeps`](/docs/config/project#mergedeps) option.

## `implicitInputs`

Defines task [`inputs`](/docs/config/project#inputs) that are implicitly inserted into *all* inherited tasks within a project. This is extremely useful for the "changes to these files should always trigger a task" scenario.

Like `inputs`, file paths/globs defined here are relative from the inheriting project. [Project and workspace relative file patterns](/docs/concepts/file-pattern#project-relative) are supported and encouraged.

.moon/tasks/node.yml

```yaml
implicitInputs:
  - 'package.json'
```

> Implicit inputs are *always* inherited, regardless of the [`mergeInputs`](/docs/config/project#mergeinputs) option.

## `tasks`

> For more information on task configuration, refer to the [`tasks`](/docs/config/project#tasks) section in the [`moon.yml`](/docs/config/project) doc.

As mentioned in the link above, [tasks](/docs/concepts/task) are actions that are ran within the context of a project, and commonly wrap a command. For most workspaces, every project *should* have linting, typechecking, testing, code formatting, so on and so forth. To reduce the amount of boilerplate that *every* project would require, this setting offers the ability to define tasks that are inherited by many projects within the workspace, but can also be overridden per project.

.moon/tasks.yml

```yaml
tasks:
  format:
    command: 'prettier --check .'
  lint:
    command: 'eslint --no-error-on-unmatched-pattern .'
  test:
    command: 'jest --passWithNoTests'
  typecheck:
    command: 'tsc --build'
```

> Relative file paths and globs used within a task are relative from the inherited project's root, and not the workspace root.

## `taskOptions` (v1.20.0)

> For more information on task options, refer to the [`options`](/docs/config/project#options) section in the [`moon.yml`](/docs/config/project) doc.

Like [tasks](#tasks), this setting allows you to define task options that will be inherited by *all tasks* within the configured file, and by all project-level inherited tasks. This setting is the 1st link in the inheritance chain, and can be overridden within each task.

.moon/tasks.yml

```yaml
taskOptions:
  # Never cache builds
  cache: false
  # Always re-run flaky tests
  retryCount: 2

tasks:
  build:
    # ...
    options:
      # Override the default cache setting
      cache: true
```
