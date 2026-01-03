---
doc_id: ref/moonrepo/typescript-project-refs
chunk_id: ref/moonrepo/typescript-project-refs#chunk-1
heading_path: ["TypeScript project references"]
chunk_type: prose
tokens: 562
summary: "<!--"
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>build-tools</category>
  <title>TypeScript project references</title>
  <description>How to use TypeScript in a monorepo? What are project references? Why use project references? What is the best way to use project references? These are just a handful of questions that are *constantly</description>
  <created_at>2026-01-02T19:55:27.151992</created_at>
  <updated_at>2026-01-02T19:55:27.151992</updated_at>
  <language>en</language>
  <sections count="33">
    <section name="Preface" level="2"/>
    <section name="Configuration" level="2"/>
    <section name="Root-level" level="3"/>
    <section name="`tsconfig.json`" level="4"/>
    <section name="`tsconfig.options.json`" level="4"/>
    <section name="ECMAScript interoperability" level="5"/>
    <section name="`.gitignore`" level="4"/>
    <section name="Project-level" level="3"/>
    <section name="`tsconfig.json`" level="4"/>
    <section name="Includes and excludes" level="5"/>
  </sections>
  <features>
    <feature>configuration</feature>
    <feature>depending_on_other_projects</feature>
    <feature>do_i_have_to_use_project_references</feature>
    <feature>ecmascript_interoperability</feature>
    <feature>editor_integration</feature>
    <feature>enabling_importsexports_resolution</feature>
    <feature>gitignore</feature>
    <feature>how_to_handle_circular_references</feature>
    <feature>how_to_integrate_with_eslint</feature>
    <feature>includes_and_excludes</feature>
    <feature>on_affected_projects</feature>
    <feature>on_all_projects</feature>
    <feature>on_an_individual_project</feature>
    <feature>package_publishing</feature>
    <feature>preface</feature>
  </features>
  <related_entities>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/toolchain</entity>
  </related_entities>
  <examples count="21">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>20</estimated_reading_time>
  <tags>typescript,advanced,reference,moonrepo</tags>
</doc_metadata>
-->

# TypeScript project references

> **Context**: How to use TypeScript in a monorepo? What are project references? Why use project references? What is the best way to use project references? These ar

> The ultimate in-depth guide for using TypeScript in a monorepo effectively!

How to use TypeScript in a monorepo? What are project references? Why use project references? What is the best way to use project references? These are just a handful of questions that are *constantly* asked on Twitter, forums, Stack Overflow, and even your workplace.

Based on years of experience managing large-scale frontend repositories, we firmly believe that TypeScript project references are the proper solution for effectively scaling TypeScript in a monorepo. The official [TypeScript documentation on project references](https://www.typescriptlang.org/docs/handbook/project-references.html) answers many of these questions, but it basically boils down to the following:

- Project references *enforce project boundaries, disallowing imports* to arbitrary projects unless they have been referenced explicitly in configuration. This avoids circular references / cycles.
- It enables TypeScript to *process individual units*, instead of the entire repository as a whole. Perfect for reducing CI and local development times.
- It supports *incremental compilation*, so only out-of-date or affected projects are processed. The more TypeScript's cache is warmed, the faster it will be.
- It simulates how types work in the Node.js package ecosystem.

This all sounds amazing but there's got to be some downsides right? Unfortunately, there is:

- Project references require generating declarations to resolve type information correctly. This results in a lot of compilation artifacts littered throughout the repository. There [are ways](#gitignore) [around this](/docs/config/toolchain#routeoutdirtocache).
- This approach is a bit involved and may require some cognitive overhead based on your current level of TypeScript tooling knowledge.

success

If you'd like a real-world repository to reference, our [moonrepo/moon](https://github.com/moonrepo/moon), [moonrepo/dev](https://github.com/moonrepo/dev), and [moonrepo/examples](https://github.com/moonrepo/examples) repositories utilizes this architecture!
