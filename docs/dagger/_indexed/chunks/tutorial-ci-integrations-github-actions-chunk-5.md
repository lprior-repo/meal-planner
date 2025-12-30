---
doc_id: tutorial/ci-integrations/github-actions
chunk_id: tutorial/ci-integrations/github-actions#chunk-5
heading_path: ["github-actions", ".github/workflows/dagger.yml"]
chunk_type: prose
tokens: 117
summary: "name: dagger

on:
  push:
    branches: [main]

jobs:
  hello:
    name: hello
    runs-on: ubunt..."
---
name: dagger

on:
  push:
    branches: [main]

jobs:
  hello:
    name: hello
    runs-on: ubuntu-latest
    steps:
      - name: Call Dagger Function
        uses: dagger/dagger-for-github@v8.2.0
        with:
          version: "latest"
          module: github.com/shykes/daggerverse/hello@v0.1.2
          args: hello --greeting="bonjour" --name="monde"
          # assumes the Dagger Cloud token is in
          # a repository secret named DAGGER_CLOUD_TOKEN
          # set via the GitHub UI/CLI
          cloud-token: ${{ secrets.DAGGER_CLOUD_TOKEN }}
```

You can also use Dagger shell syntax instead of Dagger call syntax in your Github Actions workflow. This is useful if you want to use the more advanced chaining and subshell capabilities of Dagger shell.

```yaml
