---
doc_id: ops/moonrepo/workspace
chunk_id: ops/moonrepo/workspace#chunk-12
heading_path: [".moon/workspace.{pkl,yml}", "`vcs`"]
chunk_type: code
tokens: 349
summary: "`vcs`"
---

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
