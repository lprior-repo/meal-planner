---
doc_id: tutorial/ci-integrations/azure-pipelines
chunk_id: tutorial/ci-integrations/azure-pipelines#chunk-6
heading_path: ["azure-pipelines", "full clone checkout required to prevent azure pipeline traces from being orphaned in the Dagger Cloud UI"]
chunk_type: prose
tokens: 16
summary: "- checkout: self
  fetchDepth: 0
  displayName: 'Checkout Source Code, fetch full history'"
---
- checkout: self
  fetchDepth: 0
  displayName: 'Checkout Source Code, fetch full history'
