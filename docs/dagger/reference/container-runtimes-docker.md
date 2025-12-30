# Docker Runtime

Dagger can be used with any OCI-compatible container runtime, including Docker.

## Prerequisites

Ensure that Docker is running on the host system:

```bash
docker info
```

Install Docker using:
- [Official Docker documentation](https://docs.docker.com/get-docker/)
- System package manager:
  - Debian/Ubuntu: `apt install docker.io`
  - Fedora: `dnf install docker`
  - Arch Linux: `pacman -S docker`
- Third-party tool like [Orbstack](https://orbstack.dev/)

## Example

```bash
$ docker ps
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES

$ dagger core version
v0.18.19

$ docker ps
CONTAINER ID   IMAGE                                COMMAND                  CREATED       STATUS       PORTS   NAMES
27d47c3d5a10   registry.dagger.io/engine:v0.18.19   "dagger-entrypoint.s…"   6 days ago    Up 4 hours           dagger-engine-v0.18.19
```

## Resources

Join the [Discord](https://discord.gg/dagger-io) and ask questions in the [help channel](https://discord.com/channels/707636530424053791/1030538312508776540).
