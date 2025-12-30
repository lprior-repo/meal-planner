# OpenShift Deployment

Deploy Dagger on an OpenShift cluster for Continuous Integration (CI).

## How it Works

The architecture consists of:
- A Dagger Engine DaemonSet which executes pipelines
- Tainted nodes for dedicated workloads

The Dagger DaemonSet configuration is designed to:
- Best utilize local NVMe drives of the worker nodes
- Reduce network latency and bandwidth requirements
- Simplify routing of Dagger SDK and CLI requests

## Prerequisites

- A functional OpenShift cluster
- [Helm](https://helm.sh/) package manager
- [OpenShift CLI](https://docs.openshift.com/container-platform/4.13/cli_reference/openshift_cli/getting-started-cli.html) (`oc`)

## Example

Create a `values.yaml` file:

```yaml
nameOverride: ""
fullnameOverride: ""

engine:
  image:
    repository: registry.dagger.io/engine
    tag: latest
  tolerations:
    - effect: NoSchedule
      key: dagger-node
      operator: Exists
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: dagger-node
            operator: Exists
```

Taint the nodes that should host a Dagger Engine:

```bash
oc adm taint nodes NODE-NAME dagger-node=true:NoSchedule
```

Install Dagger using Helm:

```bash
helm upgrade --create-namespace --install --namespace dagger dagger oci://registry.dagger.io/dagger-helm -f values.yaml
```

Grant the necessary permissions:

```bash
oc adm policy add-scc-to-user privileged -z default -n dagger
```

> **Warning**: Without this step, pod creation will fail due to insufficient permissions.

## About OpenShift

[OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift) is a Kubernetes-based platform to build and deploy applications at scale.
