---
doc_id: ops/how-it-works/languages
chunk_id: ops/how-it-works/languages#chunk-7
heading_path: ["Languages", "Tier structure and responsibilities"]
chunk_type: code
tokens: 578
summary: "Tier structure and responsibilities"
---

## Tier structure and responsibilities

As mentioned in our introduction, language support is divided up into tiers, where each tier introduces more internal integrations and automations, but requires more work to properly implement.

Internally each tier maps to a Rust crate, as demonstrated by the graph at the top of the article.

### Tier 0 = Unsupported

The zero tier represents all languages *not directly* supported by moon. This tier merely exists as a mechanism for running non-supported language binaries via the system toolchain.

moon.yml

```yaml
tasks:
  example:
    command: 'ruby'
    toolchain: 'system'
```

### Tier 1 = Language

The first tier is the language itself. This is the most basic level of support, and is the only tier that is required to be implemented for a language to be considered minimally supported. This tier is in charge of:

-   Declaring metadata about the language. For example, the name of the binary, supported file extensions, available dependency/package/version managers, names of config/manifest/lock files, etc.
-   Helpers for parsing lockfiles and manifest files, and interacting with the language's ecosystem (for example, Node.js module resolution).
-   Mechanisms for detecting the language of a project based on config files and other criteria.
-   Maps to a project's `language` setting.

moon.yml

```yaml
language: 'javascript'
```

### Tier 2 = Platform

The second tier requires the language functionality from tier 1, and eventually the toolchain functionality from tier 3, and provides interoperability with moon's internals. This is the most complex of all tiers, and the tier is in charge of:

-   Determining when, where, and how to install dependencies for a project or the workspace.
-   Loading project aliases and inferring implicit relationships between projects.
-   Syncing a project and ensuring a healthy project state.
-   Hashing efficiently for dependency installs and target runs.
-   Prepending `PATH` with appropriate lookups to execute a task.
-   Running a target's command with proper arguments, environment variables, and flags.
-   Maps to a project's `toolchain.default` or task's `toolchain` setting.
-   Supports a configuration block by name in `.moon/toolchain.yml`.

moon.yml

```yaml
tasks:
  example:
    command: 'webpack'
    toolchain: 'node'
```

.moon/toolchain.yml

```yaml
node: {}
```

### Tier 3 = Toolchain

The third tier is toolchain support via proto. This is the final tier, as the toolchain is unusable unless the platform has been entirely integrated, and as such, the platform depends on this tier. This tier handles:

-   Downloading and installing a language into the toolchain.
-   Installing and deduping project dependencies.
-   Detecting appropriate versions of tools to use.
-   Determining which binary to use and execute targets with.
-   Supports a `version` field in the named configuration block in `.moon/toolchain.yml`.

.moon/toolchain.yml

```yaml
node:
  version: '18.0.0'
```
