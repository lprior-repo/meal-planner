---
id: ops/reference/deployment-kubernetes
title: "Kubernetes Deployment"
category: ops
tags: ["kubernetes", "ops", "ci", "deployment", "container"]
---

# Kubernetes Deployment

> **Context**: Deploy Dagger on a Kubernetes cluster for self-hosted CI infrastructure.


Deploy Dagger on a Kubernetes cluster for self-hosted CI infrastructure.

Running Dagger in Kubernetes is generally a good choice for:
- Teams with demanding CI/CD performance needs or regulated environments
- Individuals or teams that want to self-host their CI infrastructure
- Better integration with internal existing infrastructure
- Mitigate CI vendor lock-in

## Architecture Patterns

### Persistent Nodes

Components:
- **Kubernetes cluster**: Support nodes and runner nodes
- **Certificates manager**: Required by Runner controller
- **Runner controller**: Manages CI runners in response to job requests
- **Dagger Engine**: Deployed as a DaemonSet on each runner node

### Ephemeral, Auto-scaled Nodes

Add a node auto-scaler to automatically adjust the size of node groups based on workload.

Trade-off: Lose Dagger Engine cache when nodes are de-provisioned (can be mitigated via persistent volumes).

## Recommendations

- **Runner nodes with moderate to large NVMe drives**: Dagger Engine cache can grow very large. NVMe drives are faster and usually less expensive.
- **Appropriately sized nodes**: Minimum 2 vCPUs and 8GB RAM is a good start.

## Prerequisites

- A running Kubernetes cluster with pre-configured `kubectl` profile
- [Helm](https://helm.sh/) installed

## Example

Install Dagger using Helm:

```bash
helm upgrade --install --namespace=dagger --create-namespace \
    dagger oci://registry.dagger.io/dagger-helm
```

Wait for the Dagger Engine:

```bash
kubectl wait --for condition=Ready --timeout=60s pod \
    --selector=name=dagger-dagger-helm-engine --namespace=dagger
```

Get the pod name and set environment variable:

```bash
DAGGER_ENGINE_POD_NAME="$(kubectl get pod \
    --selector=name=dagger-dagger-helm-engine --namespace=dagger \
    --output=jsonpath='{.items[0].metadata.name}')"

_EXPERIMENTAL_DAGGER_RUNNER_HOST="kube-pod://$DAGGER_ENGINE_POD_NAME?namespace=dagger"
export _EXPERIMENTAL_DAGGER_RUNNER_HOST
```

Test:

```bash
dagger query <<EOF
{
    container {
        from(address:"alpine") {
            withExec(args: ["uname", "-a"]) { stdout }
        }
    }
}
EOF
```

## About Kubernetes

[Kubernetes](https://kubernetes.io/) is an open-source container orchestration platform that automates deployment, scaling, and management of containerized applications.

## See Also

- [Documentation Overview](./COMPASS.md)
