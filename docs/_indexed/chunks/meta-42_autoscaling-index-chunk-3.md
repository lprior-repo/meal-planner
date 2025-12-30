---
doc_id: meta/42_autoscaling/index
chunk_id: meta/42_autoscaling/index#chunk-3
heading_path: ["Autoscaling", "authenticate to the cluster here if needed"]
chunk_type: code
tokens: 685
summary: "authenticate to the cluster here if needed"
---

## authenticate to the cluster here if needed
kubectl scale deployment windmill-workers-$worker_group --replicas=$desired_workers -n $namespace
```

### Kubernetes

Kubernetes native autoscaling integration can automatically infer the worker-group, namespace and credentials when running within a Kubernetes cluster. This autoscaling will only work if you run your server in the k8s cluster and will only scale workers within the same cluster.

For proper functionality, you need to configure RBAC roles and rolebindings to allow autoscaling from within the pod:

#### Using Helm

In your values.yaml set:
```yaml
enterprise:
  createKubernetesAutoscalingRolesAndBindings: true
```

#### Using pure manifests

Sometimes creating a Role/RoleBinding is forbidden by RBAC or rejected by an admission controller, that's why you might want to do this outside this helm release.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-scaler
  namespace: <windmill-namespace>
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["patch", "get"]  # Crucial to include both verbs

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployment-scaler-binding
  namespace: <windmill-namespace>
subjects:
- kind: ServiceAccount
  name: <serviceaccount>
  namespace: <windmill-namespace>
roleRef:
  kind: Role
  name: deployment-scaler
  apiGroup: rbac.authorization.k8s.io

```

You need to bind the role to the correct ServiceAccount which is bound to 'fullname' (the name you gave to your windmill deployment). You can verify which ServiceAccount name you have by running:

```bash
kubectl get serviceaccount -n <your-namespace>
```

Look for the non-default ServiceAccount name.

#### Verifying configuration

After configuring RBAC using either method above, you can hit "Check Health" to verify everything is configured properly:

![Healthy autoscaling configuration](./healthy_k8s_config.png)

You are ready to go!

For more sophisticated autoscaling designs, refer to the 'Custom script' section above.

### Advanced

| Parameter                                                                         | Description                                                                                                                                                                                                                                     |
| --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Cooldown seconds after an incremental scale-in/out                                | Time to wait after an incremental scaling event before allowing another                                                                                                                                                                         |
| Cooldown seconds after a full scale out                                           | Time to wait after a full scale out event before allowing another                                                                                                                                                                               |
| Num jobs waiting to trigger an incremental scale-out                              | Number of waiting jobs needed to trigger a gradual scale out                                                                                                                                                                                    |
| Num jobs waiting to trigger a full scale out                                      | Number of waiting jobs needed to trigger scaling to max workers (Default: max_workers, full scale out = scale out to max workers)                                                                                                               |
| Occupancy rate % threshold to go below to trigger a scale-in (decrease)           | Default: 25%. When the average worker occupancy rate across 15s, 5m and 30m intervals falls below this threshold, the system will trigger a scale-in event to reduce the number of workers. This helps prevent having too many idle workers.    |
| Occupancy rate threshold to exceed to trigger an incremental scale-out (increase) | Default: 75%. When the average worker occupancy rate across 15s, 5m and 30m intervals exceeds this threshold, the system will trigger a scale-out event to add more workers. This helps ensure there is enough capacity to handle the workload. |
| Num workers to scale-in/out by when incremental                                   | Number of workers to add/remove during incremental scaling events (Default: (max_workers - min_workers) / 5)                                                                                                                                    |
| Custom tags to autoscale on                                                       | By default, autoscaling will apply to the tags the worker group is assigned to but you can override this here.                                                                                                                                  |
