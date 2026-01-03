---
doc_id: ops/commands/overview
chunk_id: ops/commands/overview#chunk-4
heading_path: ["Overview", "Colors"]
chunk_type: prose
tokens: 92
summary: "Colors"
---

## Colors

Colored output is a complicated subject, with differing implementations and standards across tooling and operating systems. moon aims to normalize this as much as possible, by doing the following:

-   By default, moon colors are inherited from your terminal settings (`TERM` and `COLORTERM` environment variables).
-   Colors can be force enabled by passing the `--color` option (preferred), or `MOON_COLOR` or `FORCE_COLOR` environment variables.

```
$ moon app:build --color run
