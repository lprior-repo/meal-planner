---
doc_id: ops/ci-integrations/tekton
chunk_id: ops/ci-integrations/tekton#chunk-4
heading_path: ["tekton", "Example"]
chunk_type: mixed
tokens: 81
summary: "The following example builds a simple [Go application](https://github."
---
The following example builds a simple [Go application](https://github.com/kpenfound/greetings-api) using a Dagger Function. This project uses the Dagger Go SDK for CI.

Install the `git-clone` Task from Tekton Hub. This Task adds repository cloning capabilities to the Tekton Pipeline. Use the following command:

```
tkn hub install task git-clone
```

Define a new Tekton Pipeline as follows, in a file named `git-pipeline.yaml`:

```yaml
