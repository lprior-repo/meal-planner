---
id: ops/moonrepo/cache
title: "Cache"
category: ops
tags: ["cache", "advanced", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Cache</title>
  <description>moon&apos;s able to achieve high performance and blazing speeds by implementing a cache that&apos;s powered by our own unique smart hashing layer. All cache is stored in `.moon/cache`, relative from the workspa</description>
  <created_at>2026-01-02T19:55:26.958097</created_at>
  <updated_at>2026-01-02T19:55:26.958097</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Hashing" level="2"/>
    <section name="Archiving &amp; hydration" level="2"/>
    <section name="File structure" level="2"/>
  </sections>
  <features>
    <feature>archiving_hydration</feature>
    <feature>file_structure</feature>
    <feature>hashing</feature>
  </features>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>cache,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Cache

> **Context**: moon's able to achieve high performance and blazing speeds by implementing a cache that's powered by our own unique smart hashing layer. All cache is 

moon's able to achieve high performance and blazing speeds by implementing a cache that's powered by our own unique smart hashing layer. All cache is stored in `.moon/cache`, relative from the workspace root (be sure to git ignore this folder).

## Hashing

Incremental builds are possible through a concept known as hashing, where in multiple sources are aggregated to generate a unique hash. In the context of moon, each time a target is ran we generate a hash, and if this hash already exists we abort early (cache hit), otherwise we continue the run (cache miss).

The tiniest change may trigger a different hash, for example, changing a line of code (when an input), or updating a package version, so don't worry if you see *a lot* of hashes.

Our smart hashing currently takes the following sources into account:

-   Command (`command`) being ran and its arguments (`args`).
-   Input sources (`inputs`).
-   Output targets (`outputs`).
-   Environment variables (`env`).
-   Dependencies between projects (`dependsOn`) and tasks (`deps`).
-   **For Deno tasks**:
    -   Deno version.
    -   `deno.json`/`deps.ts` imports, import maps, and scopes.
    -   `tsconfig.json` compiler options (when applicable).
-   **For Bun and Node.js tasks**:
    -   Bun/Node.js version.
    -   `package.json` dependencies (including development and peer).
    -   `tsconfig.json` compiler options (when applicable).

> **Caution**: Be aware that greedy inputs (`**/*`, the default) will include *everything* in the target directory as a source. We do our best to filter out VCS ignored files, and `outputs` for the current task, but files may slip through that you don't expect. We suggest using explicit `inputs` and routinely auditing the hash files for accuracy!

## Archiving & hydration

On top of our hashing layer, we have another concept known as archiving, where in we create a tarball archive of a task's outputs and store it in `.moon/cache/outputs`. These are akin to build artifacts.

When we encounter a cache hit on a hash, we trigger a mechanism known as hydration, where we efficiently unpack an existing tarball archive into a task's outputs. This can be understood as a timeline, where every point in time will have its own hash + archive that moon can play back.

Furthermore, if we receive a cache hit on the hash, and the hash is the same as the last run, and outputs exist, we exit early without hydrating and assume the project is already hydrated. In the terminal, you'll see a message for "cached".

## File structure

The following diagram outlines our cache folder structure and why each piece exists.

```
.moon/cache/
	# Stores hash manifests of every ran task. Exists purely for debugging purposes.
	hashes/
		# Contents includes all sources used to generate the hash.
		<hash>.json

	# Stores `tar.gz` archives of a task's outputs based on its generated hash.
	outputs/
		<hash>.tar.gz

	# State information about anything and everything within moon. Toolchain,
	# dependencies, projects, running targets, etc.
	states/
		# Files at the root pertain to the entire workspace.
		<state>.json

		# Files for a project are nested within a folder by the project name.
		<project>/
			# Informational snapshot of the project, its tasks, and its configs.
			# Can be used at runtime by tasks that require this information.
			snapshot.json

			<task>/
				# Contents of the child process, including the exit code and
				# unique hash that is referenced above.
				lastRun.json

				# Outputs of last run target.
				stderr.log
				stdout.log
```


## See Also

- [Documentation Index](./COMPASS.md)
