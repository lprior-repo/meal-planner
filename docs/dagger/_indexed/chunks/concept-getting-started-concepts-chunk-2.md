---
doc_id: concept/getting-started/concepts
chunk_id: concept/getting-started/concepts#chunk-2
heading_path: ["concepts", "Functions"]
chunk_type: code
tokens: 133
summary: "To create a workflow with the Dagger API, you call multiple functions, combining them together in..."
---
To create a workflow with the Dagger API, you call multiple functions, combining them together in sequence to form a workflow. Here's an example:

**System shell:**
```bash
dagger <<EOF
container |
  from alpine |
  file /etc/os-release |
  contents
EOF
```

**Dagger Shell:**
```
container |
  from alpine |
  file /etc/os-release |
  contents
```

**Dagger CLI:**
```bash
dagger core container \
  from --address=alpine \
  file --path=/etc/os-release \
  contents
```

This example calls multiple functions from the Dagger API in sequence to create a workflow that builds an image from an `alpine` container and returns the contents of the `/etc/os-release` file to the caller.
