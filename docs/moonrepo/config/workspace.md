# .moon/workspace.{pkl,yml}

The `.moon/workspace.yml` file configures projects and services in the workspace. This file is *required*.

.moon/workspace.yml

```yaml
$schema: 'https://moonrepo.dev/schemas/workspace.json'
```

> Workspace configuration can also be written in [Pkl](/docs/guides/pkl-config) instead of YAML.

## `extends`

Defines one or many external `.moon/workspace.yml`'s to extend and inherit settings from. Perfect for reusability and sharing configuration across repositories and projects. When defined, this setting must be an HTTPS URL *or* relative file system path that points to a valid YAML document!

.moon/workspace.yml

```yaml
extends: 'https://raw.githubusercontent.com/organization/repository/master/.moon/workspace.yml'
```

> Settings will be merged recursively for blocks, with values defined in the local configuration taking precedence over those defined in the extended configuration. However, the `projects` setting *does not merge*!

## `projects` (Required)

Defines the location of all [projects](/docs/concepts/project) within the workspace. Supports either a manual map of projects (default), a list of globs in which to automatically locate projects, *or* both.

> **Caution**: Projects that depend on each other and form a cycle must be avoided! While we do our best to avoid an infinite loop and disconnect nodes from each other, there's no guarantee that tasks will run in the correct order.

### Using a map

When using a map, each project must be *manually* configured and requires a unique [name](/docs/concepts/project#names) as the map key, where this name is used heavily on the command line and within the project graph for uniquely identifying the project amongst all projects. The map value (known as the project source) is a file system path to the project folder, relative from the workspace root, and must be contained within the workspace boundary.

.moon/workspace.yml

```yaml
projects:
  admin: 'apps/admin'
  apiClients: 'packages/api-clients'
  designSystem: 'packages/design-system'
  web: 'apps/web'
```

### Using globs

If manually mapping projects is too tedious or cumbersome, you may provide a list of [globs](/docs/concepts/file-pattern#globs) to automatically locate all project folders, relative from the workspace root.

When using this approach, the project name is derived from the project folder name, and is cleaned to our [supported characters](/docs/concepts/project#names), but can be customized with the [`id`](/docs/config/project#id) setting in [`moon.yml`](/docs/config/project). Furthermore, globbing **does risk the chance of collision**, and when that happens, we log a warning and skip the conflicting project from being configured in the project graph.

.moon/workspace.yml

```yaml
projects:
  - 'apps/*'
  - 'packages/*'
  # Only shared folders with a moon configuration
  - 'shared/*/moon.yml'
```

### Using a map *and* globs

For those situations where you want to use *both* patterns, you can! The list of globs can be defined under a `globs` field, while the map of projects under a `sources` field.

.moon/workspace.yml

```yaml
projects:
  globs:
    - 'apps/*'
    - 'packages/*'
  sources:
    www: 'www'
```

## `codeowners` (v1.8.0)

Configures code owners (`CODEOWNERS`) integration across the entire workspace.

### `globalPaths`

This setting defines file patterns and their owners at the workspace-level, and are applied to any matching path, at any depth, within the entire workspace. This is useful for defining global or fallback owners when a granular [project-level path](/docs/config/project#paths) does not match or exist.

.moon/workspace.yml

```yaml
codeowners:
  globalPaths:
    '*': ['@admins']
    'config/': ['@infra']
    '/.github/': ['@infra']
```

### `syncOnRun`

Will automatically generate a `CODEOWNERS` file by aggregating and syncing all project [`owners`](/docs/config/project#owners) in the workspace when a [target is run](/docs/concepts/target). The format and location of the `CODEOWNERS` file is based on the [`vcs.provider`](#provider) setting. Defaults to `false`.

.moon/workspace.yml

```yaml
codeowners:
  syncOnRun: true
```

## `constraints`

Configures constraints between projects that are enforced during project graph generation. This is also known as project boundaries.

### `enforceLayerRelationships`

> This was previously known as `enforceProjectTypeRelationships` and was renamed to `enforceLayerRelationships` in v1.39.

Enforces allowed relationships between a project and its dependencies based on the project's [`layer`](/docs/config/project#layer) and [`stack`](/docs/config/project#stack) settings. When a project depends on another project of an invalid layer, a layering violation error will be thrown when attempting to run a task.

### `tagRelationships`

Enforces allowed relationships between a project and its dependencies based on the project's [`tags`](/docs/config/project#tags) setting. This works in a similar fashion to `enforceLayerRelationships`, but gives you far more control over what these relationships look like.

.moon/workspace.yml

```yaml
constraints:
  tagRelationships:
    next: ['react']
```

## `docker` (v1.27.0)

Configures Docker integration for the entire workspace.

### `prune`

Configures aspects of the Docker pruning process when [`moon docker prune`](/docs/commands/docker/prune) is executed.

### `scaffold`

Configures aspects of the Docker scaffolding process when [`moon docker scaffold`](/docs/commands/docker/scaffold) is executed.

## `generator`

Configures aspects of the template generator.

### `templates`

A list of paths in which templates can be located. Supports the following types of paths, and defaults to `./templates`.

-   File system paths, relative from the workspace root.
-   Git repositories and a revision, prefixed with `git://`. (v1.23.0)
-   npm packages and a version, prefixed with `npm://`. (v1.23.0)

.moon/workspace.yml

```yaml
generator:
  templates:
    - './templates'
    - 'file://./other/templates'
    - 'git://github.com/moonrepo/templates#master'
    - 'npm://@moonrepo/templates#1.2.3'
```

## `hasher`

Configures aspects of the smart hashing layer.

### `optimization`

Determines the optimization level to utilize when hashing content before running targets.

-   `accuracy` (default) - When hashing dependency versions, utilize the resolved value in the lockfile. This requires parsing the lockfile, which may reduce performance.
-   `performance` - When hashing dependency versions, utilize the value defined in the manifest. This is typically a version range or requirement.

.moon/workspace.yml

```yaml
hasher:
  optimization: 'performance'
```

### `walkStrategy`

Defines the file system walking strategy to utilize when discovering inputs to hash.

-   `glob` - Walks the file system using glob patterns.
-   `vcs` (default) - Calls out to the [VCS](#vcs) to extract files from its working tree.

.moon/workspace.yml

```yaml
hasher:
  walkStrategy: 'glob'
```

## `notifier`

Configures how moon notifies and interacts with a developer or an external system.

### `webhookUrl`

Defines an HTTPS URL that all pipeline events will be posted to. View the [webhooks guide for more information](/docs/guides/webhooks) on available events.

.moon/workspace.yml

```yaml
notifier:
  webhookUrl: 'https://api.company.com/some/endpoint'
```

## `pipeline`

Configures aspects of task running and the action pipeline.

### `cacheLifetime`

The maximum lifetime of cached artifacts before they're marked as stale and automatically removed by the action pipeline. Defaults to "7 days". This field requires an integer and a timeframe unit that can be [parsed as a duration](https://docs.rs/humantime/2.1.0/humantime/fn.parse_duration.html).

.moon/workspace.yml

```yaml
pipeline:
  cacheLifetime: '24 hours'
```

### `inheritColorsForPipedTasks`

Force colors to be inherited from the current terminal for all tasks that are ran as a child process and their output is piped to the action pipeline. Defaults to `true`.

.moon/workspace.yml

```yaml
pipeline:
  inheritColorsForPipedTasks: true
```

## `unstable_remote` (v1.30.0)

Configures a remote service, primarily for cloud-based caching of artifacts. Learn more about this in the [remote caching](/docs/guides/remote-cache) guide.

### `host`

The host URL to communicate with when uploading and downloading artifacts. Supports both `grpc(s)://` and `http(s)://` protocols. This field is required!

.moon/workspace.yml

```yaml
unstable_remote:
  host: 'grpcs://your-host.com:9092'
```

## `vcs`

Configures the version control system to utilize within the workspace (and repository). A VCS is required for determining touched (added, modified, etc) files, calculating file hashes, computing affected files, and much more.

### `defaultBranch`

Defines the default branch in the repository for comparing differences against. For git, this is typically "master" (default) or "main".

.moon/workspace.yml

```yaml
vcs:
  defaultBranch: 'master'
```

### `hooks` (v1.9.0)

Defines a mapping of hooks to a list of commands to run when that event is triggered. There are no restrictions to what commands can be run, but the binaries for each command must exist on each machine that will be running hooks.

.moon/workspace.yml

```yaml
vcs:
  hooks:
    pre-commit:
      - 'moon run :lint :format --affected --status=staged --no-bail'
      - 'another-command'
```

> If running `moon` commands directly, the `moon` binary must be installed globally!

### `manager`

Defines the VCS tool/binary that is being used for managing the repository. Accepts "git" (default). Expect more version control systems in the future!

.moon/workspace.yml

```yaml
vcs:
  manager: 'git'
```

### `provider` (v1.8.0)

Defines the service provider that the repository is hosted on. Accepts "github" (default), "gitlab", "bitbucket", or "other".

.moon/workspace.yml

```yaml
vcs:
  provider: 'github'
```

### `syncHooks` (v1.9.0)

Will automatically generate [hook scripts](#hooks) to `.moon/hooks` and sync the scripts to the local VCS checkout. The hooks format and location is based on the [`vcs.manager`](#manager) setting. Defaults to `false`.

.moon/workspace.yml

```yaml
vcs:
  hooks:
    # ...
  syncHooks: true
```

> **Caution**: When enabled, this will sync hooks for *all* users of the repository. For personal or small projects, this may be fine, but for larger projects, this may be undesirable and disruptive!

## `versionConstraint`

Defines a version requirement for the currently running moon binary. This provides a mechanism for enforcing that the globally installed moon on every developers machine is using an applicable version.

.moon/workspace.yml

```yaml
versionConstraint: '>=0.20.0'
```
