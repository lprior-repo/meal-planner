---
id: ops/moonrepo/from-package-json
title: "migrate from-package-json"
category: ops
tags: ["migrate", "advanced", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>migrate from-package-json</title>
  <description>Use the `moon migrate from-package-json &lt;project&gt;` sub-command to migrate a project&apos;s `package.json` to our [`moon.yml`](/docs/config/project) format. When ran, the following changes are made:</description>
  <created_at>2026-01-02T19:55:26.918410</created_at>
  <updated_at>2026-01-02T19:55:26.918410</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="Arguments" level="3"/>
    <section name="Caveats" level="2"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>caveats</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/faq</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>migrate,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# migrate from-package-json

> **Context**: Use the `moon migrate from-package-json <project>` sub-command to migrate a project's `package.json` to our [`moon.yml`](/docs/config/project) format.

Use the `moon migrate from-package-json <project>` sub-command to migrate a project's `package.json` to our [`moon.yml`](/docs/config/project) format. When ran, the following changes are made:

-   Converts `package.json` scripts to `moon.yml` [tasks](/docs/config/project#tasks). Scripts and tasks are not 1:1, so we'll convert as close as possible while retaining functionality.
-   Updates `package.json` by removing all converted scripts. If all scripts were converted, the entire block is removed.
-   Links `package.json` dependencies as `moon.yml` [dependencies](/docs/config/project#dependson) (`dependsOn`). Will map a package's name to their moon project name.

This command is ran *per project*, and for this to operate correctly, requires all [projects to be configured in the workspace](/docs/config/workspace#projects). There's also a handful of [requirements and caveats](#caveats) to be aware of!

```
$ moon --log debug migrate from-package-json app
```

**Caution:** moon does its best to infer the [`local`](/docs/config/project#local) option, given the small amount of information available to use. When this option is incorrectly set, it'll result in CI environments hanging for tasks that are long-running or never-ending (development servers, etc), or won't run builds that should be. Be sure to audit each task after migration!

## Arguments

-   `<project>` - Name of a project, as defined in [`projects`](/docs/config/workspace#projects).

## Caveats

-   When running a script within another script, the full invocation of `npm run ...`, `pnpm run ...`, or `yarn run ...` must be used. Shorthand variants are **not** supported, for example, `npm test` or `yarn lint` or `pnpm format`. We cannot guarantee that moon will parse these correctly otherwise.

    ```json
    {
        "scripts": {
            "lint": "eslint .",
            "lint:fix": "yarn run lint --fix"
        }
    }
    ```

-   Scripts that run multiple commands with the AND operator (`&&`) will create an individual transient task for each command, with all tasks linked *in-order* using task [`deps`](/docs/config/project#deps). These commands *will not* run in parallel. For example, given the following script:

    ```json
    {
        "scripts": {
            "check": "yarn run lint && yarn run test && yarn run typecheck"
        }
    }
    ```

    Would create 3 tasks that create the dependency chain: `check-dep1 (lint) -> check-dep2 (test) -> check (typecheck)`, instead of the expected parallel execution of `lint | test | typecheck -> check`. If you would prefer these commands to run in parallel, then you'll need to craft your tasks manually.

-   Scripts that change directory (`cd ...`), use pipes (`|`), redirects (`>`), or the OR operator (`||`) are **not** supported and will be skipped. Tasks and scripts are not 1:1 in functionality, as tasks represent that state of a single command execution. However, you can wrap this functionality in a [custom script that executes it on the task's behalf](/docs/faq#how-to-pipe-or-redirect-tasks).

-   [Life cycle scripts](https://docs.npmjs.com/cli/v8/using-npm/scripts#life-cycle-scripts) are **not** converted to tasks and will remain in `package.json` since they're required by npm (and other package managers). However, their commands *will* be updated to execute moon commands when applicable.

    ```json
    {
        "scripts": {
            "preversion": "moon run project:lint && moon run project:test"
        }
    }
    ```

    > This *does not* apply to `run`, `start`, `stop`, and `test` life cycles.

-   "Post" life cycles for [user defined scripts](https://docs.npmjs.com/cli/v8/using-npm/scripts#npm-run-user-defined) do not work, as moon tasks have no concept of "run this after the task completes", so we suggest *against using these entirely*. However, we still convert the script and include the base script as a task dependency.

    For example, a `posttest` script would be converted into a `posttest` task, with the `test` task included in [`deps`](/docs/config/project#deps). For this to actually run correctly, you'll need to use `moon run <project>:posttest` AND NOT `moon run <project>:test`.


## See Also

- [`moon.yml`](/docs/config/project)
- [tasks](/docs/config/project#tasks)
- [dependencies](/docs/config/project#dependson)
- [projects to be configured in the workspace](/docs/config/workspace#projects)
- [requirements and caveats](#caveats)
