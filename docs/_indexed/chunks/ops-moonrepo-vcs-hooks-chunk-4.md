---
doc_id: ops/moonrepo/vcs-hooks
chunk_id: ops/moonrepo/vcs-hooks#chunk-4
heading_path: ["VCS hooks", "Disabling hooks"]
chunk_type: code
tokens: 89
summary: "Disabling hooks"
---

## Disabling hooks

If you choose to stop using hooks, you'll need to cleanup the previously generated hook scripts, and reset the VCS checkout. To start, disable the `vcs.syncHooks` setting.

.moon/workspace.yml

```yaml
vcs:
  syncHooks: false
```

And then run the following command, which will delete files from your local filesystem. Every developer that is using hooks will need to run this command.

```shell
$ moon sync hooks --clean
```
