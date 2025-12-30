---
doc_id: ops/3_cli/gitsync-settings
chunk_id: ops/3_cli/gitsync-settings#chunk-4
heading_path: ["Git sync settings", "Configuration management"]
chunk_type: prose
tokens: 193
summary: "Configuration management"
---

## Configuration management

The `gitsync-settings` command manages git-sync filter settings and configuration options defined in your `wmill.yaml` file and the workspace backend.

### Settings managed

The command handles these git-sync configuration fields (see [wmill.yaml](./ops-3_cli-sync.md#wmillyaml) for complete details):

- **Path filters**: `includes`, `excludes`, `extraIncludes` - control which files are synced based on path patterns
- **Type filters**: Control which types of resources are synced:
  - `skipScripts`, `skipFlows`, `skipApps`, `skipFolders` - resource type filters
  - `skipVariables`, `skipResources`, `skipResourceTypes`, `skipSecrets` - additional type filters
  - `includeSchedules`, `includeTriggers`, `includeUsers`, `includeGroups` - optional inclusions
  - `includeSettings`, `includeKey` - system resource inclusions

### Configuration modes

The pull command supports different write modes when conflicts exist:

- **Replace mode** (`--replace`): Overwrites top-level wmill.yaml settings
- **Override mode** (`--override`): Creates branch-specific overrides in the `gitBranches` section  
- **Default mode** (`--default`): Writes to top-level defaults
- **Interactive mode** (default): Prompts user to choose between replace/override when conflicts exist
