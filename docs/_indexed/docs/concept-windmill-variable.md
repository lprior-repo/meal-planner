---
id: concept/windmill/variable
title: "Variables"
category: concept
tags: ["windmill", "concept", "variables"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Variables</title>
  <description>&lt;!-- &lt;doc_metadata&gt; &lt;type&gt;reference&lt;/type&gt; &lt;category&gt;cli&lt;/category&gt; &lt;title&gt;Windmill CLI Variable Commands&lt;/title&gt; &lt;description&gt;Manage variables via CLI&lt;/description&gt; &lt;created_at&gt;2025-12-28T00:00:00Z&lt;/</description>
  <created_at>2026-01-02T19:55:27.511673</created_at>
  <updated_at>2026-01-02T19:55:27.511673</updated_at>
  <language>en</language>
  <sections count="11">
    <section name="Listing variables" level="2"/>
    <section name="Adding a variable" level="2"/>
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
    <section name="Example" level="3"/>
    <section name="Pushing a variable" level="2"/>
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
    <section name="Variable specification" level="2"/>
    <section name="Structure" level="3"/>
  </sections>
  <features>
    <feature>adding_a_variable</feature>
    <feature>arguments</feature>
    <feature>example</feature>
    <feature>listing_variables</feature>
    <feature>options</feature>
    <feature>pushing_a_variable</feature>
    <feature>structure</feature>
    <feature>variable_specification</feature>
    <feature>wmill_variable</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
  </dependencies>
  <examples count="6">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,concept,variables</tags>
</doc_metadata>
-->

<!--
<doc_metadata>
  <type>reference</type>
  <category>cli</category>
  <title>Windmill CLI Variable Commands</title>
  <description>Manage variables via CLI</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Variables" level="1"/>
    <section name="Listing variables" level="2"/>
    <section name="Adding a variable" level="2"/>
    <section name="Pushing a variable" level="2"/>
  </sections>
  <features>
    <feature>wmill_cli</feature>
    <feature>variable_management</feature>
    <feature>variable_add</feature>
    <feature>variable_push</feature>
    <feature>secrets</feature>
  </features>
  <dependencies>
    <dependency type="tool">wmill_cli</dependency>
  </dependencies>
  <examples count="2">
    <example>Add new variable with secret flag</example>
    <example>Push variable specification from JSON/YAML</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>5</estimated_reading_time>
  <tags>windmill,cli,wmill,variable,add,push,list,secret,JSON,YAML</tags>
</doc_metadata>
-->

# Variables

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>cli</category> <title>Windmill CLI Variable Commands</title> <description>Manage variables via CL

## Listing variables

The `wmill variable` list command is used to list all variables in the remote workspace.

```bash
wmill variable
```text

## Adding a variable

The `wmill variable add` command allows you to add a new variable to the remote workspace.

```bash
wmill add <remote_path:string> --value=<value:string> [--secret] [--description=<description:string>] [--account=<account:number>] [--oauth]
```text

### Arguments

| Argument      | Description                                       |
| ------------- | ------------------------------------------------- |
| `remote_path` | The path of the variable in the remote workspace. |

### Options

| Option            | parameter       | Description                                                              |
| ----------------- | --------------- | ------------------------------------------------------------------------ |
| `--value`         | `<value>`       | The value of the variable.                                               |
| `--plain-secrets` | None            | (Optional) Specifies whether the variable is plain and not a secret      |
| `--description`   | `<description>` | (Optional) A description of the variable.                                |
| `--account`       | `<account>`     | (Optional) The account associated with the variable.                     |
| `--oauth`         | None            | (Optional) Specifies whether the variable requires OAuth authentication. |

### Example

This command adds a new variable with the path "my_variable" to the remote workspace. The value is set to "12345", marked as a secret, and associated with account number 1. A description is also provided for the variable.

```bash
wmill add my_variable --value=12345 --secret --description="My secret variable" --account=1
```text

## Pushing a variable

The cli push command allows you to push a local variable spec to the remote workspace, overriding any existing remote versions.

```bash
wmill push <file_path:string> <remote_path:string> [--plain-secrets]
```text

### Arguments

| Argument      | Description                                       |
| ------------- | ------------------------------------------------- |
| `file_path`   | The path to the variable file to push.            |
| `remote_path` | The path of the variable in the remote workspace. |

### Options

| Option            | Description                                                                                                                     |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `--plain-secrets` | (Optional) Specifies whether to push secrets as plain text. If provided, secrets will not be encrypted in the remote workspace. |

## Variable specification

### Structure

Here is an example of a variable specification:

```ts
{
  value: string,
  is_secret: boolean,
  description: string,
  extra_perms: object,
  account: number,
  is_oauth: boolean,
  is_expired: boolean
}
```text

### Example

```JSON
{
"value": "finland does not actually exist",
"is_secret": false,
"description": "This item is not secret",
"extra_perms": {},
"account": null,
"is_oauth": false,
"is_expired": false
}
```


## See Also

- [Documentation Index](./COMPASS.md)
