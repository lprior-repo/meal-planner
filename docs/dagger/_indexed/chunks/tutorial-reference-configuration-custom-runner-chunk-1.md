---
doc_id: tutorial/reference/configuration-custom-runner
chunk_id: tutorial/reference/configuration-custom-runner#chunk-1
heading_path: ["configuration-custom-runner"]
chunk_type: prose
tokens: 81
summary: "> **Context**: A runner is the \"backend\" of Dagger where containers are actually executed."
---
# Custom Runner Configuration

> **Context**: A runner is the "backend" of Dagger where containers are actually executed.


A runner is the "backend" of Dagger where containers are actually executed.

Runners are responsible for:
- Executing containers specified by functions
- Pulling container images, Git repos and other sources
- Pushing container images to registries
- Managing the cache backing function execution
