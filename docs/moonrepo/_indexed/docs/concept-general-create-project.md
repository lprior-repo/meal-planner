---
id: concept/general/create-project
title: "Create a project"
category: concept
tags: ["concept", "create"]
---

# Create a project

> **Context**: With a workspace, we can now house one or many projects, with a project being an application, library, or tool. In the end, each project will have its

With a workspace, we can now house one or many projects, with a project being an application, library, or tool. In the end, each project will have its own build layer, personal tasks, and custom configuration.

## Declaring a project in the workspace

Although a project may exist in your repository, it's not accessible from moon until it's been mapped in the `projects` setting found in `.moon/workspace.yml`. When mapping a project, we require a unique name for the project, and a project source location (path relative from the workspace root).

Let's say we have a frontend web application called "client", and a backend application called "server", our `projects` setting would look like the following.

.moon/workspace.yml

```yaml
projects:
  client: 'apps/client'
  server: 'apps/server'
```

We can now run `moon project client` and `moon project server` to display information about each project. If these projects were not mapped, or were pointing to an invalid source, the command would throw an error.

> The `projects` setting also supports a list of globs, if you'd prefer to not manually curate the projects list!

## Configuring a project

A project can be configured in 1 of 2 ways:

-   Through the `.moon/tasks.yml` config file, which defines file groups and tasks that are inherited by *all* projects within the workspace. Perfect for standardizing common tasks like linting, typechecking, and code formatting.
-   Through the `moon.yml` config file, found at the root of each project, which defines files groups, tasks, dependencies, and more that are unique to that project.

Both config files are optional, and can be used separately or together, the choice is yours!

Now let's continue with our client and server example above. If we wanted to configure both projects, and define config that's also shared between the 2, we could do something like the following:

### Client

apps/client/moon.yml

```yaml
tasks:
  build:
    command: 'vite dev'
    inputs:
      - 'src/**/*'
    outputs:
      - 'dist'
```

### Server

apps/server/moon.yml

```yaml
tasks:
  build:
    command: 'babel src --out-dir build'
    inputs:
      - 'src/**/*'
    outputs:
      - 'build'
```

### Both (inherited)

.moon/tasks.yml

```yaml
tasks:
  format:
    command: 'prettier --check .'
  lint:
    command: 'eslint --no-error-on-unmatched-pattern .'
  test:
    command: 'jest --passWithNoTests .'
  typecheck:
    command: 'tsc --build'
```

### Adding optional metadata

When utilizing moon in a large monorepo or organization, ownership becomes very important, but also difficult to maintain. To combat this problem, moon supports the `project` field within a project's `moon.yml` config.

This field is *optional* by default, but when defined it provides metadata about the project, specifically around team ownership, which developers maintain the project, where to discuss it, and more!

Furthermore, we also support the `layer` and `language` settings for a more granular breakdown of what exists in the repository.

<project>/moon.yml

```yaml
layer: 'tool'
language: 'typescript'

project:
  name: 'moon'
  description: 'A repo management tool.'
  channel: '#moon'
  owner: 'infra.platform'
  maintainers: ['miles.johnson']
```

## Next steps

- [Setup toolchain](/docs/setup-toolchain)
- [Configure `.moon/workspace.yml` further](/docs/config/workspace)
- [Configure `.moon/tasks.yml` further](/docs/config/tasks)
- [Configure `moon.yml` further](/docs/config/project)
- [Learn about projects](/docs/concepts/project)


## See Also

- [Setup toolchain](/docs/setup-toolchain)
- [Configure `.moon/workspace.yml` further](/docs/config/workspace)
- [Configure `.moon/tasks.yml` further](/docs/config/tasks)
- [Configure `moon.yml` further](/docs/config/project)
- [Learn about projects](/docs/concepts/project)
