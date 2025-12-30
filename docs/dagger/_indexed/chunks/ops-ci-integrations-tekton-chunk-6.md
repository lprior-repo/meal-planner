---
doc_id: ops/ci-integrations/tekton
chunk_id: ops/ci-integrations/tekton#chunk-6
heading_path: ["tekton", "dagger-task.yaml"]
chunk_type: prose
tokens: 290
summary: "apiVersion: tekton."
---
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: dagger
spec:
  description: Run Dagger Function
  workspaces:
  - name: source
  params:
    - name: dagger-cloud-token
      type: string
      description: Dagger Cloud Token
  volumes:
    - name: dagger-socket
      emptyDir: {}
    - name: dagger-storage
      emptyDir: {}
  sidecars:
    - name: dagger-engine
      # modify to use the desired Dagger version
      image: registry.dagger.io/engine:v0.19.7
      securityContext:
        privileged: true
        capabilities:
          add:
            - ALL
      readinessProbe:
        exec:
          command: ["dagger", "core", "version"]
      volumeMounts:
        - mountPath: /run/dagger
          name: dagger-socket
        - mountPath: /var/lib/dagger
          name: dagger-storage
  steps:
  # modify to use different function(s) as needed
  - name: read
    image: docker:dind
    workingDir: $(workspaces.source.path)
    script: |
      #!/usr/bin/env sh
      apk add curl
      curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=/usr/local/bin sh
      dagger -m github.com/kpenfound/dagger-modules/golang@v0.2.0 call build --source=. --args=.
    volumeMounts:
      - mountPath: /run/dagger
        name: dagger-socket
    env:
      - name: _EXPERIMENTAL_DAGGER_RUNNER_HOST
        value: unix:///run/dagger/engine.sock
      - name: DAGGER_CLOUD_TOKEN
        valueFrom:
          secretKeyRef:
            name: $(params.dagger-cloud-token)
            key: "token"
```

This Tekton Task installs the Dagger CLI and calls a Dagger Function. This Task installs the dependencies needed to execute the Dagger pipeline for the project (which was checked out in the previous Tekton Pipeline) and then calls a Dagger Function to build the project.

In this Tekton Task, the Dagger Engine runs as a sidecar and shares a socket with the Task itself. The Task uses `dind` as its runtime in order to have Docker available.

Define a new Tekton PipelineRun as follows, in a file named `git-pipeline-run.yaml`:

```yaml
