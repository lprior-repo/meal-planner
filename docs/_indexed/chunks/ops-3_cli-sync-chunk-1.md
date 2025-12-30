---
doc_id: ops/3_cli/sync
chunk_id: ops/3_cli/sync#chunk-1
heading_path: ["Sync"]
chunk_type: code
tokens: 513
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Sync

> **Context**: import DocCard from '@site/src/components/DocCard';

Synchronizing folders & git repositories to a Windmill instance is made easy
using the wmill CLI. Syncing operations are behind the `wmill sync` subcommand.

The CLI supports [branch-specific items](./ops-3_cli-branch-specific-items.md) that allow different Git branches to have different versions of resources and variables.

Having a Windmill instance synchronized to folders & git repositories allows for
local development through the [VS Code extension](./meta-1_vscode-extension-index.md).

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

It can be used for bi-directional sync using Windmill EE and [Git sync](./meta-11_git_sync-index.md).
