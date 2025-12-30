# Podman Runtime

Dagger can be used with any OCI-compatible container runtime, including Podman.

## Prerequisites

Ensure that Podman is installed and running on your system:

```bash
podman info
```

> **Warning**: Podman must be configured for [rootful container execution](https://docs.podman.io/en/stable/markdown/podman-machine-set.1.html#rootful).

Install Podman using the [official instructions](https://podman.io/getting-started/installation).

> **Note**: Podman Desktop on Mac and RHEL 8.x users may need to additionally execute `modprobe iptable_nat`.

To access the virtual machine used by Podman Desktop on Mac:

```bash
# list podman machines
podman machine list

# log in to machine
podman machine ssh podman-machine-default

# execute command
sudo modprobe iptable_nat
```

## Example

```bash
$ podman ps
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES

$ dagger core version
v0.18.19

$ podman ps
CONTAINER ID   IMAGE                                COMMAND                  CREATED       STATUS       PORTS   NAMES
27d47c3d5a10   registry.dagger.io/engine:v0.18.19   "dagger-entrypoint.s…"   6 days ago    Up 4 hours           dagger-engine-v0.18.19
```

## About Podman

[Podman](https://podman.io/) is a Docker-compatible tool to manage and run OCI containers.
