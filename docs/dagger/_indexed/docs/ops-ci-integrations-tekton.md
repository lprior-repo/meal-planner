---
id: ops/ci-integrations/tekton
title: "Tekton"
category: ops
tags: ["ops", "file", "ci", "pipeline", "function"]
---

# Tekton

> **Context**: Dagger provides a programmable container engine that can be invoked from Tekton to run a Dagger pipeline. This allows you to benefit from Dagger's cac...


Dagger provides a programmable container engine that can be invoked from Tekton to run a Dagger pipeline. This allows you to benefit from Dagger's caching, debugging, and visualization features, whilst still keeping all of your existing Tekton infrastructure.

## How it works

Tekton provides capabilities which allow you to run a Dagger pipeline as a Tekton Task without needing any external configuration. This integration uses the standard architecture for Tekton and adds a Dagger Engine sidecar which gives each Tekton PipelineRun its own Dagger Engine.

To trigger a pipeline run, you can use the Tekton CLI (`tkn`), or you can configure events in Tekton to run it automatically as desired.

## Prerequisites

- A running Kubernetes cluster [configured for use with Dagger](/reference/deployment/kubernetes) and with a pre-configured `kubectl` profile
- Tekton and the Tekton CLI [installed](https://tekton.dev/docs/getting-started/) in the cluster

## Example

The following example builds a simple [Go application](https://github.com/kpenfound/greetings-api) using a Dagger Function. This project uses the Dagger Go SDK for CI.

Install the `git-clone` Task from Tekton Hub. This Task adds repository cloning capabilities to the Tekton Pipeline. Use the following command:

```
tkn hub install task git-clone
```

Define a new Tekton Pipeline as follows, in a file named `git-pipeline.yaml`:

```yaml
## git-pipeline.yaml
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
## dagger-task.yaml
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
## git-pipeline-run.yaml
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

## Resources

If you have any questions about additional ways to use Tekton with Dagger, join our [Discord](https://discord.gg/dagger-io) and ask your questions in our [Kubernetes channel](https://discord.com/channels/707636530424053791/1122942037096927353).

## About Tekton

[Tekton](https://tekton.dev/) is a Kubernetes-based framework for creating, managing and running CI/CD pipelines.

## See Also

- [Documentation Overview](./COMPASS.md)
