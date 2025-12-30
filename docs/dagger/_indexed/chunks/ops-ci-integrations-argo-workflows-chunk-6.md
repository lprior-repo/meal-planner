---
doc_id: ops/ci-integrations/argo-workflows
chunk_id: ops/ci-integrations/argo-workflows#chunk-6
heading_path: ["argo-workflows", "Example"]
chunk_type: prose
tokens: 247
summary: "A few important points to note:

- The workflow uses hardwired artifacts to clone the Git reposit..."
---
A few important points to note:

- The workflow uses hardwired artifacts to clone the Git repository and to install the Dagger CLI.
- `unix://run/dagger/engine.sock` is mounted and specified with the `_EXPERIMENTAL_DAGGER_RUNNER_HOST` environment variable.
- The Dagger CLI is downloaded and installed. Confirm the version and architecture are accurate for your cluster and project.
- Setting the `DAGGER_CLOUD_TOKEN` environment variable is only necessary if integrating with Dagger Cloud.

When you're satisfied with the workflow configuration, run it with Argo:

```
argo submit -n argo --watch ./workflow.yaml
```

The `--watch` argument provides an ongoing status feed of the workflow request in Argo. To see the logs from your workflow, note the pod name and in another terminal run `kubectl logs -f POD_NAME`

Once the workflow has successfully completed, run it again with `argo submit -n argo --watch ./workflow.yaml`. Dagger's caching should result in a significantly faster second execution.

> **Note:** Argo Workflows is not a full-featured CI platform in itself, and won't directly respond to changes in repositories or have any automated triggers. To use Argo Workflows as a CI server, it should be [paired with other tools](https://argo-workflows.readthedocs.io/en/latest/use-cases/ci-cd/) like Argo Events.
