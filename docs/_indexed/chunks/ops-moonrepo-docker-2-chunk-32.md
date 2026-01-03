---
doc_id: ops/moonrepo/docker-2
chunk_id: ops/moonrepo/docker-2#chunk-32
heading_path: ["Docker integration", "Copy entire repository and scaffold"]
chunk_type: prose
tokens: 26
summary: "Copy entire repository and scaffold"
---

## Copy entire repository and scaffold
COPY . .
RUN moon docker scaffold <project>

### BUILD
FROM base AS build
