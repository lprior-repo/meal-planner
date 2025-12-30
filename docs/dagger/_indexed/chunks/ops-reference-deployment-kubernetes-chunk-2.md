---
doc_id: ops/reference/deployment-kubernetes
chunk_id: ops/reference/deployment-kubernetes#chunk-2
heading_path: ["deployment-kubernetes", "Architecture Patterns"]
chunk_type: prose
tokens: 98
summary: "Components:
- **Kubernetes cluster**: Support nodes and runner nodes
- **Certificates manager**: ..."
---
### Persistent Nodes

Components:
- **Kubernetes cluster**: Support nodes and runner nodes
- **Certificates manager**: Required by Runner controller
- **Runner controller**: Manages CI runners in response to job requests
- **Dagger Engine**: Deployed as a DaemonSet on each runner node

### Ephemeral, Auto-scaled Nodes

Add a node auto-scaler to automatically adjust the size of node groups based on workload.

Trade-off: Lose Dagger Engine cache when nodes are de-provisioned (can be mitigated via persistent volumes).
