---
doc_id: ops/features/shell
chunk_id: ops/features/shell#chunk-4
heading_path: ["shell", "Modules"]
chunk_type: mixed
tokens: 274
summary: "Dagger Shell can load modules, inspect their types, and run their functions."
---
Dagger Shell can load modules, inspect their types, and run their functions. This works for both local and remote modules.

For example, try running this command:

```bash
dagger -m github.com/dagger/dagger/docs@v0.18.5
```

This loads the module `github.com/dagger/dagger/docs` at version `v0.18.5`. Wait for the Dagger Shell interactive prompt, then:

```bash
.help
```

We see new commands available, loaded from the module. Let's try running one:

```bash
server | up
```

This builds the docs server defined in the module, and runs it as an ephemeral service [on your machine](http://localhost:8080).

You can load multiple modules in the same session, each scoped to a single pipeline, then combine those pipelines into a bigger pipeline. For example:

```bash
dagger <<.
github.com/dagger/dagger/modules/wolfi | container --packages=nginx | with-directory /var/www $(
  github.com/dagger/dagger/docs | site
)
.
```

This loads `github.com/dagger/dagger/docs` into one pipeline, `github.com/dagger/dagger/modules/wolfi` into another, then combines them.

This works by executing the module's [constructor function](./concept-extending-constructors.md). It works exactly like executing any other function:

- You can inspect it for arguments: `.help MODULE`
- You can pass arguments: `MODULE --foo=bar --baz`
- You can save it to a variable: `foo=$(MODULE)`
- You can use it in a pipeline: `MODULE | foo | bar`
- You can use that pipeline as a sub-pipeline: `foo --bar=$(MODULE | foo | bar)`
