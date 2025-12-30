---
doc_id: ops/concepts/task-inheritance
chunk_id: ops/concepts/task-inheritance#chunk-2
heading_path: ["Task inheritance", "Scope by project metadata"]
chunk_type: prose
tokens: 418
summary: "Scope by project metadata"
---

## Scope by project metadata

By default tasks defined in [`.moon/tasks.yml`](/docs/config/tasks) will be inherited by *all* projects. This approach works well when a monorepo is comprised of a single programming language, but breaks down quickly in multi-language setups.

To support these complex repositories, we support scoped tasks with [`.moon/tasks/**/*.yml`](/docs/config/tasks), where `*.yml` maps to a project based on a combination of its [language](/docs/config/project#language), [stack](/docs/config/project#stack), [layer](/docs/config/project#layer), or [tags](/docs/config/project#tags). This enables you to easily declare tasks for "JavaScript projects", "Go applications", "Ruby libraries", so on and so forth.

When resolving configuration files, moon will locate and *shallow* merge files in the following order, from widest scope to narrowest scope:

-   `.moon/tasks.yml` - All projects.
-   `.moon/tasks/<language>.yml` - Projects with a matching [`language`](/docs/config/project#language) setting.
-   `.moon/tasks/<stack>.yml` - Projects with a matching [`stack`](/docs/config/project#stack) setting. (v1.23.0)
-   `.moon/tasks/<language>-<stack>.yml` - Projects with a matching [`language`](/docs/config/project#language) and [`stack`](/docs/config/project#stack) settings. (v1.23.0)
-   `.moon/tasks/<stack>-<layer>.yml` - Projects with matching [`stack`](/docs/config/project#stack) and [`layer`](/docs/config/project#layer) settings. (v1.23.0)
-   `.moon/tasks/<language>-<layer>.yml` - Projects with matching [`language`](/docs/config/project#language) and [`layer`](/docs/config/project#layer) settings.
-   `.moon/tasks/<language>-<stack>-<layer>.yml` - Projects with matching [`language`](/docs/config/project#language), [`stack`](/docs/config/project#stack), and [`layer`](/docs/config/project#layer) settings. (v1.23.0)
-   `.moon/tasks/tag-<name>.yml` - Projects with a matching [`tag`](/docs/config/project#tags). (v1.2.0)

As mentioned above, all of these files are shallow merged into a single "global tasks" configuration that is unique per-project. Merging **does not** utilize the [merge strategies](#merge-strategies) below, as those strategies are only utilized when merging global and local tasks.

> Tags are resolved in the order they are defined in `moon.yml` `tags` setting.

### JavaScript runtimes

Unlike most languages that have 1 runtime, JavaScript has 3 (Node.js, Deno, Bun), and we must support repositories that are comprised of any combination of these 3. As such, JavaScript (and TypeScript) based projects have the following additional lookups using [`toolchain`](/docs/config/project#toolchain) to account for this:

-   `.moon/tasks/<toolchain>.yml`
-   `.moon/tasks/<toolchain>-<stack>.yml`
-   `.moon/tasks/<toolchain>-<layer>.yml`
-   `.moon/tasks/<toolchain>-<stack>-<layer>.yml`

For example, `node.yml` would be inherited for Node.js projects, `bun-library.yml` for Bun libraries, and `deno-application.yml` for Deno applications. While `javascript.yml`, `typescript-library.yml`, etc, will be inherited for all toolchains.
