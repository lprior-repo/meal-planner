---
doc_id: ops/moonrepo/debug-task
chunk_id: ops/moonrepo/debug-task#chunk-2
heading_path: ["Debugging a task", "Verify configuration"]
chunk_type: prose
tokens: 461
summary: "Verify configuration"
---

## Verify configuration

Before we dive into the internals of moon, we should first verify that the task is actually configured correctly. Our configuration layer is very strict, but it can't catch everything, so jump to the [`moon.yml`](/docs/config/project#tasks) documentation for more information.

To start, moon will create a snapshot of the project and its tasks, with all [tokens](/docs/concepts/token) resolved, and paths expanded. This snapshot is located at `.moon/cache/states/<project>/snapshot.json`. With the snapshot open, inspect the root `tasks` object for any inconsistencies or inaccuracies.

Some issues to look out for:

- Have `command` and `args` been parsed correctly?
- Have [tokens](/docs/concepts/token) resolved correctly? If not, verify syntax or try another token type.
- Have `inputFiles`, `inputGlobs`, and `inputVars` expanded correctly from [`inputs`](/docs/config/project#inputs)?
- Have `outputFiles` and `outputGlobs` expanded correctly from [`outputs`](/docs/config/project#outputs)?
- Is the `toolchain` (formerly `platform`) correct for the command? If incorrect, explicitly set the [`toolchain`](/docs/config/project#toolchain).
- Are `options` and `flags` correct?

> **Info:** Resolved information can also be inspected with the [`moon task <target> --json`](/docs/commands/task) command.

### Verify inherited configuration

If the configuration from the previous step looks correct, you can skip this step, otherwise let's verify that the inherited configuration is also correct. In the `snapshot.json` file, inspect the root `inherited` object, which is structured as follows:

- `order` - The order in which configuration files from `.moon` are loaded, from lowest to highest priority, and the order files are merged. The `*` entry is `.moon/tasks.yml`, while other entries map to `.moon/tasks/**/*.yml`.
- `layers` - A mapping of configuration files that were loaded, derived from the `order`. Each layer represents a partial object (not expanded or resolved). Only files that exist will be mapped here.
- `config` - A partial configuration object representing the state of all merged layers. This is what is merged with the project's `moon.yml` file.

Some issues to look out for:

- Is the order correct? If not, verify the project's [`language`](/docs/config/project#language) and the task's [`toolchain`](/docs/config/project#toolchain).
- Does `config` correctly represent the merged state of all `layers`? Do note that tasks are shallow merged (by name), *not* deep merged.
- Have the root `tasks` properly inherited [`implicitDeps`](/docs/config/tasks#implicitdeps), [`implicitInputs`](/docs/config/tasks#implicitinputs), and `fileGroups`?
