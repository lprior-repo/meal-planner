---
doc_id: ops/reference/container-runtimes-docker
chunk_id: ops/reference/container-runtimes-docker#chunk-2
heading_path: ["container-runtimes-docker", "Prerequisites"]
chunk_type: mixed
tokens: 58
summary: "Ensure that Docker is running on the host system:

```bash
docker info
```

Install Docker using:..."
---
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
