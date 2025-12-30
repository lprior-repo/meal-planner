---
id: ops/general/setup-toolchain
title: "Setup toolchain"
category: ops
tags: ["setup", "operations"]
---

# Setup toolchain

> **Context**: One of moon's most powerful features is the toolchain, which automatically manages, downloads, and installs Node.js and other languages behind the sce

One of moon's most powerful features is the toolchain, which automatically manages, downloads, and installs Node.js and other languages behind the scenes using proto. It also enables advanced functionality for task running based on the platform (language and environment combination) it runs in.

The toolchain is configured with `.moon/toolchain.yml`.

## How it works

For more information on the toolchain, our tier based support, and how languages integrate into moon, refer to the official "how it works" language guide and the toolchain concept documentation!

> The toolchain is optional but helps to solve an array of issues that developers face in their day-to-day.

## Enabling a platform

By default all tasks run through the system platform and inherit *no* special functionality. If you want to take advantage of this functionality, like dependency hashing, package shorthand execution, and lockfile management, you'll need to enable the platform in `.moon/toolchain.yml`. Otherwise, you can skip to the create a task guide.

Begin by declaring the necessary configuration block, even if an empty object! This configuration can also be injected using the `moon init <tool>` command (doesn't support all languages).

.moon/toolchain.yml

```yaml
node: {}
```

Although we've enabled the platform, language binaries must exist on `PATH` for task execution to function correctly. Continue reading to learn how to automate this flow using tier 3 support.

## Automatically installing a tool

One of the best features of moon is its integrated toolchain and automatic download and installation of programming languages (when supported), for all developers and machines that moon runs on. This feature solves the following pain points:

-   Developers running tasks using different versions of languages.
-   Version drift of languages between machines.
-   Languages being installed through different version managers or install scripts.
-   Language binaries not existing on `PATH`.
-   How shell profiles should be configured.

If you have dealt with any of these pain points before and would like to eliminate them for you and all your developers, you can try enabling moon's tier 3 support for supported tools. This is easily done by defining the `version` field for each platform.

.moon/toolchain.yml

```yaml
node:
  version: '20.0.0'
```

When the `version` field is configured, moon will download and install the tool when a related task is executed for the first time! It will also set the correct `PATH` lookups and environment variables automatically. Amazing right?

## Next steps

- [Create a task](/docs/create-task)
- [Configure `.moon/toolchain.yml` further](/docs/config/toolchain)
- [Learn about the toolchain](/docs/concepts/toolchain)


## See Also

- [Create a task](/docs/create-task)
- [Configure `.moon/toolchain.yml` further](/docs/config/toolchain)
- [Learn about the toolchain](/docs/concepts/toolchain)
