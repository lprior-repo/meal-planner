---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-17
heading_path: ["Windmill Deployment Guide", "wmill.yaml - Multi-environment configuration"]
chunk_type: prose
tokens: 44
summary: "wmill.yaml - Multi-environment configuration"
---

## wmill.yaml - Multi-environment configuration
defaultTs: bun
includes:
  - f/**
excludes: []
codebases: []
skipVariables: false
skipResources: false
skipResourceTypes: false
skipSecrets: true       # Keep secrets manual for security
includeSchedules: true
includeTriggers: true
```

---
