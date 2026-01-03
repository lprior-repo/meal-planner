---
doc_id: ops/moonrepo/vcs-hooks
chunk_id: ops/moonrepo/vcs-hooks#chunk-2
heading_path: ["VCS hooks", "Defining hooks"]
chunk_type: prose
tokens: 282
summary: "Defining hooks"
---

## Defining hooks

Hooks can be configured with the [`vcs.hooks`](/docs/config/workspace#hooks) setting in [`.moon/workspace.yml`](/docs/config/workspace). This setting requires a map of hook names (in the format required by your VCS), to a list of arbitrary commands to run within the hook script. Commands are used as-is and are not formatted or interpolated in any way.

To demonstrate this, let's configure a `pre-commit` hook that runs a moon `lint` task for affected projects, and also verifies that the commit message abides by a specified format (using [pre-commit](https://pre-commit.com/) and the [commitlint hook](https://github.com/alessandrojcm/commitlint-pre-commit-hook), for example).

.moon/workspace.yml

```yaml
vcs:
  hooks:
    pre-commit:
      - 'pre-commit run'
      - 'moon run :lint --affected'
    commit-msg:
      - 'pre-commit run --hook-stage commit-msg --commit-msg-filename $ARG1'
```

> **Info:** All commands are executed from the repository root (not moon's workspace root) and must exist on `PATH`. If `moon` is installed locally, you can execute it using a repository relative path, like `./node_modules/@moonrepo/cli/moon`.

### Accessing arguments (v1.40.3)

To ease interoperability between operating systems and terminal shells, we set passed arguments as environment variables.

In your hook commands, you can access these arguments using the `$ARG<n>` format, where `<n>` is the 1-indexed position of the argument. For example, to access the first argument, you would use `$ARG1`, the second argument would be `$ARG2`, and so on. `$ARG0` exists and points to the current script.
