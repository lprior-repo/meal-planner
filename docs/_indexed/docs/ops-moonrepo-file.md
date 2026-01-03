---
id: ops/moonrepo/file
title: "docker file"
category: ops
tags: ["docker", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>docker file</title>
  <description>The `moon docker file &lt;project&gt;` command can be used to generate a multi-staged `Dockerfile` for a project, that takes full advantage of Docker&apos;s layer caching, and is primarily for production deploys</description>
  <created_at>2026-01-02T19:55:26.908390</created_at>
  <updated_at>2026-01-02T19:55:26.908390</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>configuration</feature>
    <feature>options</feature>
  </features>
  <dependencies>
    <dependency type="service">docker</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/commands/docker/scaffold</entity>
    <entity relationship="uses">/docs/commands/docker/setup</entity>
    <entity relationship="uses">/docs/commands/docker/prune</entity>
    <entity relationship="uses">/docs/guides/docker</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>docker,operations,moonrepo</tags>
</doc_metadata>
-->

# docker file

> **Context**: The `moon docker file <project>` command can be used to generate a multi-staged `Dockerfile` for a project, that takes full advantage of Docker's laye

v1.27.0

The `moon docker file <project>` command can be used to generate a multi-staged `Dockerfile` for a project, that takes full advantage of Docker's layer caching, and is primarily for production deploys (this should not be used for development).

```
$ moon docker file <project>
```

As mentioned above, the generated `Dockerfile` uses a multi-stage approach, where each stage is broken up into the following:

-   `base` - The base stage, which simply installs moon for a chosen Docker image. This stage requires Bash.
-   `skeleton` - Scaffolds workspace and sources repository skeletons using [`moon docker scaffold`](/docs/commands/docker/scaffold).
-   `build` - Copies required sources, installs the toolchain using [`moon docker setup`](/docs/commands/docker/setup), optionally builds the project, and optionally prunes the image using [`moon docker prune`](/docs/commands/docker/prune).
-   `start` - Runs the project after it has been built. This is typically starting an HTTP server, or executing a binary.

> View the official [Docker usage guide](/docs/guides/docker) for a more in-depth example of how to utilize this command.

## Arguments

-   `<name>` - Name or alias of a project, as defined in [`projects`](/docs/config/workspace#projects).
-   `[dest]` - Destination to write the file, relative from the project root. Defaults to `Dockerfile`.

### Options

-   `--defaults` - Use default options instead of prompting in the terminal.
-   `--buildTask` - Name of a task to build the project. Defaults to the [`docker.file.buildTask`](/docs/config/project#buildtask) setting, or prompts in the terminal.
-   `--image` - Base Docker image to use. Defaults to an image derived from the toolchain, or prompts in the terminal.
-   `--no-prune` - Do not prune the workspace in the build stage.
-   `--no-toolchain` - Do not use the toolchain and instead use system binaries.
-   `--startTask` - Name of a task to start the project. Defaults to the [`docker.file.startTask`](/docs/config/project#starttask) setting, or prompts in the terminal.

### Configuration

-   [`docker.file`](/docs/config/project#file) in `moon.yml`


## See Also

- [`moon docker scaffold`](/docs/commands/docker/scaffold)
- [`moon docker setup`](/docs/commands/docker/setup)
- [`moon docker prune`](/docs/commands/docker/prune)
- [Docker usage guide](/docs/guides/docker)
- [`projects`](/docs/config/workspace#projects)
