---
doc_id: meta/8_preinstall_binaries/index
chunk_id: meta/8_preinstall_binaries/index#chunk-5
heading_path: ["Preinstall binaries", "Examples with docker compose"]
chunk_type: code
tokens: 84
summary: "Examples with docker compose"
---

## Examples with docker compose

All examples above can be used in your [`docker-compose.yml`](https://github.com/windmill-labs/windmill/blob/main/docker-compose.yml) by specifying the build context.

Replace:

```yaml
  windmill_worker:
    image: ${WM_IMAGE}
```

With the following:

```yaml
  windmill_worker:
    build:
      context: ./path/to/dockerfile
      args:
        WM_IMAGE: ${WM_IMAGE}
```

Note that you can pass environment variables from your `.env` file via the args above and use them in your `Dockerfile`:

```dockerfile
ARG WM_IMAGE
FROM ${WM_IMAGE}

[...]
```
