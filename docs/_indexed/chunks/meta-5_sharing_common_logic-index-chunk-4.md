---
doc_id: meta/5_sharing_common_logic/index
chunk_id: meta/5_sharing_common_logic/index#chunk-4
heading_path: ["Sharing common logic", "u/user/custom_script"]
chunk_type: prose
tokens: 53
summary: "u/user/custom_script"
---

## u/user/custom_script

from u.user.common_logic import foo

def main():
  return foo()
```

It works with Scripts contained in folders, and for scripts contained in
user-spaces, e.g: `f.<foldername>.script_path` or `u.<username>.script_path`.

You can also do relative imports to the current script. For instance.

```python
