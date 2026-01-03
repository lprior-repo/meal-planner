---
doc_id: ops/moonrepo/touched-files
chunk_id: ops/moonrepo/touched-files#chunk-1
heading_path: ["query touched-files"]
chunk_type: prose
tokens: 171
summary: "query touched-files"
---

# query touched-files

> **Context**: Use the `moon query touched-files` sub-command to query for a list of touched files (added, modified, deleted, etc) using the current VCS state. These

Use the `moon query touched-files` sub-command to query for a list of touched files (added, modified, deleted, etc) using the current VCS state. These are the same queries that [`moon ci`](/docs/commands/ci) and [`moon run`](/docs/commands/run) use under the hood.

Touches files are determined using the following logic:

- If `--defaultBranch` is provided, and the current branch is the [`vcs.defaultBranch`](/docs/config/workspace#defaultbranch), then compare against the previous revision of the default branch (`HEAD~1`). This is what [continuous integration](/docs/guides/ci) uses.
- If `--local` is provided, touched files are based on your local index only (`git status`).
- Otherwise, then compare the defined base (`--base`) against head (`--head`).

```
