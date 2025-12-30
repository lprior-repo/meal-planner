---
doc_id: ops/reference/deployment-openshift
chunk_id: ops/reference/deployment-openshift#chunk-4
heading_path: ["deployment-openshift", "Example"]
chunk_type: code
tokens: 125
summary: "Create a `values."
---
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
