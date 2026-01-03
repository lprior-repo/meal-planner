---
doc_id: ops/moonrepo/faq
chunk_id: ops/moonrepo/faq#chunk-3
heading_path: ["FAQ", "Projects & tasks"]
chunk_type: code
tokens: 465
summary: "Projects & tasks"
---

## Projects & tasks

### How to pipe or redirect tasks?

Piping (`|`) or redirecting (`>`) the output of one moon task to another moon task, whether via stdin or through `inputs`, is not possible within our pipeline (task runner) directly.

However, we do support this functionality on the command line, or within a task itself, using the `script` setting.

moon.yml

```yaml
tasks:
  pipe:
    script: 'gen-json | jq ...'
```

Alternativaly, you can wrap this script in something like a Bash file, and execute that instead.

scripts/pipe.sh

```bash
#!/usr/bin/env bash
gen-json | jq ...
```

moon.yml

```yaml
tasks:
  pipe:
    command: 'bash ./scripts/pipe.sh'
```

### How to run multiple commands within a task?

Only `script` based tasks can run multiple commands via `&&` or `;` syntax. This is possible as we execute the entire script within a shell, and not directly with the toolchain.

moon.yml

```yaml
tasks:
  multiple:
    script: 'mkdir test && cd test && do-something'
```

### How to run tasks in a shell?

By default, all tasks run in a shell, based on the task's `shell` option, as demonstrated below:

moon.yml

```yaml
tasks:
  # Runs in a shell
  global:
    command: 'some-command-on-path'

  # Custom shells
  unix:
    command: 'bash -c some-command'
    options:
      shell: false

  windows:
    command: 'pwsh.exe -c some-command'
    options:
      shell: false
```

### Can we run other languages?

Yes! Although our toolchain only supports a few languages at this time, you can still run other languages within tasks by setting their `toolchain` to "system". System tasks are an escape hatch that will use any command available on the current machine.

moon.yml

```yaml
tasks:
  # Ruby
  lint:
    command: 'rubocop'
    toolchain: 'system'

  # PHP
  test:
    command: 'phpunit tests'
    toolchain: 'system'
```

However, because these languages are not supported directly within our toolchain, they will not receive the benefits of the toolchain. Some of which are:

-   Automatic installation of the language. System tasks expect the command to already exist in the environment, which requires the user to manually install them.
-   Consistent language and dependency manager versions across all machines.
-   Built-in cpu and heap profiling (language specific).
-   Automatic dependency installs when the lockfile changes.
-   And many more.
