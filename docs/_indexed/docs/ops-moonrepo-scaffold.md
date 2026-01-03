---
id: ops/moonrepo/scaffold
title: "docker scaffold"
category: ops
tags: ["docker", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>docker scaffold</title>
  <description>The `moon docker scaffold &lt;...projects&gt;` command creates multiple repository skeletons for use within `Dockerfile`s, to effectively take advantage of Docker&apos;s layer caching. It utilizes the [project g</description>
  <created_at>2026-01-02T19:55:26.911024</created_at>
  <updated_at>2026-01-02T19:55:26.911024</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Arguments" level="3"/>
    <section name="Configuration" level="3"/>
    <section name="How it works" level="2"/>
    <section name="Workspace" level="3"/>
    <section name="Sources" level="3"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>configuration</feature>
    <feature>how_it_works</feature>
    <feature>sources</feature>
    <feature>workspace</feature>
  </features>
  <dependencies>
    <dependency type="service">docker</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/guides/docker</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/commands/run</entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>docker,operations,moonrepo</tags>
</doc_metadata>
-->

# docker scaffold

> **Context**: The `moon docker scaffold <...projects>` command creates multiple repository skeletons for use within `Dockerfile`s, to effectively take advantage of 

The `moon docker scaffold <...projects>` command creates multiple repository skeletons for use within `Dockerfile`s, to effectively take advantage of Docker's layer caching. It utilizes the [project graph](/docs/config/workspace#projects) to copy only critical files, like manifests, lockfiles, and configuration.

```
## Scaffold a skeleton to .moon/docker
$ moon docker scaffold <project>
```

> View the official [Docker usage guide](/docs/guides/docker) for a more in-depth example of how to utilize this command.

### Arguments

-   `<...projects>` - List of project names or aliases to scaffold sources for, as defined in [`projects`](/docs/config/workspace#projects).

### Configuration

-   [`docker.scaffold`](/docs/config/workspace#scaffold) in `.moon/workspace.yml` (entire workspace)
-   [`docker.scaffold`](/docs/config/project#scaffold) in `moon.yml` (per project)

## How it works

This command may seem like magic, but it's relative simple thanks to moon's infrastructure and its project graph. When the command is ran, we generate 2 skeleton structures in `.moon/docker` (be sure to gitignore this). One for the workspace, and the other for sources.

**Warning:** Because scaffolding uses the project graph, it requires all projects with a `package.json` to be [configured in moon](/docs/config/workspace#projects). Otherwise, moon will fail to copy all required files and builds may fail.

### Workspace

The workspace skeleton mirrors the project folder structure of the repository 1:1, and only copies files required for dependencies to install. This is typically manifests (`package.json`), lockfiles (`yarn.lock`, etc), other critical configs, and `.moon` itself. This is necessary for package managers to install dependencies (otherwise they will fail), and for dependencies to be layer cached in Docker.

An example of this skeleton using Yarn may look like the following:

```
.moon/docker/workspace/
├── .moon/
├── .yarn/
├── apps/
│   ├── client/
│   │   └── package.json
│   └── server/
│       └── package.json
├── packages/
│   ├── foo/
│   │   └── package.json
│   ├── bar/
│   │   └── package.json
│   └── baz/
│       └── package.json
├── .yarnrc.yml
├── package.json
└── yarn.lock
```

### Sources

The sources skeleton is not a 1:1 mirror of the repository, and instead is the source files of a project (passed as an argument to the command), and all of its dependencies. This allows [`moon run`](/docs/commands/run) and other commands to work within the `Dockerfile`, and avoid having to `COPY . .` the entire repository.

Using our example workspace above, our sources skeleton would look like the following, assuming our `client` project is passed as an argument, and this project depends on the `foo` and `baz` projects.

```
.moon/docker/sources/
├── apps/
│   └── client/
|       ├── src/
|       ├── tests/
|       ├── public/
|       ├── package.json
|       ├── tsconfig.json
│       └── (anything else)
└── packages/
    ├── foo/
    │   ├── lib/
    │   ├── src/
    │   ├── package.json
    │   ├── tsconfig.json
    │   └── (anything else)
    └── baz/
        ├── lib/
        ├── src/
        ├── package.json
        ├── tsconfig.json
        └── (anything else)
```


## See Also

- [project graph](/docs/config/workspace#projects)
- [Docker usage guide](/docs/guides/docker)
- [`projects`](/docs/config/workspace#projects)
- [`docker.scaffold`](/docs/config/workspace#scaffold)
- [`docker.scaffold`](/docs/config/project#scaffold)
