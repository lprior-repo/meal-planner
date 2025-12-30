---
doc_id: meta/15_dependencies_in_python/index
chunk_id: meta/15_dependencies_in_python/index#chunk-6
heading_path: ["Dependencies in Python", "u/user/custom_script"]
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
