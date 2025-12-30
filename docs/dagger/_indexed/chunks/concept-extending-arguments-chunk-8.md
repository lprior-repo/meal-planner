---
doc_id: concept/extending/arguments
chunk_id: concept/extending/arguments#chunk-8
heading_path: ["arguments", "Service arguments"]
chunk_type: prose
tokens: 134
summary: "Host network services or sockets can be passed to Dagger Functions as arguments."
---
Host network services or sockets can be passed to Dagger Functions as arguments. To do so, add the corresponding flag, followed by a service or socket reference.

### TCP and UDP services

To pass host TCP or UDP network services as arguments when invoking a Dagger Function, specify them in the form `tcp://HOST:PORT` or `udp://HOST:PORT`.

### Unix sockets

Similar to host TCP/UDP services, Dagger Functions can also be granted access to host Unix sockets when the client is running on Linux or MacOS.

To pass host Unix sockets as arguments when invoking a Dagger Function, specify them by their path on the host.
