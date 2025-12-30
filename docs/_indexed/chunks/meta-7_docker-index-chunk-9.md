---
doc_id: meta/7_docker/index
chunk_id: meta/7_docker/index#chunk-9
heading_path: ["Run Docker containers", "Docker-in-Docker sidecar container (recommended)"]
chunk_type: code
tokens: 215
summary: "Docker-in-Docker sidecar container (recommended)"
---

## Docker-in-Docker sidecar container (recommended)

One possibility to use the docker daemon with k8s with containerd is to run a docker daemon in the same pod using "Docker-in-Docker" ( dind) Using the official image `docker:stable-dind`:

Here an example of a a worker group setup with a dind side-container to be adapted with your needs.

```yaml
  workerGroups:
    ...
    - name: "docker"
      replicas: 2
      securityContext:
        privileged: true
      resources:
        limits:
          memory: "256M"
          ephemeral-storage: "8Gi"
      volumes:
        - emptyDir: {}
          name: sock-dir
        - emptyDir: {}
          name: windmill-workspace
      volumeMounts:
        - mountPath: /var/run
          name: sock-dir
        - mountPath: /opt/windmill
          name: windmill-workspace
      extraContainers:
        - args:
            - --mtu=1450
          image: docker:27.2.1-dind
          imagePullPolicy: IfNotPresent
          name: dind
          resources:
            limits:
              memory: "2Gi"
              ephemeral-storage: "8Gi"
          securityContext:
            privileged: true
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          volumeMounts:
            - mountPath: /opt/windmill
              name: windmill-workspace
            - mountPath: /var/run
              name: sock-dir
```




### Using remote container runtimes (not recommended)

This method is not recommended because it skips Windmill's native docker runtime and simpl execute as a normal bash script.

### Remote docker daemon (not recommended)

```bash
#!/bin/bash

set -ex
