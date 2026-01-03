---
doc_id: ops/moonrepo/prettier
chunk_id: ops/moonrepo/prettier#chunk-4
heading_path: ["Prettier example", "FAQ"]
chunk_type: prose
tokens: 104
summary: "FAQ"
---

## FAQ

### How to use `--write`?

Unfortunately, this isn't currently possible, as the `prettier` binary itself requires either the `--check` or `--write` options, and since we're configuring `--check` in the task above, that takes precedence. This is also the preferred pattern as checks will run (and fail) in CI.

To work around this limitation, we suggest the following alternatives:

- Configure your editor to run Prettier on save.
- Define another task to write the formatted code, like `format-write`.
