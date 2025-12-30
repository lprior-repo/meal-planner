---
doc_id: concept/getting-started/api-sdk
chunk_id: concept/getting-started/api-sdk#chunk-2
heading_path: ["api-sdk", "Dagger Functions"]
chunk_type: code
tokens: 358
summary: "The recommended, and most common way, to interact with the Dagger API is through Dagger Functions."
---
The recommended, and most common way, to interact with the Dagger API is through Dagger Functions. Dagger Functions are just regular code, written in your usual language using a type-safe Dagger SDK.

Dagger Functions are packaged, shared and reused using Dagger modules. A new Dagger module is initialized by calling `dagger init`. This creates a new `dagger.json` configuration file in the current working directory, together with sample Dagger Function source code. The configuration file will default the name of the module to the current directory name, unless an alternative is specified with the `--name` argument.

Once a module is initialized, `dagger develop --sdk=...` sets up or updates all the resources needed to develop the module locally using a Dagger SDK. By default, the module source code will be stored in the current working directory, unless an alternative is specified with the `--source` argument.

Here is an example of initializing a Dagger module:

**Go:**
```bash
dagger init --name=my-module
dagger develop --sdk=go
```

**Python:**
```bash
dagger init --name=my-module
dagger develop --sdk=python
```

**TypeScript:**
```bash
dagger init --name=my-module
dagger develop --sdk=typescript
```

**PHP:**
```bash
dagger init --name=my-module
dagger develop --sdk=php
```

**Java:**
```bash
dagger init --name=my-module
dagger develop --sdk=java
```

> **Warning:** Running `dagger develop` regenerates the module's code based on dependencies, the current state of the module, and the current Dagger API version. This can result in unexpected results if there are significant changes between the previous and latest installed Dagger API versions. Always refer to the [changelog](https://github.com/dagger/dagger/blob/main/CHANGELOG.md) for a complete list of changes (including breaking changes) in each Dagger release before running `dagger develop`, or use the `--compat=skip` option to bypass updating the Dagger API version.
