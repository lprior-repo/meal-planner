---
doc_id: ops/general/faq
chunk_id: ops/general/faq#chunk-2
heading_path: ["FAQ", "General"]
chunk_type: prose
tokens: 816
summary: "General"
---

## General

### Where did the name "moon" come from?

The first incarnation of the name was a misspelling of monorepo (= moonrepo). This is where the domain moonrepo.dev came from, and our official company, moonrepo, Inc.

However, moonrepo is quite a long name with many syllables, and as someone who prefers short 1 syllable words, moon was perfect. The word moon also has great symmetry, as you can see in our logo!

But that's not all... moon is also an acronym. It originally stood for **m**onorepo, **o**rganization, **o**rchestration, and **n**otification tool. But since moon can also be used for polyrepos, we replaced monorepo with **m**anagement (as shown on the homepage). This is a great acronym, as it embraces what moon is trying to solve:

-   **M**anage repos, projects, and tasks with ease.
-   **O**rganize projects and the repo to scale.
-   **O**rchestrate tasks as efficiently as possible.
-   **N**otify developers and systems about important events.

### Will moon support other languages?

Yes! Although we're focusing right now on the web ecosystem (Node.js, Rust, Go, PHP, Python, etc), we've designed moon to be language agnostic and easily pluggable in the future. View our supported languages for more information.

### Will moon support continuous deployment?

Yes! We plan to integrate CD with the current build and CI system, but we are focusing on the latter 2 for the time being. Why not start using moon today so that you can easily adopt CD when it's ready?

### What should be considered the "source of truth"?

If you're a frontend developer, you'll assume that a `package.json` is the source of truth for a project, as it defines scripts, dependencies, and repo-local relations. While true, this breaks down with additional tooling, like TypeScript project references, as now you must maintain `tsconfig.json` as well as `package.json`. The risk of these falling out of sync is high.

This problem is further exacerbated by more tooling, or additional programming languages. What if your frontend project is dependent on a backend project? This isn't easily modeled in `package.json`. What if the backend project needs to be built and ran before running the frontend project? Again, while not impossible, it's quite cumbersome to model in `package.json` scripts. So on and so forth.

moon aims to solve this with a different approach, by standardizing all projects in the workspace on `moon.yml`. With this, the `moon.yml` is the source of truth for each project, and provides us with the following:

-   The configuration is language agnostic. All projects are configured in a similar manner.
-   Tasks can reference other tasks easily. For example, npm scripts referencing rake tasks, and vice verse, is a non-ideal experience.
-   Dependencies defined with `dependsOn` use moon project names, and not language specific semantics. This field also easily populates the dependency/project graphs.
-   For JavaScript projects:
    -   `package.json` dependencies (via `dependsOn`) are kept in sync when `node.syncProjectWorkspaceDependencies` is enabled.
    -   `tsconfig.json` project references (via `dependsOn`) are kept in sync when `typescript.syncProjectReferences` is enabled.

By using moon as the source of truth, we can ensure a healthy repository, by accurately keeping everything in sync, and modifying project/language configuration to operate effectively.

> With all that being said, moon supports implicit dependency scanning, if you'd prefer to continue utilizing language specific functionality, instead of migrating entirely to moon.

### How to stop moon formatting JSON and YAML files?

To ensure a healthy repository state, moon constantly modifies JSON and YAML files, specifically `package.json` and `tsconfig.json`. This may result in a different formatting style in regards to indentation. While there is no way to stop or turn off this functionality, we respect [EditorConfig](https://editorconfig.org/) during this process.

Create a root `.editorconfig` file to enforce a consistent syntax.

.editorconfig

```
[*.{json,yaml,yml}]
indent_style = space
indent_size = 4
```
