---
doc_id: ops/moonrepo/vue
chunk_id: ops/moonrepo/vue#chunk-1
heading_path: ["Vue example"]
chunk_type: prose
tokens: 270
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Vue example</title>
  <description>Vue is an application or library concern, and not a build system one, since the bundling of Vue is abstracted away through other tools. Because of this, moon has no guidelines around utilizing Vue dir</description>
  <created_at>2026-01-02T19:55:27.123051</created_at>
  <updated_at>2026-01-02T19:55:27.123051</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Setup" level="2"/>
    <section name="ESLint integration" level="3"/>
    <section name="TypeScript integration" level="3"/>
  </sections>
  <features>
    <feature>eslint_integration</feature>
    <feature>setup</feature>
    <feature>typescript_integration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/guides/examples/vite</entity>
    <entity relationship="uses">/docs/guides/examples/eslint</entity>
    <entity relationship="uses">/docs/guides/examples/typescript</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>vue,operations,moonrepo</tags>
</doc_metadata>
-->

# Vue example

> **Context**: Vue is an application or library concern, and not a build system one, since the bundling of Vue is abstracted away through other tools. Because of thi

Vue is an application or library concern, and not a build system one, since the bundling of Vue is abstracted away through other tools. Because of this, moon has no guidelines around utilizing Vue directly. You can use Vue however you wish!

However, with that being said, Vue is typically coupled with [Vite](https://vitejs.dev/). To scaffold a new Vue project with Vite, run the following command in a project root.

```
npm init vue@latest
```

> We highly suggest reading our documentation on [using Vite (and Vitest) with moon](/docs/guides/examples/vite) for a more holistic view.
