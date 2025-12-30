---
doc_id: ref/javascript/typescript-project-refs
chunk_id: ref/javascript/typescript-project-refs#chunk-1
heading_path: ["TypeScript project references"]
chunk_type: prose
tokens: 392
summary: "TypeScript project references"
---

# TypeScript project references

> **Context**: How to use TypeScript in a monorepo? What are project references? Why use project references? What is the best way to use project references? These ar

> The ultimate in-depth guide for using TypeScript in a monorepo effectively!

How to use TypeScript in a monorepo? What are project references? Why use project references? What is the best way to use project references? These are just a handful of questions that are *constantly* asked on Twitter, forums, Stack Overflow, and even your workplace.

Based on years of experience managing large-scale frontend repositories, we firmly believe that TypeScript project references are the proper solution for effectively scaling TypeScript in a monorepo. The official [TypeScript documentation on project references](https://www.typescriptlang.org/docs/handbook/project-references.html) answers many of these questions, but it basically boils down to the following:

- Project references *enforce project boundaries, disallowing imports* to arbitrary projects unless they have been referenced explicitly in configuration. This avoids circular references / cycles.
- It enables TypeScript to *process individual units*, instead of the entire repository as a whole. Perfect for reducing CI and local development times.
- It supports *incremental compilation*, so only out-of-date or affected projects are processed. The more TypeScript's cache is warmed, the faster it will be.
- It simulates how types work in the Node.js package ecosystem.

This all sounds amazing but there's got to be some downsides right? Unfortunately, there is:

- Project references require generating declarations to resolve type information correctly. This results in a lot of compilation artifacts littered throughout the repository. There [are ways](#gitignore) [around this](/docs/config/toolchain#routeoutdirtocache).
- This approach is a bit involved and may require some cognitive overhead based on your current level of TypeScript tooling knowledge.

success

If you'd like a real-world repository to reference, our [moonrepo/moon](https://github.com/moonrepo/moon), [moonrepo/dev](https://github.com/moonrepo/dev), and [moonrepo/examples](https://github.com/moonrepo/examples) repositories utilizes this architecture!
