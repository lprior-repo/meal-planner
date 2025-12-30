---
doc_id: ops/docker/scaffold
chunk_id: ops/docker/scaffold#chunk-3
heading_path: ["docker scaffold", "How it works"]
chunk_type: code
tokens: 453
summary: "How it works"
---

## How it works

This command may seem like magic, but it's relative simple thanks to moon's infrastructure and its project graph. When the command is ran, we generate 2 skeleton structures in `.moon/docker` (be sure to gitignore this). One for the workspace, and the other for sources.

**Warning:** Because scaffolding uses the project graph, it requires all projects with a `package.json` to be [configured in moon](/docs/config/workspace#projects). Otherwise, moon will fail to copy all required files and builds may fail.

### Workspace

The workspace skeleton mirrors the project folder structure of the repository 1:1, and only copies files required for dependencies to install. This is typically manifests (`package.json`), lockfiles (`yarn.lock`, etc), other critical configs, and `.moon` itself. This is necessary for package managers to install dependencies (otherwise they will fail), and for dependencies to be layer cached in Docker.

An example of this skeleton using Yarn may look like the following:

```
.moon/docker/workspace/
├── .moon/
├── .yarn/
├── apps/
│   ├── client/
│   │   └── package.json
│   └── server/
│       └── package.json
├── packages/
│   ├── foo/
│   │   └── package.json
│   ├── bar/
│   │   └── package.json
│   └── baz/
│       └── package.json
├── .yarnrc.yml
├── package.json
└── yarn.lock
```

### Sources

The sources skeleton is not a 1:1 mirror of the repository, and instead is the source files of a project (passed as an argument to the command), and all of its dependencies. This allows [`moon run`](/docs/commands/run) and other commands to work within the `Dockerfile`, and avoid having to `COPY . .` the entire repository.

Using our example workspace above, our sources skeleton would look like the following, assuming our `client` project is passed as an argument, and this project depends on the `foo` and `baz` projects.

```
.moon/docker/sources/
├── apps/
│   └── client/
|       ├── src/
|       ├── tests/
|       ├── public/
|       ├── package.json
|       ├── tsconfig.json
│       └── (anything else)
└── packages/
    ├── foo/
    │   ├── lib/
    │   ├── src/
    │   ├── package.json
    │   ├── tsconfig.json
    │   └── (anything else)
    └── baz/
        ├── lib/
        ├── src/
        ├── package.json
        ├── tsconfig.json
        └── (anything else)
```
