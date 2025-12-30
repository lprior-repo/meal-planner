---
doc_id: ops/ci-integrations/tekton
chunk_id: ops/ci-integrations/tekton#chunk-7
heading_path: ["tekton", "git-pipeline-run.yaml"]
chunk_type: mixed
tokens: 162
summary: "apiVersion: tekton."
---
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: clone-read-run-
spec:
  pipelineRef:
    name: dagger-pipeline
  podTemplate:
    securityContext:
      fsGroup: 65532
  workspaces:
  - name: shared-data
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
  params:
  - name: repo-url
    # replace with your repository URL
    value: https://github.com/kpenfound/greetings-api.git
  - name: dagger-cloud-token
    value: YOUR_DAGGER_CLOUD_TOKEN_HERE
```

This PipelineRun corresponds to the Tekton Pipeline created previously. It executes the Tekton Pipeline with a given set of input parameters: the Git repository URL and an optional Dagger Cloud token.

To apply the configuration and run the Tekton Pipeline, use the following commands:

```
kubectl apply -f dagger-task.yaml
kubectl apply -f git-pipeline-yaml
kubectl create -f git-pipeline-run.yaml
```

To see the logs from the PipelineRun, obtain the PipelineRun name from the output and run `tkn pipelinerun logs clone-read-run-<id> -f`.
