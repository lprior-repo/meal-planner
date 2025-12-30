---
doc_id: meta/7_docker/index
chunk_id: meta/7_docker/index#chunk-1
heading_path: ["Run Docker containers"]
chunk_type: prose
tokens: 62
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Run Docker containers

> **Context**: import DocCard from '@site/src/components/DocCard';

:::info Worker security

Windmill workers in the official docker-compose have `ENABLE_UNSHARE_PID=true` enabled by default for process isolation. This protects worker credentials from being accessed by jobs. See [Security and Process Isolation](/docs/advanced/security_isolation) for details.

:::
