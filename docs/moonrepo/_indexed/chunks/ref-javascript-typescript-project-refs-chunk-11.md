---
doc_id: ref/javascript/typescript-project-refs
chunk_id: ref/javascript/typescript-project-refs#chunk-11
heading_path: ["TypeScript project references", "FAQ"]
chunk_type: prose
tokens: 838
summary: "FAQ"
---

## FAQ

### I still have questions, where can I ask them?

We'd love to answer your questions and help anyway that we can. Feel free to...

- Join the [moonrepo discord](https://discord.gg/qCh9MEynv2) and post your question in the `#typescript` channel.
- Ping me, [Miles Johnson](https://twitter.com/mileswjohnson), on Twitter. I'll try my best to respond to every tweet.

### Do I have to use project references?

Short answer, no. If you have less than say 10 projects, references may be overkill. If your repository is primarily an application, but then has a handful of shared npm packages, references may also be unnecessary here. In the end, it really depends on how many projects exist in the monorepo, and what your team/company is comfortable with.

However, we do suggest using project references for very large monorepos (think 100s of projects), or repositories with a large number of contributors, or if you merely want to reduce CI typechecking times.

### What about not using project references and only using source files?

A popular alternative to project references is to simply use the source files as-is, by updating the `main` and `types` entry fields within each `package.json` to point to the original TypeScript files. This approach is also known as "internal packages".

package.json

```json
{
  // ...
  "main": "./src/index.tsx",
  "types": "./src/index.tsx"
}
```

While this *works*, there are some downsides to this approach.

- Loading declaration files are much faster than source files.
- You'll lose all the benefits of TypeScript's incremental caching and compilation. TypeScript will consistently load, parse, and evaluate these source files every time. This is especially true for CI environments.
- When using `package.json` workspaces, bundlers and other tools may consider these source files "external" as they're found in `node_modules`. This will require custom configuration to allow it.
- It breaks consistency. Consistency with the npm ecosystem, and consistency with how packaging and TypeScript was designed to work. If all packages are internal, then great, but if you have some packages that are published, you now have 2 distinct patterns for "using packages" instead of 1.

With that being said, theres a 3rd alternative that may be the best of both worlds, using project references *and* source files, [by using `paths` aliases](#importing-source-files-from-local-packages).

All in all, this is a viable approach if you're comfortable with the downsides listed above. Use the pattern that works best for your repository, team, or company!

### How to integrate with ESLint?

We initially included ESLint integration in this guide, but it was very complex and in-depth on its own, so we've opted to push it to another guide. Unfortunately, that guide is not yet available, so please come back soon! We'll announce when it's ready.

### How to handle circular references?

Project references *do **not** support [circular references](https://github.com/microsoft/TypeScript/issues/33685)* (cycles), which is great, as they are a *code smell*! If you find yourself arbitrarily importing code from random sources, or between 2 projects that depend on each other, then this highlights a problem with your architecture. Projects should be encapsulated and isolated from outside sources, unless explicitly allowed through a dependency. Dependencies are "upstream", so having them depend on the current project (the "downstream"), makes little to no sense.

If you're trying to adopt project references and are unfortunately hitting the circular reference problem, don't fret, untangling is possible, although non-trivial depending on the size of your repository. It basically boils down to creating an additional project to move coupled code to.

For example, if project A was importing from project B, and B from A, then the solution would be to create another project, C (typically a shared npm package), and move both pieces of code into C. A and B would then import from C, instead of from each other. We're not aware of any tools that would automate this, or detect cycles, so you'll need to do it manually.
