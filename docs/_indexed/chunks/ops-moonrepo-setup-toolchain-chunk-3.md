---
doc_id: ops/moonrepo/setup-toolchain
chunk_id: ops/moonrepo/setup-toolchain#chunk-3
heading_path: ["Setup toolchain", "Enabling a platform"]
chunk_type: prose
tokens: 152
summary: "Enabling a platform"
---

## Enabling a platform

By default all tasks run through the system platform and inherit *no* special functionality. If you want to take advantage of this functionality, like dependency hashing, package shorthand execution, and lockfile management, you'll need to enable the platform in `.moon/toolchain.yml`. Otherwise, you can skip to the create a task guide.

Begin by declaring the necessary configuration block, even if an empty object! This configuration can also be injected using the `moon init <tool>` command (doesn't support all languages).

.moon/toolchain.yml

```yaml
node: {}
```

Although we've enabled the platform, language binaries must exist on `PATH` for task execution to function correctly. Continue reading to learn how to automate this flow using tier 3 support.
