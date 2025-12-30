---
id: ref/reference/configuration-custom-ca
title: "Custom Certificate Authorities (CA)"
category: ref
tags: ["ref", "config", "auth", "ai", "container"]
---

# Custom Certificate Authorities (CA)

> **Context**: Dagger can be configured to use custom certificate authorities (CAs) when communicating with external services like container registries, Git reposito...


Dagger can be configured to use custom certificate authorities (CAs) when communicating with external services like container registries, Git repositories, etc.

## Configuration

### Method 1: Automatic provisioned engine

Write certificates to:
- `~/.config/dagger/ca-certificates` on Linux
- `~/Library/Application Support/dagger/ca-certificates` on macOS
- `$XDG_CONFIG_HOME/dagger/ca-certificates` if set

### Method 2: Custom runner

Place custom CAs in the `/usr/local/share/ca-certificates/` directory of the Dagger container:

```bash
docker run --rm \
    -v /var/lib/dagger \
    -v $PWD/ca-certificates:/usr/local/share/ca-certificates/ \
    --name dagger-engine-custom \
    --privileged \
    registry.dagger.io/engine:v0.19.7
```

The CAs will be automatically installed on Dagger startup.

## Configuration Applied to User Containers

Dagger provides best-effort support for automatically installing custom CAs in all containers created by user workflows.

Supported base distributions:
- Alpine
- Debian-based (e.g., `debian` and `ubuntu`)
- Redhat-based (e.g., `rhel`, `fedora`, `centos`, etc.)

Behavior:
- If installation fails, the error is logged but execution continues
- When the container exits, the CAs are automatically removed to prevent leaking into cache or published images

## See Also

- [Documentation Overview](./COMPASS.md)
