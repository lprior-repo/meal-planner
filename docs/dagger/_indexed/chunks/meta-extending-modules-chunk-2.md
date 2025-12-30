---
doc_id: meta/extending/modules
chunk_id: meta/extending/modules#chunk-2
heading_path: ["modules", "File layout"]
chunk_type: mixed
tokens: 386
summary: "**Go:**

You can split your Dagger module into multiple files, not just `main."
---
### Multiple files

**Go:**

You can split your Dagger module into multiple files, not just `main.go`. To do this, you can just create another file beside `main.go` (for example, `utils.go`):

```
.
│── ...
│── main.go
│── utils.go
└── dagger.json
```

This file should be inside the same package as `main.go`, and as such, can access any private variables/functions/types inside the package.

Additionally, you can also split your Dagger module into Go subpackages (for example, `utils`):

```
.
│── ...
│── main.go
|── utils
│   └── utils.go
└── dagger.json
```

Because this is a separate package, you can only use the variables/functions/types that are exported from this package in `main.go` (you can't access types from `main.go` in the `utils` package).

> **Note:** Only types and functions in the top-level package are part of the public-facing API for the module.

**Python:**

The Dagger module's code in Python can be split into multiple files by making a [package](https://docs.python.org/3/tutorial/modules.html#packages) and ensuring the *main object* is imported in `__init__.py`. All the other object types should already be imported from there.

**TypeScript:**

Due to TypeScript limitations, it is not possible to split your main class module (`index.ts`) into multiple files. However, it is possible to create sub-classes in different files and access them from your main class module.

**PHP:**

Only functions from your main class (`MyModule.php`) can initially be called by Dagger. However, it is possible to create other classes and access them from your main class.

**Java:**

The Dagger module's code in Java can be split into multiple classes, in multiple files. A few constraints apply:
- The main Dagger object must be represented by a class using the same name as the module, in PascalCase.
- The exposed objects must be annotated with `@Object` and the exposed functions with `@Function`.
