---
id: ops/moonrepo/generate
title: "generate"
category: ops
tags: ["generate", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>generate</title>
  <description>The `moon generate &lt;name&gt;` (or `moon g`) command will generate code (files and folders) from a pre-defined template of the same name, using an interactive series of prompts. Templates are located base</description>
  <created_at>2026-01-02T19:55:26.915343</created_at>
  <updated_at>2026-01-02T19:55:26.915343</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>configuration</feature>
    <feature>options</feature>
  </features>
  <dependencies>
    <dependency type="library">react</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/guides/codegen</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>generate,operations,moonrepo</tags>
</doc_metadata>
-->

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
