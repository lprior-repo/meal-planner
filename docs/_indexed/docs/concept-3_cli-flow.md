---
id: concept/3_cli/flow
title: "Flows"
category: concept
tags: ["windmill", "3_cli", "flows", "concept"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>cli</category>
  <title>Windmill CLI Flow Commands</title>
  <description>Manage flows via CLI</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Flows" level="1"/>
    <section name="Listing flows" level="2"/>
    <section name="Pushing a flow" level="2"/>
    <section name="Creating a new flow" level="2"/>
    <section name="Running a flow" level="2"/>
    <section name="Update flow inline scripts lockfile" level="2"/>
  </sections>
  <features>
    <feature>wmill_cli</feature>
    <feature>flow_management</feature>
    <feature>flow_push</feature>
    <feature>flow_bootstrap</feature>
    <feature>flow_run</feature>
  </features>
  <dependencies>
    <dependency type="tool">wmill_cli</dependency>
  </dependencies>
  <examples count="3">
    <example>List all flows in workspace</example>
    <example>Push local flow YAML to remote</example>
    <example>Create new flow</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>6</estimated_reading_time>
  <tags>windmill,cli,wmill,flow,push,bootstrap,run,locks</tags>
</doc_metadata>
-->

# Flows

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>cli</category> <title>Windmill CLI Flow Commands</title> <description>Manage flows via CLI</descr

## Listing flows

The `wmill flow` list command is used to list all flows in the remote workspace.

```bash
wmill flow
```text

## Pushing a flow

Pushing a flow to a Windmill instance is done using the `wmill flow push` command.

```bash
wmill flow push <file_path> <remote_path>
```text

### Arguments

| Argument      | Description                                                    |
| ------------- | -------------------------------------------------------------- |
| `file_path`   | The path to the flow file to push.                             |
| `remote_path` | The remote path where the flow specification should be pushed. |

### Examples

1. Push the flow located at `path/to/local/flow.yaml` to the remote path `f/flows/test`.

```bash
wmill flow push path/to/local/flow.yaml f/flows/test
```text

## Creating a new flow

The wmill flow bootstrap command is used to create a new flow locally.

```bash
wmill flow bootstrap [--summary <summary>] [--description <description>] <path>
```text

### Arguments

| Argument   | Description                          |
| ---------- | ------------------------------------ |
| `path`     | The path of the flow to be created.  |

### Examples

1. Create a new flow `f/flows/flashy_flow`

```bash
wmill flow bootstrap f/flows/flashy_flow
```text

## Running a flow

Running a flow by its path s done using the `wmill flow run` command.

```bash
wmill flow run <remote_path> [options]
```text

### Arguments

| Argument      | Description                     |
| ------------- | ------------------------------- |
| `remote_path` | The path of the flow to be run. |

### Options

| Option         | Parameters | Description                                                                   |
| -------------- | ---------- | ----------------------------------------------------------------------------- |
| `-d, --data`   | `data`     | Inputs specified as a JSON string or a file using @filename or stdin using @- . Resources and variables must be passed using "$res:..." or "$var:..." For example `wmill flow run u/henri/message_to_slack -d '{"slack":"$res:u/henri/henri_slack_perso","channel":"general","text":"hello dear team"}'` |
| `-s, --silent` |            | Do not ouput anything other then the final output. Useful for scripting.      |

![CLI arguments](../../assets/cli/cli_arguments.png "CLI arguments")

## Update flow inline scripts lockfile

Flows inline script [lockfiles](./meta-6_imports-index.md) can be also updated locally in the same way as [`wmill script generate-metadata --lock-only`](./concept-3_cli-script.md#re-generating-a-script-metadata-file) but for flows' inline scripts:

```bash
wmill flow generate-locks
```text

## Flow specification

You can find the definition of the flow file structure [here](./meta-openflow-index.md).

## Remote path format

```js
<u|g|f>/<username|group|folder>/...
```


## See Also

- [CLI arguments](../../assets/cli/cli_arguments.png "CLI arguments")
- [lockfiles](../6_imports/index.mdx)
- [`wmill script generate-metadata --lock-only`](./script.md#re-generating-a-script-metadata-file)
- [here](../../openflow/index.mdx)
