---
id: ops/moonrepo/prune
title: "docker prune"
category: ops
tags: ["docker", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>docker prune</title>
  <description>The `moon docker prune` command will reduce the overall filesize of the Docker environment by installing production only dependencies for projects that were scaffolded, and removing any applicable ext</description>
  <created_at>2026-01-02T19:55:26.910122</created_at>
  <updated_at>2026-01-02T19:55:26.910122</updated_at>
  <language>en</language>
  <sections count="1">
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>configuration</feature>
  </features>
  <dependencies>
    <dependency type="service">docker</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/guides/docker</entity>
    <entity relationship="uses">/docs/commands/docker/scaffold</entity>
    <entity relationship="uses">/docs/commands/docker/file</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>docker,operations,moonrepo</tags>
</doc_metadata>
-->

# docker prune

> **Context**: The `moon docker prune` command will reduce the overall filesize of the Docker environment by installing production only dependencies for projects tha

The `moon docker prune` command will reduce the overall filesize of the Docker environment by installing production only dependencies for projects that were scaffolded, and removing any applicable extraneous files.

```
$ moon docker prune
```

> View the official [Docker usage guide](/docs/guides/docker) for a more in-depth example of how to utilize this command.

**Caution:** This command *must be* ran after [`moon docker scaffold`](/docs/commands/docker/scaffold) and is typically ran within a `Dockerfile`! The [`moon docker file`](/docs/commands/docker/file) command can be used to generate a `Dockerfile`.

## Configuration

-   [`docker.prune`](/docs/config/workspace#prune) in `.moon/workspace.yml`


## See Also

- [Docker usage guide](/docs/guides/docker)
- [`moon docker scaffold`](/docs/commands/docker/scaffold)
- [`moon docker file`](/docs/commands/docker/file)
- [`docker.prune`](/docs/config/workspace#prune)
