---
doc_id: ops/moonrepo/info
chunk_id: ops/moonrepo/info#chunk-1
heading_path: ["toolchain info"]
chunk_type: code
tokens: 241
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>toolchain info</title>
  <description>The `moon toolchain info &lt;id&gt; [plugin]` command will display detailed information about a toolchain, like what files are scanned, what configuration settings are available, and what tier APIs are supp</description>
  <created_at>2026-01-02T19:55:26.947056</created_at>
  <updated_at>2026-01-02T19:55:26.947056</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="Arguments" level="3"/>
    <section name="Example output" level="2"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>example_output</feature>
  </features>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>api,toolchain,operations,moonrepo</tags>
</doc_metadata>
-->

# toolchain info

> **Context**: The `moon toolchain info <id> [plugin]` command will display detailed information about a toolchain, like what files are scanned, what configuration s

v1.38.0

The `moon toolchain info <id> [plugin]` command will display detailed information about a toolchain, like what files are scanned, what configuration settings are available, and what tier APIs are supported. To do this, the command will download the WASM plugin, extract information, and call specific functions.

For built-in toolchains, the [plugin locator] argument is optional, and will be derived from the identifier.

```
$ moon toolchain info typescript
```

For third-party toolchains, the [plugin locator] argument is required, and must point to the WASM plugin.

```
$ moon toolchain info custom https://example.com/path/to/plugin.wasm
```
