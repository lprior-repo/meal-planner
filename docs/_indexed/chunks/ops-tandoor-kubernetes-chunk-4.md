---
doc_id: ops/tandoor/kubernetes
chunk_id: ops/tandoor/kubernetes#chunk-4
heading_path: ["Kubernetes", "Conclusion"]
chunk_type: prose
tokens: 188
summary: "Conclusion"
---

## Conclusion

All in all:

- The database is set up as a stateful set.
- The database container runs as a low privileged user.
- Database and application use secrets.
- The application also runs as a low privileged user.
- nginx runs as root but forks children with a low privileged user.
- There's an ingress rule to access the application from outside.

I tried the setup with [kind](https://kind.sigs.k8s.io/) and it runs well on my local cluster.

There is a warning, when you check your system as super user:

!!! warning "Media Serving Warning"
    Serving media files directly using gunicorn/python is not recommend! Please follow the steps described here to update your installation.

I don't know how this check works, but this warning is simply wrong! ;-) Media and static files are routed by ingress to the nginx container - I promise :-)
