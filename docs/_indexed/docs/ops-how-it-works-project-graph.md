---
id: ops/how-it-works/project-graph
title: "Project graph"
category: ops
tags: ["operations", "how-it-works", "project"]
---

# Project graph

> **Context**: The project graph is a representation of all configured projects in the workspace and their relationships between each other, and is represented inter

The project graph is a representation of all configured projects in the workspace and their relationships between each other, and is represented internally as a directed acyclic graph (DAG). Below is a visual representation of a project graph, composed of multiple applications and libraries, where both project types depend on libraries.

> The `moon project-graph` command can be used to view the structure of your workspace.

## Relationships

A relationship is between a dependent (downstream project) and a dependency/requirement (upstream project). Relationships are derived from source code and configuration files within the repository, and fall into 1 of 2 categories:

### Explicit

These are dependencies that are explicitly defined in a project's `moon.yml` config file, using the `dependsOn` setting.

moon.yml

```yaml
dependsOn:
  - 'components'
  - id: 'utils'
    scope: 'peer'
```

### Implicit

These are dependencies that are implicitly discovered by moon when scanning the repository. How an implicit dependency is discovered is based on a language's platform integration, and how that language's ecosystem functions.

package.json

```json
{
  "dependencies": {
    "@company/components": "workspace:*"
  },
  "peerDependencies": {
    "@company/utils": "workspace:*"
  }
}
```

> If a language is not officially supported by moon, then implicit dependencies will *not* be resolved. For unsupported languages, you must explicitly configure dependencies.

### Scopes

Every relationship is categorized into a scope that describes the type of relationship between the parent and child. Scopes are currently used for project syncing and deep Docker integration.

-   **Production** - Dependency is required in production, *will not be* pruned in production environments, and will sync as a production dependency.
-   **Development** - Dependency is required in development and production, *will be* pruned from production environments, and will sync as a development-only dependency.
-   **Build** - Dependency is required for building only, and will sync as a build dependency.
-   **Peer** - Dependency is a peer requirement, with language specific semantics. Will sync as a peer dependency when applicable.

## What is the graph used for?

Great question, the project graph is used throughout the codebase to accomplish a variety of functions, but mainly:

-   Is fed into the task graph to determine relationships of tasks between other tasks, and across projects.
-   Powers our Docker layer caching and scaffolding implementations.
-   Utilized for project syncing to ensure a healthy repository state.
-   Determines affected projects in continuous integration workflows.


## See Also

- [Documentation Index](./COMPASS.md)
