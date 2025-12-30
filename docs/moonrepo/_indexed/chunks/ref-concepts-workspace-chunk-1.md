---
doc_id: ref/concepts/workspace
chunk_id: ref/concepts/workspace#chunk-1
heading_path: ["Workspace"]
chunk_type: prose
tokens: 81
summary: "Workspace"
---

# Workspace

> **Context**: A workspace is a directory that contains [projects](/docs/concepts/project), manages a [toolchain](/docs/concepts/toolchain), runs [tasks](/docs/conce

A workspace is a directory that contains [projects](/docs/concepts/project), manages a [toolchain](/docs/concepts/toolchain), runs [tasks](/docs/concepts/task), and is coupled with a VCS repository. The root of a workspace is denoted by a `.moon` folder.

By default moon has been designed for monorepos, but can also be used for polyrepos.
