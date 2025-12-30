---
doc_id: ops/reference/deployment-openshift
chunk_id: ops/reference/deployment-openshift#chunk-2
heading_path: ["deployment-openshift", "How it Works"]
chunk_type: prose
tokens: 66
summary: "The architecture consists of:
- A Dagger Engine DaemonSet which executes pipelines
- Tainted nodes f"
---
The architecture consists of:
- A Dagger Engine DaemonSet which executes pipelines
- Tainted nodes for dedicated workloads

The Dagger DaemonSet configuration is designed to:
- Best utilize local NVMe drives of the worker nodes
- Reduce network latency and bandwidth requirements
- Simplify routing of Dagger SDK and CLI requests
