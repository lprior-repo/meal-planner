---
doc_id: meta/extending/modules
chunk_id: meta/extending/modules#chunk-1
heading_path: ["modules"]
chunk_type: code
tokens: 503
summary: "> **Context**: A new Dagger module is initialized by calling `dagger init`."
---
# Module Initialization

> **Context**: A new Dagger module is initialized by calling `dagger init`. This creates a new `dagger.json` configuration file in the current working directory, tog...


A new Dagger module is initialized by calling `dagger init`. This creates a new `dagger.json` configuration file in the current working directory, together with sample Dagger Function source code. The configuration file will default the name of the module to the current directory name, unless an alternative is specified with the `--name` argument.

Once a module is initialized, `dagger develop --sdk=...` sets up or updates all the resources needed to develop the module locally. By default, the module source code will be stored in the current working directory, unless an alternative is specified with the `--source` argument.

> **Warning:** Running `dagger develop` regenerates the module's code based on dependencies, the current state of the module, and the current Dagger API version. This can result in unexpected results if there are significant changes between the previous and latest installed Dagger API versions. Always refer to the [changelog](https://github.com/dagger/dagger/blob/main/CHANGELOG.md) for a complete list of changes (including breaking changes) in each Dagger release before running `dagger develop`, or use the `--compat=skip` option to bypass updating the Dagger API version.

The default template from `dagger develop` creates the following structure:

**Go:**
```
.
├── LICENSE
├── dagger.gen.go
├── go.mod
├── go.sum
├── internal
│   ├── dagger
│   ├── querybuilder
│   └── telemetry
└── main.go
└── dagger.json
```

**Python:**
```
.
├── LICENSE
├── pyproject.toml
├── uv.lock
├── sdk
├── src
│   └── my_module
│       ├── __init__.py
│       └── main.py
└── dagger.json
```

**TypeScript:**
```
.
├── LICENSE
├── package.json
├── sdk
├── src
│   └── index.ts
└── tsconfig.json
└── dagger.json
```

**PHP:**
```
.
├── composer.json
├── composer.lock
├── dagger.json
├── LICENSE
├── README.md
├── sdk
├── src
│    └── MyModule.php
└── vendor
```

**Java:**
```
.
├── dagger.json
├── pom.xml
├── src
│   └── main
│       └── java
│           └── io
│               └── dagger
│                   └── modules
│                       └── mymodule
│                           ├── MyModule.java
│                           └── package-info.java
└── target
    └── generated-sources
        ├── dagger-io
        ├── dagger-module
        └── entrypoint
```

> **Note:** While you can use the utilities defined in the automatically-generated code above, you *cannot* edit these files. Even if you edit them locally, any changes will not be persisted when you run the module.
