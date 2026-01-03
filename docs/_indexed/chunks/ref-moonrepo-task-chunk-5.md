---
doc_id: ref/moonrepo/task
chunk_id: ref/moonrepo/task#chunk-5
heading_path: ["Tasks", "Configuration"]
chunk_type: prose
tokens: 297
summary: "Configuration"
---

## Configuration

Tasks can be configured per project through [`moon.yml`](/docs/config/project), or for many projects through [`.moon/tasks.yml`](/docs/config/tasks).

### Commands vs Scripts

A task is either a command or script, but not both. So what's the difference exactly? In the context of a moon task, a command is a single binary execution with optional arguments, configured with the [`command`](/docs/config/project#command) and [`args`](/docs/config/project#args) settings (which both support a string or array). While a script is one or many binary executions, with support for pipes and redirects, and configured with the [`script`](/docs/config/project#script) setting (which is only a string).

A command also supports merging during task inheritance, while a script does not and will always replace values. Refer to the table below for more differences between the 2.

| Feature | Command | Script |
|---------|---------|--------|
| Configured as | string, array | string |
| Inheritance merging | via `mergeArgs` option | always replaces |
| Additional args | via `args` setting | No |
| Passthrough args (from CLI) | Yes | No |
| Multiple commands (with `&&` or `;`) | No | Yes |
| Pipes, redirects, etc | No | Yes |
| Always ran in a shell | No | Yes |
| Custom platform/toolchain | Yes | Yes |
| [Token](/docs/concepts/token) functions and variables | Yes | Yes |

### Inheritance

View the official documentation on [task inheritance](/docs/concepts/task-inheritance).
