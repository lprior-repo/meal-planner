---
doc_id: concept/moonrepo/create-project
chunk_id: concept/moonrepo/create-project#chunk-2
heading_path: ["Create a project", "Declaring a project in the workspace"]
chunk_type: prose
tokens: 184
summary: "Declaring a project in the workspace"
---

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
