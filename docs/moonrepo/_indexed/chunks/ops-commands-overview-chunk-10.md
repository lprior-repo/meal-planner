---
doc_id: ops/commands/overview
chunk_id: ops/commands/overview#chunk-10
heading_path: ["Overview", "Logging"]
chunk_type: prose
tokens: 167
summary: "Logging"
---

## Logging

By default, moon aims to output as little as possible, as we want to preserve the original output of the command's being ran, excluding warnings and errors. This is managed through log levels, which can be defined with the `--log` global option, or the `MOON_LOG` environment variable. The following levels are supported, in priority order.

-   `off` - Turn off logging entirely.
-   `error` - Only show error logs.
-   `warn` - Only show warning logs and above.
-   `info` (default) - Only show info logs and above.
-   `debug` - Only show debug logs and above.
-   `trace` - Show all logs, including network requests and child processes.
-   `verbose` - Like `trace` but also includes span information. v1.35.0

```
$ moon run app:build --log trace
