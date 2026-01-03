---
doc_id: ops/moonrepo/bin
chunk_id: ops/moonrepo/bin#chunk-1
heading_path: ["bin"]
chunk_type: prose
tokens: 241
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>bin</title>
  <description>The `moon bin &lt;tool&gt;` command will return an absolute path to a tool&apos;s binary within the toolchain. If a tool has not been configured or installed, this will return a 1 or 2 exit code with no value re</description>
  <created_at>2026-01-02T19:55:26.903594</created_at>
  <updated_at>2026-01-02T19:55:26.903594</updated_at>
  <language>en</language>
  <sections count="1">
    <section name="Arguments" level="3"/>
  </sections>
  <features>
    <feature>arguments</feature>
  </features>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>bin,operations,moonrepo</tags>
</doc_metadata>
-->

# bin

> **Context**: The `moon bin <tool>` command will return an absolute path to a tool's binary within the toolchain. If a tool has not been configured or installed, th

The `moon bin <tool>` command will return an absolute path to a tool's binary within the toolchain. If a tool has not been configured or installed, this will return a 1 or 2 exit code with no value respectively.

```
$ moon bin node
/Users/example/.proto/tools/node/x.x.x/bin/node
```

> A tool is considered "not configured" when not in use, for example, querying yarn/pnpm when the package manager is configured for "npm". A tool is considered "not installed", when it has not been downloaded and installed into the tools directory.
