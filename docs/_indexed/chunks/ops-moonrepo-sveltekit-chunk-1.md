---
doc_id: ops/moonrepo/sveltekit
chunk_id: ops/moonrepo/sveltekit#chunk-1
heading_path: ["SvelteKit example"]
chunk_type: prose
tokens: 293
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>SvelteKit example</title>
  <description>[SvelteKit](https://kit.svelte.dev) is built on [Svelte](https://svelte.dev), a UI framework that uses a compiler to let you write breathtakingly concise components that do minimal work in the browser</description>
  <created_at>2026-01-02T19:55:27.111400</created_at>
  <updated_at>2026-01-02T19:55:27.111400</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="Setup" level="2"/>
    <section name="ESLint integration" level="3"/>
    <section name="TypeScript integration" level="3"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="Project-level" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>eslint_integration</feature>
    <feature>js_config</feature>
    <feature>project-level</feature>
    <feature>root-level</feature>
    <feature>setup</feature>
    <feature>typescript_integration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/guides/examples/vite</entity>
    <entity relationship="uses">/docs/guides/examples/eslint</entity>
    <entity relationship="uses">/docs/guides/examples/prettier</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/guides/examples/eslint</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/guides/examples/typescript</entity>
  </related_entities>
  <examples count="7">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>sveltekit,advanced,operations,javascript,moonrepo</tags>
</doc_metadata>
-->

# SvelteKit example

> **Context**: [SvelteKit](https://kit.svelte.dev) is built on [Svelte](https://svelte.dev), a UI framework that uses a compiler to let you write breathtakingly conc

[SvelteKit](https://kit.svelte.dev) is built on [Svelte](https://svelte.dev), a UI framework that uses a compiler to let you write breathtakingly concise components that do minimal work in the browser, using languages you already know — HTML, CSS and JavaScript. It's a love letter to web development.

```
cd apps && npm create svelte@latest <project>
```

You will be prompted to choose between select templates, TypeScript, ESLint, Prettier, Playwright and Vitest among other options. moon supports and has guides for many of these tools.

> We highly suggest reading our documentation on [using Vite (and Vitest) with moon](/docs/guides/examples/vite), [using ESLint with moon](/docs/guides/examples/eslint) and [using Prettier with moon](/docs/guides/examples/prettier) for a more holistic view.
