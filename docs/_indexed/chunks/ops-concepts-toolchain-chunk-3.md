---
doc_id: ops/concepts/toolchain
chunk_id: ops/concepts/toolchain#chunk-3
heading_path: ["Toolchain", "Configuration"]
chunk_type: prose
tokens: 408
summary: "Configuration"
---

## Configuration

The tools that are managed by the toolchain are configured through the [`.moon/toolchain.yml`](/docs/config/toolchain) file, but can be overridden in each project with [`moon.yml`](/docs/config/project#toolchain).

### Version specification

As mentioned above, tools within the toolchain are managed *by version* for consistency across machines. These versions are configured on a per-tool basis in [`.moon/toolchain.yml`](/docs/config/toolchain). So what kinds of versions are allowed?

-   **Full versions** - A full version is a semantic version that is fully specified, such as `1.2.3` or `2.0.0-rc.1`. This is the most common way to specify a version, and is preferred to avoid subtle deviations.
-   **Partial versions** - A partial version is a version that is either missing a patch number, minor number, or both, such as `1.2` or `1`. These can also be represented with requirement syntax, such as `^1.2` or `~1`. If using partials, we suggest having a major and minor number to reduce the deviation of versions across machines.
-   **Aliases** - An alias is a human-readable word that maps to a specific version. For example, `latest` or `stable` maps to the latest version of a tool, or `canary` which maps to applicable canary release, or even a completely custom alias like `berry`. Aliases are language specific, are not managed by moon, and are not suggested for use since they can change at any time (or even daily!).

This sounds great, but how exactly does this work? For full versions and aliases, it's straight forward, as the resolved version is used as-is (assuming it's a legitimate version), and can be found at `~/.proto/tools/<tool>/<version>`.

For partial versions, we first check locally installed versions for a match, by scanning `~/.proto/tools/<tool>`. For example, if the requested version is `1.2` and we have `1.2.10` installed locally, we'll use that version instead of downloading the latest `1.2.*` version. Otherwise, we'll download the latest version that matches the partial version, and install it locally.
