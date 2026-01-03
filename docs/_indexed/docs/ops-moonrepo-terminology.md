---
id: ops/moonrepo/terminology
title: "Terminology"
category: ops
tags: ["terminology", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Terminology</title>
  <description>| Term | Description | |------|-------------| | Action | A node within the dependency graph that gets executed by the action pipeline. | | Action pipeline | Executes actions from our dependency graph </description>
  <created_at>2026-01-02T19:55:27.236433</created_at>
  <updated_at>2026-01-02T19:55:27.236433</updated_at>
  <language>en</language>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>terminology,operations,moonrepo</tags>
</doc_metadata>
-->

# Terminology

> **Context**: | Term | Description | |------|-------------| | Action | A node within the dependency graph that gets executed by the action pipeline. | | Action pipe

| Term | Description |
|------|-------------|
| Action | A node within the dependency graph that gets executed by the action pipeline. |
| Action pipeline | Executes actions from our dependency graph in topological order using a thread pool. |
| Affected | Touched by an explicit set of inputs or sources. |
| Cache | Files and outputs that are stored on the file system to provide incremental builds and increased performance. |
| CI | Continuous integration. An environment where tests, builds, lints, etc, are continuously ran on every pull/merge request. |
| Dependency graph | A directed acyclic graph (DAG) of targets to run and their dependencies. |
| Downstream | Dependents or consumers of the item in question. |
| Generator | Generates code from pre-defined templates. |
| Hash | A unique SHA256 identifier that represents the result of a ran task. |
| Hashing | The mechanism of generating a hash based on multiple sources: inputs, dependencies, configs, etc. |
| LTS | Long-term support. |
| Dependency manager | Installs and manages dependencies for a specific tool (`npm`), using a manifest file (`package.json`). |
| Platform | An internal concept representing the integration of a programming language (tool) within moon, and also the environment + language that a task runs in. |
| Primary target | The target that was explicitly ran, and is the dependee of transitive targets. |
| Project | An collection of source and test files, configurations, a manifest and dependencies, and much more. Exists within a workspace |
| Revision | In the context of a VCS: a branch, revision, commit, hash, or point in history. |
| Runtime | An internal concept representing the platform + version of a tool. |
| Target | A label and reference to a task within the project, in the format of `project:task`. |
| Task | A command to run within the context of and configured in a project. |
| Template | A collection of files that get scaffolded by a generator. |
| Template file | An individual file within a template. |
| Template variable | A value that is interpolated within a template file and its file system path. |
| Token | A value within task configuration that is substituted at runtime. |
| Tool | A programming language or dependency manager within the toolchain. |
| Toolchain | Installs and manages tools within the workspace. |
| Transitive target | A target that is the dependency of the primary target, and must be ran before the primary. |
| Touched | A file that has been created, modified, deleted, or changed in any way. |
| Upstream | Dependencies or producers of the item in question. |
| VCS | Version control system (like Git or SVN). |
| Workspace | Root of the moon installation, and houses one or many projects. *Also refers to package manager workspaces (like Yarn).* |


## See Also

- [Documentation Index](./COMPASS.md)
