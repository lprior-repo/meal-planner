# sync codeowners

v1.8.0

The `moon sync codeowners` command will manually sync code owners, by aggregating all owners from projects, and generating a single `CODEOWNERS` file. Refer to the official [code owners](/docs/guides/codeowners) guide for more information.

```
$ moon sync codeowners
```

### Options

- `--clean` - Clean and remove previously generated file.
- `--force` - Bypass cache and force create file.

### Configuration

- [`codeowners`](/docs/config/workspace#codeowners) in `.moon/workspace.yml`
- [`owners`](/docs/config/project#owners) in `moon.yml`
