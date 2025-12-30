---
doc_id: ops/general/setup-toolchain
chunk_id: ops/general/setup-toolchain#chunk-4
heading_path: ["Setup toolchain", "Automatically installing a tool"]
chunk_type: prose
tokens: 223
summary: "Automatically installing a tool"
---

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
