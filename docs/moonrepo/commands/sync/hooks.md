# sync hooks

v1.9.0

The `moon sync hooks` command will manually sync hooks for the configured [VCS](/docs/config/workspace#vcs), by generating and referencing hook scripts from the [`vcs.hooks`](/docs/config/workspace#hooks) setting. Refer to the official [VCS hooks](/docs/guides/vcs-hooks) guide for more information.

```
$ moon sync hooks
```

### Options

- `--clean` - Clean and remove previously generated hooks.
- `--force` - Bypass cache and force create hooks.

### Configuration

- [`vcs.hooks`](/docs/config/workspace#hooks) in `.moon/workspace.yml`
