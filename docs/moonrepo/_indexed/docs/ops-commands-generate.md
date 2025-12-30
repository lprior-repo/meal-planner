---
id: ops/commands/generate
title: "generate"
category: ops
tags: ["commands", "generate", "operations"]
---

# generate

> **Context**: The `moon generate <name>` (or `moon g`) command will generate code (files and folders) from a pre-defined template of the same name, using an interac

The `moon generate <name>` (or `moon g`) command will generate code (files and folders) from a pre-defined template of the same name, using an interactive series of prompts. Templates are located based on the [`generator.templates`](/docs/config/workspace#templates) setting.

```
## Generate code from a template
$ moon generate npm-package

## Generate code from a template to a target directory
$ moon generate npm-package ./packages/example

## Generate code while declaring custom variable values
$ moon generate npm-package ./packages/example -- --name "@company/example"

## Create a new template
$ moon generate react-app --template
```

> View the official [code generation guide](/docs/guides/codegen) for a more in-depth example of how to utilize this command.

### Arguments

-   `<name>` - Name of the template to generate.
-   `[dest]` - Destination to write files to, relative from the current working directory. If not defined, will be prompted during generation.
-   `[-- <vars>]` - Additional arguments to override default variable values.

### Options

-   `--defaults` - Use the default value of all variables instead of prompting the user.
-   `--dryRun` - Run entire generator process without writing files.
-   `--force` - Force overwrite any existing files at the destination.
-   `--template` - Create a new template with the provided name.

### Configuration

-   [`generator`](/docs/config/workspace#generator) in `.moon/workspace.yml`


## See Also

- [`generator.templates`](/docs/config/workspace#templates)
- [code generation guide](/docs/guides/codegen)
- [`generator`](/docs/config/workspace#generator)
