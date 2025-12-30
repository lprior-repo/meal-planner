---
doc_id: tutorial/reference/configuration-custom-runner
chunk_id: tutorial/reference/configuration-custom-runner#chunk-3
heading_path: ["configuration-custom-runner", "Execution Requirements"]
chunk_type: prose
tokens: 42
summary: "1."
---
1. The runner container needs root capabilities, including `CAP_SYS_ADMIN` (use `--privileged` flag)
2. The runner container should be given a volume at `/var/lib/dagger`
3. Use the default entrypoint to start the runner
