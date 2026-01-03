---
id: ops/commands/templates
title: "templates"
category: ops
tags: ["operations", "templates", "commands"]
---

# templates

> **Context**: The `moon templates` command will list all templates available for [code generation](/docs/commands/generate). This list will include the template tit

v1.24.0

The `moon templates` command will list all templates available for [code generation](/docs/commands/generate). This list will include the template title, description, default destination, where it's source files are located, and more.

```
$ moon templates
```

## Options

- `--json` - Print templates in JSON format.

### Configuration

- [`generator`](/docs/config/workspace#generator) in `.moon/workspace.yml`


## See Also

- [code generation](/docs/commands/generate)
- [`generator`](/docs/config/workspace#generator)
