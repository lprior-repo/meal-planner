---
doc_id: ops/concepts/toolchain
chunk_id: ops/concepts/toolchain#chunk-2
heading_path: ["Toolchain", "How it works"]
chunk_type: code
tokens: 143
summary: "How it works"
---

## How it works

The toolchain is built around [proto](/proto), our stand-alone multi-language version manager. moon will piggyback of proto's toolchain found at `~/.proto` and reuse any tools available, or download and install them if they're missing.

### Force disabling

The `MOON_TOOLCHAIN_FORCE_GLOBALS` environment variable can be set to `true` to force moon to use tool binaries available on `PATH`, instead of downloading and installing them. This is useful for pre-configured environments, like CI and Docker.

```
MOON_TOOLCHAIN_FORCE_GLOBALS=true
```

Additionally, the name of one or many tools can be passed to this variable to only force globals for those tools, and use the toolchain for the remaining tools.

```
MOON_TOOLCHAIN_FORCE_GLOBALS=node,yarn
```
