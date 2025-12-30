---
doc_id: meta/security_isolation/index
chunk_id: meta/security_isolation/index#chunk-2
heading_path: ["Security and process isolation", "Overview"]
chunk_type: prose
tokens: 113
summary: "Overview"
---

## Overview

Windmill workers execute user-provided code in various languages. To protect the worker process and the underlying infrastructure, Windmill implements multiple isolation strategies:

1. **PID Namespace Isolation** - Process memory and environment protection (disabled by default, requires configuration)
2. **NSJAIL Sandboxing** - Filesystem, network, and resource isolation (optional, requires special image)
3. **Agent Workers** - Workers without direct database access, communicating via the API
4. **Worker Groups** - Logical separation of workers that can be used to run workers on separate clusters with different network/resource access
