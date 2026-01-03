---
id: ops/moonrepo/install
title: "Install moon"
category: ops
tags: ["advanced", "install", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Install moon</title>
  <description>The following guide can be used to install moon and integrate it into an existing repository (with or without incremental adoption), or to a fresh repository.</description>
  <created_at>2026-01-02T19:55:27.224686</created_at>
  <updated_at>2026-01-02T19:55:27.224686</updated_at>
  <language>en</language>
  <sections count="10">
    <section name="Installing" level="2"/>
    <section name="proto" level="3"/>
    <section name="Linux, macOS, WSL" level="3"/>
    <section name="Windows" level="3"/>
    <section name="npm" level="3"/>
    <section name="Other" level="3"/>
    <section name="Upgrading" level="2"/>
    <section name="Canary releases" level="2"/>
    <section name="Nightly releases" level="2"/>
    <section name="Next steps" level="2"/>
  </sections>
  <features>
    <feature>canary_releases</feature>
    <feature>installing</feature>
    <feature>linux_macos_wsl</feature>
    <feature>next_steps</feature>
    <feature>nightly_releases</feature>
    <feature>other</feature>
    <feature>proto</feature>
    <feature>upgrading</feature>
    <feature>windows</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/proto</entity>
    <entity relationship="uses">/docs/setup-workspace</entity>
  </related_entities>
  <examples count="12">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>advanced,install,operations,moonrepo</tags>
</doc_metadata>
-->

# Install moon

> **Context**: The following guide can be used to install moon and integrate it into an existing repository (with or without incremental adoption), or to a fresh rep

The following guide can be used to install moon and integrate it into an existing repository (with or without incremental adoption), or to a fresh repository.

## Installing

The entirety of moon is packaged and shipped as a single binary. It works on all major operating systems, and does not require any external dependencies. For convenience, we provide the following scripts to download and install moon.

### proto

moon can be installed and managed in [proto's toolchain](/proto). This will install moon to `~/.proto/tools/moon` and make the binary available at `~/.proto/bin`.

```
proto install moon
```

Furthermore, the version of moon can be pinned on a per-project basis using the `.prototools` config file.

.prototools

```
moon = "1.31.0"
```

> We suggest using proto to manage moon (and other tools), as it allows for multiple versions to be installed and used. The other installation options only allow for a single version (typically the last installed).

### Linux, macOS, WSL

In a terminal that supports Bash, run:

```
bash <(curl -fsSL https://moonrepo.dev/install/moon.sh)
```

This will install moon to `~/.moon/bin`. You'll then need to set `PATH` manually in your shell profile.

```
export PATH="$HOME/.moon/bin:$PATH"
```

### Windows

In Powershell or Windows Terminal, run:

```
irm https://moonrepo.dev/install/moon.ps1 | iex
```

This will install moon to `~\.moon\bin` and prepend to the `PATH` environment variable for the current session. To persist across sessions, update `PATH` manually in your system environment variables.

> If you are using Git Bash on Windows, you can run the Unix commands above.

### npm

moon is also packaged and shipped as a single binary through the [`@moonrepo/cli`](https://www.npmjs.com/package/@moonrepo/cli) npm package. Begin by installing this package at the root of the repository.

**Yarn:**
```
yarn add --dev @moonrepo/cli
```

**Yarn (classic):**
```
yarn add --dev @moonrepo/cli
## If using workspaces
yarn add --dev -W @moonrepo/cli
```

**npm:**
```
npm install --save-dev @moonrepo/cli
```

**pnpm:**
```
pnpm add --save-dev @moonrepo/cli
## If using workspaces
pnpm add --save-dev -w @moonrepo/cli
```

**Bun:**
```
bun install --dev @moonrepo/cli
```

If you are installing with Bun, you'll need to add `@moonrepo/cli` as a [trusted dependency](https://bun.sh/docs/install/lifecycle#trusteddependencies).

> When a global `moon` binary is executed, and the `@moonrepo/cli` binary exists within the repository, the npm package version will be executed instead. We do this because the npm package denotes the exact version the repository is pinned it.

### Other

moon can also be downloaded and installed manually, by downloading an asset from [https://github.com/moonrepo/moon/releases](https://github.com/moonrepo/moon/releases). Be sure to rename the file after downloading, and apply the executable bit (`chmod +x`) on macOS and Linux.

## Upgrading

If using proto, moon can be upgraded using the following command:

```
proto install moon --pin
```

Otherwise, moon can be upgraded with the `moon upgrade` command. However, this will only upgrade moon if it was installed in `~/.moon/bin`.

```
moon upgrade
```

Otherwise, you can re-run the installers above and it will download, install, and overwrite with the latest version.

## Canary releases

moon supports canary releases, which are built and published for every commit to our development branches. These releases will include features and functionality that have not yet landed on master. When using a canary release, you'll need to download and execute the binaries manually:

-   Using our npm package [`@moonrepo/cli`](https://www.npmjs.com/package/@moonrepo/cli?activeTab=versions) under the `canary` tag. Releases are versioned by date.
-   From a [GitHub prerelease](https://github.com/moonrepo/moon/releases/tag/canary) using the `canary` tag. This tag always represents the latest development release.

## Nightly releases

moon supports nightly releases, which are built and published once a day from the latest commit on master. When using a nightly release, you'll need to download and execute the binaries manually.

-   Using our npm package [`@moonrepo/cli`](https://www.npmjs.com/package/@moonrepo/cli?activeTab=versions) under the `nightly` tag. Releases are versioned by date.
-   From a [GitHub prerelease](https://github.com/moonrepo/moon/releases/tag/nightly) using the `nightly` tag. This tag always represents the latest stable release.

## Next steps

- [Setup workspace](/docs/setup-workspace)


## See Also

- [proto's toolchain](/proto)
- [Setup workspace](/docs/setup-workspace)
