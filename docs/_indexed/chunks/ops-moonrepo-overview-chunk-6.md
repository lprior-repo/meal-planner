---
doc_id: ops/moonrepo/overview
chunk_id: ops/moonrepo/overview#chunk-6
heading_path: ["Overview", "Or"]
chunk_type: prose
tokens: 140
summary: "Or"
---

## Or
$ MOON_THEME=light moon run app:build
```

### Piped output

When tasks (child processes) are piped, colors and ANSI escape sequences are lost, since the target is not a TTY and we do not implement a PTY. This is a common pattern this is quite annoying. However, many tools and CLIs support a `--color` option to work around this limitation and to always force colors, even when not a TTY.

To mitigate this problem as a whole, and to avoid requiring `--color` for every task, moon supports the [`pipeline.inheritColorsForPipedTasks`](/docs/config/workspace#inheritcolorsforpipedtasks) configuration setting. When enabled, all piped child processes will inherit the color settings of the currently running terminal.
