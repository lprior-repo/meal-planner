---
doc_id: ops/install/kubesail
chunk_id: ops/install/kubesail#chunk-1
heading_path: ["Kubesail"]
chunk_type: prose
tokens: 170
summary: "Kubesail"
---

# Kubesail

> **Context**: !!! info "Community Contributed" This guide was contributed by the community and is neither officially supported, nor updated or tested.

!!! info "Community Contributed"
    This guide was contributed by the community and is neither officially supported, nor updated or tested.

!!! danger "Tandoor 2 Compatibility"
    This guide has not been verified/tested for Tandoor 2, which now integrates a nginx service inside the default docker container and exposes its service on port 80 instead of 8080.

[KubeSail](https://kubesail.com/) lets you install Tandoor by providing a simple web interface for installing and managing apps. You can connect any server running Kubernetes, or get a pre-configured [PiBox](https://pibox.io).

<!-- A portion of every PiBox sale goes toward supporting Tandoor development. -->

The KubeSail template is closely based on the [Kubernetes installation]([docs/install/k8s](https://github.com/vabene1111/recipes/tree/develop/docs/install/k8s)) configs
