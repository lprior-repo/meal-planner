---
doc_id: ops/windmill/sync
chunk_id: ops/windmill/sync#chunk-1
heading_path: ["Sync"]
chunk_type: code
tokens: 660
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Sync</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.500165</created_at>
  <updated_at>2026-01-02T19:55:27.500165</updated_at>
  <language>en</language>
  <sections count="15">
    <section name="Pulling" level="3"/>
    <section name="Pushing" level="3"/>
    <section name="Pull API" level="2"/>
    <section name="Options" level="3"/>
    <section name="Push API" level="2"/>
    <section name="Options" level="3"/>
    <section name="wmill.yaml" level="2"/>
    <section name="Basic configuration" level="3"/>
    <section name="Git branch-specific configuration" level="3"/>
    <section name="Configuration resolution priority" level="3"/>
  </sections>
  <features>
    <feature>basic_configuration</feature>
    <feature>cloning_an_instance</feature>
    <feature>codebase_configuration</feature>
    <feature>configuration_resolution_priority</feature>
    <feature>git_branch-specific_configuration</feature>
    <feature>options</feature>
    <feature>pull_api</feature>
    <feature>pulling</feature>
    <feature>pulling_an_instance</feature>
    <feature>push_api</feature>
    <feature>pushing</feature>
    <feature>pushing_an_instance</feature>
    <feature>wmill_init</feature>
    <feature>wmill_sync</feature>
    <feature>wmillyaml</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="library">react</dependency>
    <dependency type="service">postgres</dependency>
    <dependency type="feature">ops/windmill/branch-specific-items</dependency>
    <dependency type="feature">meta/windmill/index-22</dependency>
    <dependency type="feature">meta/windmill/index-2</dependency>
    <dependency type="feature">ops/windmill/workspace-management</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./branch-specific-items.mdx</entity>
    <entity relationship="uses">../../cli_local_dev/1_vscode-extension/index.mdx</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">../11_git_sync/index.mdx</entity>
    <entity relationship="uses">./workspace-management.md</entity>
    <entity relationship="uses">./workspace-management.md</entity>
    <entity relationship="uses">./workspace-management.md</entity>
  </related_entities>
  <examples count="8">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>10</estimated_reading_time>
  <tags>windmill,advanced,sync,operations</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Sync

> **Context**: import DocCard from '@site/src/components/DocCard';

Synchronizing folders & git repositories to a Windmill instance is made easy
using the wmill CLI. Syncing operations are behind the `wmill sync` subcommand.

The CLI supports [branch-specific items](./ops-windmill-branch-specific-items.md) that allow different Git branches to have different versions of resources and variables.

Having a Windmill instance synchronized to folders & git repositories allows for
local development through the [VS Code extension](./meta-windmill-index-22.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="VS Code extension"
		description="Build scripts and flows in the comfort of your VS Code editor, while leveraging Windmill UIs for test & flows edition."
		href="/docs/cli_local_dev/vscode-extension"
	/>
</div>

Syncing is done using `wmill sync pull` & `wmill sync push`.

Syncing is a one-off operation with no state maintained. It will override any item that is within the scope: remove those that are in the target and not in the source, and it will create new items that are in source but not in target.
It is a _dangerous_ operation, that we recommend doing on a version-controlled folder to be able to revert any undesired changes made by mistake if necessary. It will however, show you the list of changes and ask you for confirmation before applying them.

To specify the scopes of files, you should modify the includes and excludes (array of path matchers) part of the `wmill.yaml` file generated with `wmill init`. We recommend looking at all the settings of the `wmill.yaml` file to understand the different options available.
Those are the default ones:

```yaml
defaultTs: bun
includes:
  - f/**
excludes: []
codebases: []
skipVariables: true
skipResources: true
skipResourceTypes: true
skipSecrets: true
includeSchedules: false
includeTriggers: false
```

See more details in [wmill.yaml](#wmillyaml).

Note that here, the variables, resources, secrets, schedules, and triggers are all skipped by default. You can change that by setting the corresponding options.

When pulling, the source is the remote workspace and the target is the local folder, and when pushing, the source is the local folder and the target is the remote workspace.

To add a remote workspace, use `wmill workspace add`, and to switch workspace after having added multiple, use `wmill workspace switch <source_workspace_id>`. The workspaces can be on completely different instances.

```bash
wmill workspace switch <source_workspace_id>
wmill sync pull
wmill workspace switch <target_workspace_id>
wmill sync push
```

It can be used for bi-directional sync using Windmill EE and [Git sync](./meta-windmill-index-2.md).
