---
doc_id: ops/reference/deployment-kubernetes
chunk_id: ops/reference/deployment-kubernetes#chunk-5
heading_path: ["deployment-kubernetes", "Example"]
chunk_type: code
tokens: 94
summary: "Install Dagger using Helm:

```bash
helm upgrade --install --namespace=dagger --create-namespace ..."
---
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
