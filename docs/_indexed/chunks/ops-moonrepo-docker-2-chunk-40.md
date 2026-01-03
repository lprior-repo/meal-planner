---
doc_id: ops/moonrepo/docker-2
chunk_id: ops/moonrepo/docker-2#chunk-40
heading_path: ["Docker integration", "Troubleshooting"]
chunk_type: prose
tokens: 79
summary: "Troubleshooting"
---

## Troubleshooting

### Supporting `node:alpine` images

If you're trying to use the `node:alpine` image with moon's [integrated toolchain](/docs/concepts/toolchain), you'll need to set the `MOON_TOOLCHAIN_FORCE_GLOBALS` environment variable in the Docker image to disable moon's toolchain. This is required as Node.js does not provide pre-built binaries for the Alpine target, so installing the Node.js toolchain will fail.

```dockerfile
FROM node:alpine

ENV MOON_TOOLCHAIN_FORCE_GLOBALS=true
```
