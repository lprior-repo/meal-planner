---
doc_id: ops/moonrepo/overview
chunk_id: ops/moonrepo/overview#chunk-11
heading_path: ["Overview", "Or"]
chunk_type: prose
tokens: 74
summary: "Or"
---

## Or
$ MOON_LOG=trace moon run app:build
```

### Writing logs to a file

moon can dump the logs from a command to a file using the `--logFile` option, or the `MOON_LOG_FILE` environment variable. The dumped logs will respect the `--log` option and filter the logs piped to the output file.

```
$ moon run app:build --logFile=output.log
