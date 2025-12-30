---
doc_id: ops/ci-integrations/tekton
chunk_id: ops/ci-integrations/tekton#chunk-5
heading_path: ["tekton", "git-pipeline.yaml"]
chunk_type: mixed
tokens: 202
summary: "apiVersion: tekton."
---
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: dagger-pipeline
spec:
  description: |
    This pipeline clones a Git repository, then runs the Dagger Function.
  params:
  - name: repo-url
    type: string
    description: The Git repository clone URL
  - name: dagger-cloud-token
    type: string
    description: The Dagger Cloud token
  workspaces:
  - name: shared-data
    description: |
      This workspace contains the cloned repository files, so they can be read by the
      next task.
  tasks:
  - name: fetch-source
    taskRef:
      name: git-clone
    workspaces:
    - name: output
      workspace: shared-data
    params:
    - name: url
      value: $(params.repo-url)
  - name: dagger
    runAfter: ["fetch-source"]
    taskRef:
      name: dagger
    workspaces:
    - name: source
      workspace: shared-data
    params:
      - name: dagger-cloud-token
        value: $(params.dagger-cloud-token)
```

This Pipeline references two Tasks:

- The `git-clone` Task, to check out the Git repository for the project into a Tekton Workspace;
- A custom `dagger` Task, to run the Dagger pipeline for the project (defined below).

Define a new Tekton Task as follows, in a file named `dagger-task.yaml`:

```yaml
