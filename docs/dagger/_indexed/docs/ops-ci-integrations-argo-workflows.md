---
id: ops/ci-integrations/argo-workflows
title: "Argo Workflows"
category: ops
tags: ["ops", "ci", "git", "pipeline", "container"]
---

# Argo Workflows

> **Context**: Dagger provides a programmable container engine that can be invoked from an Argo Workflow to run a Dagger pipeline. This allows you to benefit from Da...


Dagger provides a programmable container engine that can be invoked from an Argo Workflow to run a Dagger pipeline. This allows you to benefit from Dagger's caching, debugging, and visualization features, whilst still keeping all of your existing Argo Workflows infrastructure.

## How it works

Dagger is invoked like any other tool, as one step of an Argo Workflow. Argo Workflows executes the Dagger CLI in a container and connects to the Dagger Engine running in a sidecar container.

## Prerequisites

- A running Kubernetes cluster [configured for use with Dagger](/reference/deployment/kubernetes) and with a pre-configured `kubectl` profile
- Argo Workflows [installed](https://github.com/argoproj/argo-workflows/blob/master/docs/quick-start.md) in the cluster

## Example

The following example runs the tests for a simple [Go application](https://github.com/kpenfound/greetings-api) using a Dagger Function. This project uses the Dagger Go SDK for CI.

Create a file called `workflow.yaml` with the following content:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: dagger-in-argo-
spec:
  entrypoint: dagger-workflow
  volumes:
    - name: dagger-socket
      emptyDir: {}
    - name: dagger-storage
      emptyDir: {}
  templates:
    - name: dagger-workflow
      sidecars:
        - name: dagger-engine
          # replace with the latest available version of Dagger for your platform
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
      inputs:
        artifacts:
          - name: project-source
            path: /work
            git:
              # replace with your repository URL
              repo: https://github.com/kpenfound/greetings-api.git
              revision: "main"
          - name: dagger-cli
            path: /usr/local/bin
            mode: 0755
            http:
              # replace with the latest available version of Dagger for your platform
              url: https://github.com/dagger/dagger/releases/download/v0.19.7/dagger_v0.19.7_linux_amd64.tar.gz
      container:
        image: alpine:latest
        command: ["sh", "-c"]
        # modify to use different function(s) as needed
        args: ["dagger -m github.com/kpenfound/dagger-modules/golang@v0.2.0 call test --source=."]
        workingDir: /work
        env:
        - name: "_EXPERIMENTAL_DAGGER_RUNNER_HOST"
          value: "unix:///run/dagger/engine.sock"
          # assumes the Dagger Cloud token is
          # in a Kubernetes secret named dagger-cloud
        - name: "DAGGER_CLOUD_TOKEN"
          valueFrom:
            secretKeyRef:
              name: dagger-cloud
              key: token
        volumeMounts:
          - mountPath: /run/dagger
            name: dagger-socket
```

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

## Resources

Some resources from the Dagger community that may help are listed below. If you have any questions about additional ways to use Argo Workflows with Dagger, join our [Discord](https://discord.gg/dagger-io) and ask your questions in our [Kubernetes channel](https://discord.com/channels/707636530424053791/1122942037096927353).

- [Video: Argo Workflows with Dagger](https://www.youtube.com/watch?v=FWOJO2PAQIo) by Kyle Penfound: In this demo, Kyle demonstrates how to use Dagger to define pipelines in code and then use argo Workflows to orchestrate the execution of those pipelines.

## About Argo Workflows

[Argo Workflows](https://argoproj.github.io/argo-workflows/) is an open source container-native workflow engine for orchestrating parallel jobs on Kubernetes.

## See Also

- [Documentation Overview](./COMPASS.md)
