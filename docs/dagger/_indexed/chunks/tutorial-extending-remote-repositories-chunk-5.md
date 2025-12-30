---
doc_id: tutorial/extending/remote-repositories
chunk_id: tutorial/extending/remote-repositories#chunk-5
heading_path: ["remote-repositories", "Known limitations and workarounds"]
chunk_type: prose
tokens: 147
summary: "This section outlines current limitations and provides workarounds for common issues."
---
This section outlines current limitations and provides workarounds for common issues. We're actively working on improvements for these areas.

### Windows is not supported

Currently, SSH refs are fully supported on UNIX-based systems (Linux and macOS). Windows support is under development. Track progress and contribute to the discussion in our [GitHub issue for Windows support](https://github.com/dagger/dagger/issues/8313).

### Multiple SSH keys may cause SSH forwarding to fail

SSH forwarding may fail when multiple keys are loaded in your SSH agent. This is under active investigation in our [GitHub issue](https://github.com/dagger/dagger/issues/8288). Until this is resolved, the following workaround may be used:

1. Clear all loaded keys: `ssh-add -D`
2. Add back only the required key: `ssh-add /path/to/key`
