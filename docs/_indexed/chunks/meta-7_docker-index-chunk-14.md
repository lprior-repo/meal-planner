---
doc_id: meta/7_docker/index
chunk_id: meta/7_docker/index#chunk-14
heading_path: ["Run Docker containers", "See documentation: https://www.windmill.dev/docs/advanced/docker"]
chunk_type: code
tokens: 189
summary: "See documentation: https://www.windmill.dev/docs/advanced/docker"
---

## See documentation: https://www.windmill.dev/docs/advanced/docker
msg="${1:-world}"

IMAGE="docker/whalesay:latest"
COMMAND=(sh -c "cowsay $msg")

APISERVER=https://kubernetes.default.svc
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
TOKEN=$(cat ${SERVICEACCOUNT}/token)
CACERT=${SERVICEACCOUNT}/ca.crt

KUBECONFIG_TMP_DIR="$(mktemp -d)"
export KUBECONFIG="${KUBECONFIG_TMP_DIR}/kubeconfig"

trap "rm -rfv ${KUBECONFIG_TMP_DIR}" EXIT

kubectl config set-cluster local --server="${APISERVER}" --certificate-authority="${CACERT}"
kubectl config set-credentials local --token="${TOKEN}"
kubectl config set-context local --cluster=local --user=local --namespace="${NAMESPACE}"
kubectl config use-context local

kubectl run task -it --rm --restart=Never --image="$IMAGE" -- "${COMMAND[@]}"
```

and use the following additional privileges

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: windmill
  name: pod-management
rules:
  - apiGroups: ['']
    resources: ['pods']
    verbs: ['get', 'list', 'watch', 'create', 'update', 'patch', 'delete']
  - apiGroups: ['']
    resources: ['pods/log']
    verbs: ['get', 'list', 'watch']
  - apiGroups: ['']
    resources: ['pods/attach']
    verbs: ['get', 'list', 'watch', 'create', 'update', 'patch', 'delete']
  - apiGroups: ['']
    resources: ['events']
    verbs: ['get', 'list', 'watch']
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-management
  namespace: windmill
subjects:
  - kind: ServiceAccount
    name: windmill-chart
    namespace: windmill
roleRef:
  kind: Role
  name: pod-management
  apiGroup: rbac.authorization.k8s.io
```
