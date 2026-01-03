---
doc_id: ops/moonrepo/node-handbook
chunk_id: ops/moonrepo/node-handbook#chunk-6
heading_path: ["Node.js handbook", "Repository structure"]
chunk_type: code
tokens: 585
summary: "Repository structure"
---

## Repository structure

JavaScript monorepo's work best when projects are split into applications and packages, with each project containing its own `package.json` and dependencies. A root `package.json` must also exist that pieces all projects together through workspaces.

For small repositories, the following structure typically works well:

```
/
├── .moon/
├── package.json
├── apps/
│   ├── client/
|   |   ├── ...
│   |   └── package.json
│   └── server/
|       ├── ...
│       └── package.json
└── packages/
    ├── components/
    |   ├── ...
    │   └── package.json
    ├── theme/
    |   ├── ...
    │   └── package.json
    └── utils/
        ├── ...
        └── package.json
```

For large repositories, grouping projects by team or department helps with ownership and organization. With this structure, applications and libraries can be nested at any depth.

```
/
├── .moon/
├── package.json
├── infra/
│   └── ...
├── internal/
│   └── ...
├── payments/
│   └── ...
└── shared/
    └── ...
```

### Applications

Applications are runnable or executable, like an HTTP server, and are pieced together with packages and its own encapsulated code. They represent the whole, while packages are the pieces. Applications can import and depend on packages, but they *must not* import and depend on other applications.

In moon, you can denote a project as an application using the [`layer`](/docs/config/project#layer) setting in [`moon.yml`](/docs/config/project).

moon.yml

```
layer: 'application'
```

### Packages

Packages (also known as a libraries) are self-contained reusable pieces of code, and are the suggested pattern for [code sharing](#code-sharing). Packages can import and depend on other packages, but they *must not* import and depend on applications!

In moon, you can denote a project as a library using the [`layer`](/docs/config/project#layer) setting in [`moon.yml`](/docs/config/project).

moon.yml

```
layer: 'library'
```

### Configuration

Every tool that you'll utilize in a repository will have its own configuration file. This will be a lot of config files, but regardless of what tool it is, where the config file should go will fall into 1 of these categories:

- **Settings are inherited by all projects.** These are known as universal tools, and enforce code consistency and quality across the entire repository. Their config file must exist in the repository root, but may support overrides in each project.
  - Examples: Babel, [ESLint](/docs/guides/examples/eslint), [Prettier](/docs/guides/examples/prettier), [TypeScript](/docs/guides/examples/typescript)
- **Settings are unique per project.** These are developers tools that must be configured separately for each project, as they'll have different concerns. Their config file must exist in each project, but a shared configuration may exist as a base (for example, Jest presets).
  - Examples: [Jest](/docs/guides/examples/jest), [TypeScript](/docs/guides/examples/typescript) (with project references)
- **Settings are one-offs.** These are typically for applications or tools that require their own config, but aren't prevalent throughout the entire repository.
  - Examples: [Astro](/docs/guides/examples/astro), [Next](/docs/guides/examples/next), [Nuxt](/docs/guides/examples/nuxt), [Remix](/docs/guides/examples/remix), Tailwind
