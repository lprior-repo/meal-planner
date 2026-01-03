---
doc_id: ops/moonrepo/codegen
chunk_id: ops/moonrepo/codegen#chunk-4
heading_path: ["Code generation", "Sharing templates"]
chunk_type: code
tokens: 293
summary: "Sharing templates"
---

## Sharing templates

Although moon is designed for a monorepo, you may be using multiple repositories and would like to use the same templates across all of them. So how can we share templates across repositories? Why not try...

- Git submodules
- Git repositories (using `git://` protocol)
- File archives
- Node.js modules
- npm packages (using `npm://` protocol)
- Another packaging system

Regardless of the choice, simply configure [`generator.templates`](/docs/config/workspace#templates) to point to these locations:

.moon/workspace.yml

```yaml
generator:
  templates:
    - './templates'
    - 'file://./templates'
    # Git
    - './path/to/submodule'
    - 'git://github.com/org/repo#branch'
    # npm
    - './node_modules/@company/shared-templates'
    - 'npm://@company/shared-templates#1.2.3'
```

### Git and npm layout structure

If you plan to share templates using Git repositories (`git://`) or npm packages (`npm://`), then the layout of those projects must follow these guidelines:

- A project must support multiple templates
- A template is denoted by a folder in the root of the project
- Each template must have a [`template.yml`](/docs/config/template) file
- Template names are derived from the folder name, or the `id` field in [`template.yml`](/docs/config/template)

An example of this layout structure may look something like the following:

```
<root>
├── template-one/
│   └── template.yml
├── template-two/
│   └── template.yml
├── template-three/
│   └── template.yml
└── package.json, etc
```

These templates can then be referenced by name, such as [`moon generate template-one`](/docs/commands/generate).

**Tags:**

- [codegen](/docs/tags/codegen)
- [generator](/docs/tags/generator)
- [scaffold](/docs/tags/scaffold)
- [template](/docs/tags/template)
