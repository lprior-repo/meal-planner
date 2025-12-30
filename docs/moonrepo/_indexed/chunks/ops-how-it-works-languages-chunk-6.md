---
doc_id: ops/how-it-works/languages
chunk_id: ops/how-it-works/languages#chunk-6
heading_path: ["Languages", "System language and toolchain"]
chunk_type: prose
tokens: 150
summary: "System language and toolchain"
---

## System language and toolchain

When working with moon, you'll most likely have tasks that run built-in system commands that do not belong to any of the supported languages. For example, you may have a task that runs `git` or `docker` commands, or common commands like `rm`, `cp`, `mv`, etc.

For these cases, moon provides a special language/toolchain called `system`, that is always enabled. This toolchain is a catch-all, an escape-hatch, a fallback, and provides the following:

-   Runs a system command or a binary found on `PATH`.
-   Wraps the execution in a shell.

To run system commands, set a task's `toolchain` setting to "system".

moon.yml

```yaml
tasks:
  example:
    command: 'git status'
    toolchain: 'system'
```
