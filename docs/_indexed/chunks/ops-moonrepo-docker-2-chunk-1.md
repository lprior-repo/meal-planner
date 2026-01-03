---
doc_id: ops/moonrepo/docker-2
chunk_id: ops/moonrepo/docker-2#chunk-1
heading_path: ["Docker integration"]
chunk_type: prose
tokens: 257
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Docker integration</title>
  <description>Using [Docker](https://www.docker.com/) to run your applications? Or build your artifacts? No worries, moon can be utilized with Docker, and supports a robust integration layer.</description>
  <created_at>2026-01-02T19:55:27.077729</created_at>
  <updated_at>2026-01-02T19:55:27.077729</updated_at>
  <language>en</language>
  <sections count="22">
    <section name="Requirements" level="2"/>
    <section name="Creating a `Dockerfile`" level="2"/>
    <section name="What we&apos;re trying to avoid" level="3"/>
    <section name="Scaffolding the bare minimum" level="3"/>
    <section name="Non-staged" level="4"/>
    <section name="Multi-staged" level="4"/>
    <section name="BASE" level="4"/>
    <section name="SKELETON" level="4"/>
    <section name="BUILD" level="4"/>
    <section name="Copying necessary source files" level="3"/>
  </sections>
  <features>
    <feature>base</feature>
    <feature>build</feature>
    <feature>copying_necessary_source_files</feature>
    <feature>creating_a_dockerfile</feature>
    <feature>final_result</feature>
    <feature>multi-staged</feature>
    <feature>non-staged</feature>
    <feature>pruning_extraneous_files</feature>
    <feature>requirements</feature>
    <feature>running_docker_commands</feature>
    <feature>scaffolding_the_bare_minimum</feature>
    <feature>skeleton</feature>
    <feature>supporting_nodealpine_images</feature>
    <feature>troubleshooting</feature>
    <feature>what_were_trying_to_avoid</feature>
  </features>
  <dependencies>
    <dependency type="service">docker</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/commands/docker/file</entity>
    <entity relationship="uses">/docs/commands/docker/scaffold</entity>
    <entity relationship="uses">/docs/commands/docker/scaffold</entity>
    <entity relationship="uses">/docs/commands/docker/scaffold</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/commands/docker/prune</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/concepts/toolchain</entity>
  </related_entities>
  <examples count="12">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>7</estimated_reading_time>
  <tags>docker,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Docker integration

> **Context**: Using [Docker](https://www.docker.com/) to run your applications? Or build your artifacts? No worries, moon can be utilized with Docker, and supports 

Using [Docker](https://www.docker.com/) to run your applications? Or build your artifacts? No worries, moon can be utilized with Docker, and supports a robust integration layer.

> Looking to speed up your Docker builds? Want to build in the cloud? [Give Depot a try](https://depot.dev?ref=moonrepo)!
