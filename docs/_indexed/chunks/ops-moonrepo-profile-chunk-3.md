---
doc_id: ops/moonrepo/profile
chunk_id: ops/moonrepo/profile#chunk-3
heading_path: ["Task profiling", "Heap snapshots"]
chunk_type: prose
tokens: 222
summary: "Heap snapshots"
---

## Heap snapshots

Heap profiling lets you detect memory leaks, dynamic memory problems, and locate the fragments of code that caused them.

### Record a profile

To record a heap profile, pass `--profile heap` to the [`moon run`](/docs/commands/run) command. When successful, the profile will be written to `.moon/cache/states/<project>/<task>/snapshot.heapprofile`.

```shell
$ moon run --profile heap app:lint
```

### Analyze in Chrome

Heap profiles can be reviewed and analyzed with [Chrome developer tools](https://developer.chrome.com/docs/devtools/) using the following steps.

1. Open Chrome and navigate to `chrome://inspect`.
2. Under "Devices", navigate to "Open dedicated DevTools for Node".
3. The following window will popup. Ensure the "Memory" tab is selected.
4. Click "Load" and select the `snapshot.heapprofile` that was [previously recorded](#record-a-profile-1). If successful, the snapshot will appear in the left column.

> On macOS, press `command` + `shift` + `.` to display hidden files and folders, to locate the `.moon` folder.

5. Select the snapshot in the left column. From here, the snapshot can be analyzed and represented with [Bottom up](#bottom-up), [Top down](#top-down), or [Flame chart](#flame-chart) views.
