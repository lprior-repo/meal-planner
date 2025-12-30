---
doc_id: ops/general/setup-workspace
chunk_id: ops/general/setup-workspace#chunk-2
heading_path: ["Setup workspace", "Initializing the repository"]
chunk_type: prose
tokens: 126
summary: "Initializing the repository"
---

## Initializing the repository

Let's scaffold and initialize moon in a repository with the `moon init` command. This should typically be ran at the root, but can be nested within a directory.

```
$ moon init
```

When executed, the following operations will be applied.

-   Creates a `.moon` folder with a `.moon/workspace.yml` configuration file.
-   Appends necessary ignore patterns to the relative `.gitignore`.
-   Infers the version control system from the environment.

> If you're investigating moon, or merely want to prototype, you can use `moon init --minimal` to quickly initialize and create minimal configuration files.
