---
id: concept/windmill/app
title: "Apps"
category: concept
tags: ["windmill", "apps", "concept"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Apps</title>
  <description>&lt;!-- &lt;doc_metadata&gt; &lt;type&gt;reference&lt;/type&gt; &lt;category&gt;cli&lt;/category&gt; &lt;title&gt;Windmill CLI App Commands&lt;/title&gt; &lt;description&gt;Manage apps via CLI&lt;/description&gt; &lt;created_at&gt;2025-12-28T00:00:00Z&lt;/created_at</description>
  <created_at>2026-01-02T19:55:27.473468</created_at>
  <updated_at>2026-01-02T19:55:27.473468</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Listing apps" level="2"/>
    <section name="Pushing an app" level="2"/>
    <section name="Arguments" level="3"/>
    <section name="Examples" level="3"/>
    <section name="Remote path format" level="2"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>examples</feature>
    <feature>listing_apps</feature>
    <feature>pushing_an_app</feature>
    <feature>remote_path_format</feature>
    <feature>wmill_app</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
  </dependencies>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>windmill,apps,concept</tags>
</doc_metadata>
-->

<!--
<doc_metadata>
  <type>reference</type>
  <category>cli</category>
  <title>Windmill CLI App Commands</title>
  <description>Manage apps via CLI</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00Z</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Apps" level="1"/>
    <section name="Listing apps" level="2"/>
    <section name="Pushing an app" level="2"/>
  </sections>
  <features>
    <feature>wmill_cli</feature>
    <feature>app_management</feature>
    <feature>app_push</feature>
  </features>
  <dependencies>
    <dependency type="tool">wmill_cli</dependency>
  </dependencies>
  <examples count="1">
    <example>Push app JSON specification to remote</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,cli,wmill,app,list,push,JSON</tags>
</doc_metadata>
-->

# Apps

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>cli</category> <title>Windmill CLI App Commands</title> <description>Manage apps via CLI</descrip

## Listing apps

The `wmill app` list command is used to list all apps in the remote workspace.

```bash
wmill app
```text

## Pushing an app

Pushing an app to a Windmill instance is done using the `wmill app push` command.

```bash
wmill app push <file_path>
```text

### Arguments

| Argument    | Description                       |
| ----------- | --------------------------------- |
| `file_path` | The path to the app file to push. |

### Examples

1. Push the app located at `./my_app.json`.

```bash
wmill app push ./my_app.json
```text

## Remote path format

```js
<u|g|f>/<username|group|folder>/...
```


## See Also

- [Documentation Index](./COMPASS.md)
