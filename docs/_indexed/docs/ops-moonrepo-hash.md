---
id: ops/moonrepo/hash
title: "query hash"
category: ops
tags: ["query", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>query hash</title>
  <description>Use the `moon query hash` sub-command to inspect the contents and sources of a generated hash, also known as the hash manifest. This is extremely useful in debugging task inputs.</description>
  <created_at>2026-01-02T19:55:26.929834</created_at>
  <updated_at>2026-01-02T19:55:26.929834</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="Options" level="3"/>
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>options</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/workspace</entity>
  </related_entities>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>query,operations,moonrepo</tags>
</doc_metadata>
-->

# query hash

> **Context**: Use the `moon query hash` sub-command to inspect the contents and sources of a generated hash, also known as the hash manifest. This is extremely usef

Use the `moon query hash` sub-command to inspect the contents and sources of a generated hash, also known as the hash manifest. This is extremely useful in debugging task inputs.

```
$ moon query hash 0b55b234f1018581c45b00241d7340dc648c63e639fbafdaf85a4cd7e718fdde

## Query hash using short form
$ moon query hash 0b55b234
```

By default, this will output the contents of the hash manifest (which is JSON), and the fully qualified resolved hash.

```
Hash: 0b55b234f1018581c45b00241d7340dc648c63e639fbafdaf85a4cd7e718fdde

{
  "command": "build",
  "args": ["./build"]
  // ...
}
```

The command can also be output raw JSON by passing the `--json` flag.

### Options

- `--json` - Display the diff in JSON format.

### Configuration

- [`hasher`](/docs/config/workspace#hasher) in `.moon/workspace.yml`


## See Also

- [`hasher`](/docs/config/workspace#hasher)
