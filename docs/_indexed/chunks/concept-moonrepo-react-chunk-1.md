---
doc_id: concept/moonrepo/react
chunk_id: concept/moonrepo/react#chunk-1
heading_path: ["React example"]
chunk_type: prose
tokens: 252
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>React example</title>
  <description>React is an application or library concern, and not a build system one, since the bundling of React is abstracted away through another tool like webpack. Because of this, moon has no guidelines around</description>
  <created_at>2026-01-02T19:55:27.104697</created_at>
  <updated_at>2026-01-02T19:55:27.104697</updated_at>
  <language>en</language>
  <dependencies>
    <dependency type="library">react</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/concepts/cache</entity>
    <entity relationship="uses">/docs/guides/examples/typescript</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>react,concept,moonrepo</tags>
</doc_metadata>
-->

# React example

> **Context**: React is an application or library concern, and not a build system one, since the bundling of React is abstracted away through another tool like webpa

React is an application or library concern, and not a build system one, since the bundling of React is abstracted away through another tool like webpack. Because of this, moon has no guidelines around utilizing React directly. You can use React however you wish!

However, with that being said, we do suggest the following:

- Add `react` and related dependencies to each project, not the root. This includes `@types/react` as well. This will ensure accurate [hashing](/docs/concepts/cache#hashing).

```
yarn workspace <project> add react
```

- Configure Babel with the `@babel/preset-react` preset.
- Configure [TypeScript](/docs/guides/examples/typescript) compiler options with `"jsx": "react-jsx"`.
