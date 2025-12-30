---
doc_id: ops/ci-integrations/tekton
chunk_id: ops/ci-integrations/tekton#chunk-2
heading_path: ["tekton", "How it works"]
chunk_type: prose
tokens: 88
summary: "Tekton provides capabilities which allow you to run a Dagger pipeline as a Tekton Task without ne..."
---
Tekton provides capabilities which allow you to run a Dagger pipeline as a Tekton Task without needing any external configuration. This integration uses the standard architecture for Tekton and adds a Dagger Engine sidecar which gives each Tekton PipelineRun its own Dagger Engine.

To trigger a pipeline run, you can use the Tekton CLI (`tkn`), or you can configure events in Tekton to run it automatically as desired.
