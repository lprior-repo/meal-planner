---
doc_id: tutorial/getting-started/quickstarts-ci
chunk_id: tutorial/getting-started/quickstarts-ci#chunk-5
heading_path: ["quickstarts-ci", "Initialize a Dagger module"]
chunk_type: code
tokens: 99
summary: "Bootstrap a new Dagger module by running `dagger init` in the application's root directory:

**Go..."
---
Bootstrap a new Dagger module by running `dagger init` in the application's root directory:

**Go:**
```bash
dagger init --sdk=go --name=hello-dagger
```

**Python:**
```bash
dagger init --sdk=python --name=hello-dagger
```

**TypeScript:**
```bash
dagger init --sdk=typescript --name=hello-dagger
```

**PHP:**
```bash
dagger init --sdk=php --name=hello-dagger
```

**Java:**
```bash
dagger init --sdk=java --name=hello-dagger
```

This will generate a `dagger.json` module metadata file and a `.dagger` directory containing boilerplate Dagger Functions.

To see the generated Dagger Functions, run:

```bash
dagger functions
```
