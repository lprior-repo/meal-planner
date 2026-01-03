---
doc_id: concept/moonrepo/root-project
chunk_id: concept/moonrepo/root-project#chunk-3
heading_path: ["Root-level project", "As a list of globs"]
chunk_type: code
tokens: 132
summary: "As a list of globs"
---

## As a list of globs
projects:
  - '.'
```

> When using globs, the root project's name will be inferred from the repository folder name. Be wary of this as it can change based on what a developer has checked out as.

Once added, create a [`moon.yml`](/docs/config/project) in the root of the repository. From here you can define tasks that can be ran using this new root-level project name, for example, `moon run root:<task>`.

moon.yml

```yaml
tasks:
  versionCheck:
    command: 'yarn version check'
    inputs: []
    options:
      cache: false
```

And that's it, but there are a few caveats to be aware of...
