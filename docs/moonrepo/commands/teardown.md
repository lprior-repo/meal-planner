# teardown

The `moon teardown` command, as its name infers, will teardown and clean the current environment, opposite the [`setup`](/docs/commands/setup) command. It achieves this by doing the following:

- Uninstalling all configured tools in the toolchain.
- Removing any download or temporary files/folders.

```
$ moon teardown
```

### Configuration

- [`*`](/docs/config/toolchain) in `.moon/toolchain.yml`
