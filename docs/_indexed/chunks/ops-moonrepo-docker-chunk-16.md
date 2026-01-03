---
doc_id: ops/moonrepo/docker
chunk_id: ops/moonrepo/docker#chunk-16
heading_path: ["docker", "Copy entire repository and scaffold"]
chunk_type: prose
tokens: 26
summary: "Copy entire repository and scaffold"
---

## Copy entire repository and scaffold
COPY . .
RUN moon docker scaffold <project>

### BUILD
FROM base AS build
