---
doc_id: ref/javascript/typescript-project-refs
chunk_id: ref/javascript/typescript-project-refs#chunk-6
heading_path: ["TypeScript project references", "Running the typechecker"]
chunk_type: prose
tokens: 375
summary: "Running the typechecker"
---

## Running the typechecker

Now that our configuration is place, we can run the typechecker, or attempt to at least! This can be done with the `tsc --build` command, which acts as a [build orchestrator](https://www.typescriptlang.org/docs/handbook/project-references.html#build-mode-for-typescript). We also suggest passing `--verbose` for insights into what projects are compiling, and which are out-of-date.

### On all projects

From the root of the repository, run `tsc --build --verbose` to typecheck *all* projects, as defined in [tsconfig.json](#tsconfigjson). TypeScript will generate a directed acyclic graph (DAG) and compile projects *in order* so that dependencies and references are resolved correctly.

info

Why run TypeScript in the root? Typically you would only want to run against projects, but for situations where you need to verify that all projects still work, running in the root is the best approach. Some such situations are upgrading TypeScript itself, upgrading global `@types` packages, updating shared types, reworking build processes, and more.

### On an individual project

To only typecheck a single project (and its dependencies), there are 2 approaches. The first is to run from the root, and pass a relative path to the project, such as `tsc --build --verbose packages/foo`. The second is to change the working directory to the project, and run from there, such as `cd packages/foo && tsc --build --verbose`.

Both approaches are viable, and either may be used based on your tooling, build system, task runner, so on and so forth. This is the approach moon suggests with its [`typecheck` task](/docs/guides/examples/typescript).

### On affected projects

In CI environments, it's nice to *only run* the typechecker on affected projects — projects that have changed files. While this isn't entirely possible with `tsc`, it is possible with moon! Head over to the [official docs for more information](/docs/run-task#running-based-on-affected-files-only).
