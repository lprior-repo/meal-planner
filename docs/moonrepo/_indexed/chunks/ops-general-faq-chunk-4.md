---
doc_id: ops/general/faq
chunk_id: ops/general/faq#chunk-4
heading_path: ["FAQ", "JavaScript ecosystem"]
chunk_type: prose
tokens: 335
summary: "JavaScript ecosystem"
---

## JavaScript ecosystem

### Can we use `package.json` scripts?

We encourage everyone to define tasks in a `moon.yml` file, as it allows for additional metadata like `inputs`, `outputs`, `options`, and more. However, if you'd like to keep using `package.json` scripts, enable the `node.inferTasksFromScripts` setting.

View the official documentation for more information on this approach, including risks, disadvantages, and caveats.

### Can moon version/publish packages?

At this time, no, as we're focusing on the build and test aspect of development. With that being said, this is something we'd like to support first-class in the future, but until then, we suggest the following popular tools:

-   [Yarn releases](https://yarnpkg.com/features/release-workflow) (requires >= v2)
-   [Changesets](https://github.com/changesets/changesets)
-   [Lerna](https://github.com/lerna/lerna)

### Why is npm/pnpm/yarn install running twice when running a task?

moon will automatically install dependencies in a project or in the workspace root (when using package workspaces) when the lockfile or `package.json` has been modified since the last time the install ran. If you are running a task and multiple installs are occurring (and it's causing issues), it can mean 1 of 2 things:

-   If you are using package workspaces, then one of the projects triggering the install is not listed within the `workspaces` field in the root `package.json` (for npm and yarn), or in `pnpm-workspace.yml` (for pnpm).
-   If the install is triggering in a non-JavaScript related project, then this project is incorrectly listed as a package workspace.
-   If you don't want a package included in the workspace, but do want to install its dependencies, then it'll need its own lockfile.
