---
doc_id: ops/moonrepo/workspace
chunk_id: ops/moonrepo/workspace#chunk-8
heading_path: [".moon/workspace.{pkl,yml}", "`hasher`"]
chunk_type: code
tokens: 158
summary: "`hasher`"
---

## `hasher`

Configures aspects of the smart hashing layer.

### `optimization`

Determines the optimization level to utilize when hashing content before running targets.

-   `accuracy` (default) - When hashing dependency versions, utilize the resolved value in the lockfile. This requires parsing the lockfile, which may reduce performance.
-   `performance` - When hashing dependency versions, utilize the value defined in the manifest. This is typically a version range or requirement.

.moon/workspace.yml

```yaml
hasher:
  optimization: 'performance'
```

### `walkStrategy`

Defines the file system walking strategy to utilize when discovering inputs to hash.

-   `glob` - Walks the file system using glob patterns.
-   `vcs` (default) - Calls out to the [VCS](#vcs) to extract files from its working tree.

.moon/workspace.yml

```yaml
hasher:
  walkStrategy: 'glob'
```
