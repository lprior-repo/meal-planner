---
doc_id: ops/migrate/from-package-json
chunk_id: ops/migrate/from-package-json#chunk-1
heading_path: ["migrate from-package-json"]
chunk_type: prose
tokens: 261
summary: "migrate from-package-json"
---

# migrate from-package-json

> **Context**: Use the `moon migrate from-package-json <project>` sub-command to migrate a project's `package.json` to our [`moon.yml`](/docs/config/project) format.

Use the `moon migrate from-package-json <project>` sub-command to migrate a project's `package.json` to our [`moon.yml`](/docs/config/project) format. When ran, the following changes are made:

-   Converts `package.json` scripts to `moon.yml` [tasks](/docs/config/project#tasks). Scripts and tasks are not 1:1, so we'll convert as close as possible while retaining functionality.
-   Updates `package.json` by removing all converted scripts. If all scripts were converted, the entire block is removed.
-   Links `package.json` dependencies as `moon.yml` [dependencies](/docs/config/project#dependson) (`dependsOn`). Will map a package's name to their moon project name.

This command is ran *per project*, and for this to operate correctly, requires all [projects to be configured in the workspace](/docs/config/workspace#projects). There's also a handful of [requirements and caveats](#caveats) to be aware of!

```
$ moon --log debug migrate from-package-json app
```

**Caution:** moon does its best to infer the [`local`](/docs/config/project#local) option, given the small amount of information available to use. When this option is incorrectly set, it'll result in CI environments hanging for tasks that are long-running or never-ending (development servers, etc), or won't run builds that should be. Be sure to audit each task after migration!
