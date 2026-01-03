---
id: ops/moonrepo/setup-workspace
title: "Setup workspace"
category: ops
tags: ["operations", "setup", "moonrepo"]
---

# Setup workspace

> **Context**: Once moon has been installed, we must setup the workspace, which is denoted by the `.moon` folder — this is known as the workspace root. The workspace

Once moon has been installed, we must setup the workspace, which is denoted by the `.moon` folder — this is known as the workspace root. The workspace is in charge of:

-   Integrating with a version control system.
-   Defining configuration that applies to its entire tree.
-   Housing projects to build a project graph.
-   Running tasks with the action graph.

## Initializing the repository

Let's scaffold and initialize moon in a repository with the `moon init` command. This should typically be ran at the root, but can be nested within a directory.

```
$ moon init
```

When executed, the following operations will be applied.

-   Creates a `.moon` folder with a `.moon/workspace.yml` configuration file.
-   Appends necessary ignore patterns to the relative `.gitignore`.
-   Infers the version control system from the environment.

> If you're investigating moon, or merely want to prototype, you can use `moon init --minimal` to quickly initialize and create minimal configuration files.

## Migrate from an existing build system

Looking to migrate from Nx or Turborepo to moon? Use our `moon ext migrate-nx` or `moon ext migrate-turborepo` commands for a (somewhat) seamless migration!

These extensions will convert your existing configuration files to moon's format as best as possible, but is not a requirement.

## Configuring a version control system

moon requires a version control system (VCS) to be present for functionality like file diffing, hashing, and revision comparison. The VCS and its default branch can be configured through the `vcs` setting.

.moon/workspace.yml

```yaml
vcs:
  manager: 'git'
  defaultBranch: 'master'
```

> moon defaults to `git` and the settings above, so feel free to skip this.

## Next steps

- [Create a project](/docs/create-project)
- [Configure `.moon/workspace.yml` further](/docs/config/workspace)
- [Learn about the workspace](/docs/concepts/workspace)


## See Also

- [Create a project](/docs/create-project)
- [Configure `.moon/workspace.yml` further](/docs/config/workspace)
- [Learn about the workspace](/docs/concepts/workspace)
