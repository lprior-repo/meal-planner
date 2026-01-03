---
doc_id: ops/moonrepo/vcs-hooks
chunk_id: ops/moonrepo/vcs-hooks#chunk-3
heading_path: ["VCS hooks", "Enabling hooks"]
chunk_type: code
tokens: 302
summary: "Enabling hooks"
---

## Enabling hooks

Hooks are a divisive subject, as some developers love them, and others hate them. Finding a viable solution for everyone can be difficult, so with moon, we opted to support 2 distinct options, but only 1 can be used at a time. Choose the option that works best for your project, team, or company!

> **Caution:** If you have existing VCS hooks, back them up as moon's implementation will overwrite them! To migrate your existing hooks, [configure them as commands to run](#defining-hooks).

### Automatically for everyone

If you'd like hooks to be enforced for every contributor of the repository, then simply enable the [`vcs.syncHooks`](/docs/config/workspace#synchooks) setting in [`.moon/workspace.yml`](/docs/config/workspace). This will automatically generate hook scripts and link them with the local VCS checkout, everytime a [target](/docs/concepts/target) is ran.

.moon/workspace.yml

```yaml
vcs:
  hooks: [...]
  syncHooks: true
```

> **Caution:** Automatically activating hooks on everyone's computer is considered a sensitive action, because it enables the execution of arbitrary code on the computers of the team members. Be careful about the hook commands you define in the [`.moon/workspace.yml`](/docs/config/workspace) file.

### Manually by each developer

If you'd prefer contributors to have a choice in whether or not they want to use hooks, then simply do nothing, and guide them to run the [`moon sync hooks`](/docs/commands/sync/hooks) command. This command will generate hook scripts and link them with the local VCS checkout.

```shell
$ moon sync hooks
```
