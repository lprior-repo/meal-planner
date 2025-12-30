---
doc_id: meta/security_isolation/index
chunk_id: meta/security_isolation/index#chunk-15
heading_path: ["Security and process isolation", "Troubleshooting"]
chunk_type: prose
tokens: 28
summary: "Troubleshooting"
---

## Troubleshooting

### Worker fails to start with "unshare: Operation not permitted"

**Cause**: User namespaces are disabled in the kernel.

**Solution**:

```bash
