---
doc_id: ops/moonrepo/workspace
chunk_id: ops/moonrepo/workspace#chunk-3
heading_path: [".moon/workspace.{pkl,yml}", "`projects` (Required)"]
chunk_type: code
tokens: 414
summary: "`projects` (Required)"
---

## `projects` (Required)

Defines the location of all [projects](/docs/concepts/project) within the workspace. Supports either a manual map of projects (default), a list of globs in which to automatically locate projects, *or* both.

> **Caution**: Projects that depend on each other and form a cycle must be avoided! While we do our best to avoid an infinite loop and disconnect nodes from each other, there's no guarantee that tasks will run in the correct order.

### Using a map

When using a map, each project must be *manually* configured and requires a unique [name](/docs/concepts/project#names) as the map key, where this name is used heavily on the command line and within the project graph for uniquely identifying the project amongst all projects. The map value (known as the project source) is a file system path to the project folder, relative from the workspace root, and must be contained within the workspace boundary.

.moon/workspace.yml

```yaml
projects:
  admin: 'apps/admin'
  apiClients: 'packages/api-clients'
  designSystem: 'packages/design-system'
  web: 'apps/web'
```

### Using globs

If manually mapping projects is too tedious or cumbersome, you may provide a list of [globs](/docs/concepts/file-pattern#globs) to automatically locate all project folders, relative from the workspace root.

When using this approach, the project name is derived from the project folder name, and is cleaned to our [supported characters](/docs/concepts/project#names), but can be customized with the [`id`](/docs/config/project#id) setting in [`moon.yml`](/docs/config/project). Furthermore, globbing **does risk the chance of collision**, and when that happens, we log a warning and skip the conflicting project from being configured in the project graph.

.moon/workspace.yml

```yaml
projects:
  - 'apps/*'
  - 'packages/*'
  # Only shared folders with a moon configuration
  - 'shared/*/moon.yml'
```

### Using a map *and* globs

For those situations where you want to use *both* patterns, you can! The list of globs can be defined under a `globs` field, while the map of projects under a `sources` field.

.moon/workspace.yml

```yaml
projects:
  globs:
    - 'apps/*'
    - 'packages/*'
  sources:
    www: 'www'
```
