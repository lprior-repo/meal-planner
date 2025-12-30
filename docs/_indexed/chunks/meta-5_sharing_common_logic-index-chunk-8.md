---
doc_id: meta/5_sharing_common_logic/index
chunk_id: meta/5_sharing_common_logic/index#chunk-8
heading_path: ["Sharing common logic", "Bash logic sharing"]
chunk_type: prose
tokens: 37
summary: "Bash logic sharing"
---

## Bash logic sharing

You can reuse bash scripts by fetching them "raw" and source them. The url is as follows:

```
curl -H "Authorization: Bearer <Token>" <INSTANCE>/api/w/<workspace>/scripts/raw/p/<path>.sh
```
