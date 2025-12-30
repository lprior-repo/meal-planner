---
doc_id: tutorial/ci-integrations/github-actions
chunk_id: tutorial/ci-integrations/github-actions#chunk-8
heading_path: ["github-actions", ".github/workflows/dagger.yml"]
chunk_type: mixed
tokens: 88
summary: "name: dagger

on:
  push:
    branches: [main]

jobs:
  hello:
    name: hello
    runs-on: depot..."
---
name: dagger

on:
  push:
    branches: [main]

jobs:
  hello:
    name: hello
    runs-on: depot-ubuntu-24.04,dagger=0.19.7
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Call Dagger Function
        run: dagger -m github.com/shykes/daggerverse/hello@v0.3.0 call hello --greeting="bonjour" --name="monde"
```

You can also use Dagger shell syntax instead of Dagger call syntax in your Github Actions workflow. This is useful if you want to use the more advanced chaining and subshell capabilities of Dagger shell.

```yaml
