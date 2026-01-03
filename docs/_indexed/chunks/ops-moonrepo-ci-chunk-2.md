---
doc_id: ops/moonrepo/ci
chunk_id: ops/moonrepo/ci#chunk-2
heading_path: ["ci", "How it works"]
chunk_type: prose
tokens: 122
summary: "How it works"
---

## How it works

The `ci` command does all the heavy lifting necessary for effectively running jobs. It achieves this by automatically running the following steps:

- Determines touched files by comparing the current HEAD against a base.
- Determines all [targets](/docs/concepts/target) that need to run based on touched files.
- Additionally runs affected [targets](/docs/concepts/target) dependencies *and* dependents.
- Generates an action and dependency graph.
- Installs the toolchain, Node.js, and npm dependencies.
- Runs all actions within the graph using a thread pool.
- Displays stats about all passing, failed, and invalid actions.
