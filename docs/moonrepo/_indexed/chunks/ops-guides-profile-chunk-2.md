---
doc_id: ops/guides/profile
chunk_id: ops/guides/profile#chunk-2
heading_path: ["Task profiling", "CPU snapshots"]
chunk_type: prose
tokens: 266
summary: "CPU snapshots"
---

## CPU snapshots

CPU profiling helps you get a better understanding of which parts of your code require the most CPU time, and how your code is executed and optimized by Node.js. The profiler will measure code execution and activities performed by the engine itself, such as compilation, calls of system libraries, optimization, and garbage collection.

### Record a profile

To record a CPU profile, pass `--profile cpu` to the [`moon run`](/docs/commands/run) command. When successful, the profile will be written to `.moon/cache/states/<project>/<task>/snapshot.cpuprofile`.

```shell
$ moon run --profile cpu app:lint
```

### Analyze in Chrome

CPU profiles can be reviewed and analyzed with [Chrome developer tools](https://developer.chrome.com/docs/devtools/) using the following steps.

1. Open Chrome and navigate to `chrome://inspect`.
2. Under "Devices", navigate to "Open dedicated DevTools for Node".
3. The following window will popup. Ensure the "Profiler" tab is selected.
4. Click "Load" and select the `snapshot.cpuprofile` that was [previously recorded](#record-a-profile). If successful, the snapshot will appear in the left column.

> On macOS, press `command` + `shift` + `.` to display hidden files and folders, to locate the `.moon` folder.

5. Select the snapshot in the left column. From here, the snapshot can be analyzed and represented with [Bottom up](#bottom-up), [Top down](#top-down), or [Flame chart](#flame-chart) views.
