---
doc_id: ops/javascript/node-handbook
chunk_id: ops/javascript/node-handbook#chunk-7
heading_path: ["Node.js handbook", "Dependency management"]
chunk_type: code
tokens: 795
summary: "Dependency management"
---

## Dependency management

Dependencies, also known as node modules, are required by all projects, and are installed through a package manager like npm, pnpm, or yarn. It doesn't matter which package manager you choose, but we highly suggest choosing one that has proper workspaces support. If you're unfamiliar with workspaces, they will:

- Resolve all `package.json`'s in a repository using glob patterns.
- Install dependencies from all `package.json`'s at once, in the required locations.
- Create symlinks of local packages in `node_modules` (to emulate an installed package).
- Deduplicate and hoist `node_modules` when applicable.

All of this functionality enables robust monorepo support, and can be enabled with the following:

**npm** - package.json

```json
{
  "workspaces": ["apps/*", "packages/*"]
}
```

- [Documentation](https://docs.npmjs.com/cli/v8/using-npm/workspaces)

**pnpm** - pnpm-workspace.yaml

```yaml
packages:
  - 'apps/*'
  - 'packages/*'
```

- [Documentation](https://pnpm.io/workspaces)

**Yarn** - package.json and .yarnrc.yml

```json
{
  "workspaces": ["apps/*", "packages/*"]
}
```

```yaml
nodeLinker: 'node-modules'
```

- [Documentation](https://yarnpkg.com/features/workspaces)

**Yarn (classic)** - package.json

```json
{
  "workspaces": ["apps/*", "packages/*"]
}
```

- [Documentation](https://classic.yarnpkg.com/en/docs/workspaces)

caution

Package workspaces are not a requirement for monorepos, but they do solve an array of problems around module resolution, avoiding duplicate packages in bundles, and general interoperability. Proceed with caution for non-workspaces setups!

### Workspace commands

The following common commands can be used for adding, removing, or managing dependencies in a workspace. View the package manager's official documentation for a thorough list of commands.

**npm:**
- Install dependencies: `npm install`
- Add a package at root: `npm install <dependency>`
- Add a package in a project: `npm install <dependency> --workspace <project>`
- Remove a package at root: `npm install <dependency>`
- Remove a package in a project: `npm install <dependency> --workspace <project>`
- Update packages: `npx npm-check-updates --interactive`

**pnpm:**
- Install dependencies: `pnpm install`
- Add a package at root: `pnpm add <dependency>`
- Add a package in a project: `pnpm add <dependency> --filter <project>`
- Remove a package at root: `pnpm remove <dependency>`
- Remove a package in a project: `pnpm remove <dependency> --filter <project>`
- Update packages: `pnpm update -i -r --latest`

**Yarn:**
- Install dependencies: `yarn install`
- Add a package at root: `yarn add <dependency>`
- Add a package in a project: `yarn workspace <project> add <dependency>`
- Remove a package at root: `yarn remove <dependency>`
- Remove a package in a project: `yarn workspace <project> remove <dependency>`
- Update packages: `yarn upgrade-interactive`

**Yarn (classic):**
- Install dependencies: `yarn install`
- Add a package at root: `yarn add <dependency> -w`
- Add a package in a project: `yarn workspace <project> add <dependency>`
- Remove a package at root: `yarn remove <dependency> -w`
- Remove a package in a project: `yarn workspace <project> remove <dependency>`
- Update packages: `yarn upgrade-interactive --latest`

### Developer tools at the root

While not a strict guideline to follow, we've found that installing universal developer tool related dependencies (Babel, ESLint, Jest, TypeScript, etc) in the root `package.json` as `devDependencies` to be a good pattern for consistency, quality, and the health of the repository. It provides the following benefits:

- It ensures all projects are utilizing the same version (and sometimes configuration) of a tool.
- It allows the tool to easily be upgraded. Upgrade once, applied everywhere.
- It avoids conflicting or outdated versions of the same package.

With that being said, this *does not* include development dependencies that are unique to a project!

### Product libraries in a project

Product, application, and or framework specific packages should be installed as production `dependencies` in a project's `package.json`. We've found this pattern to work well for the following reasons:

- Application dependencies are pinned per project, avoiding accidental regressions.
- Applications can upgrade their dependencies and avoid breaking neighbor applications.
