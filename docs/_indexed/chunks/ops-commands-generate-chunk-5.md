---
doc_id: ops/commands/generate
chunk_id: ops/commands/generate#chunk-5
heading_path: ["generate", "Create a new template"]
chunk_type: prose
tokens: 166
summary: "Create a new template"
---

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
