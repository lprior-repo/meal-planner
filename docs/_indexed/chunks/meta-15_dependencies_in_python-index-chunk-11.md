---
doc_id: meta/15_dependencies_in_python/index
chunk_id: meta/15_dependencies_in_python/index#chunk-11
heading_path: ["Dependencies in Python", "content of f/foo/main:"]
chunk_type: prose
tokens: 140
summary: "content of f/foo/main:"
---

## content of f/foo/main:
import f.foo.bar
import f.foo.baz
import dependency # repin: dependency==1.0 Repin to version that works for all scripts
...

```

:::note
Windmill assumes that imports directly map to requirements,
however it is not always the case.
To handle this there is windmill import map.
And if you found a public python dependency that needs to be explicitly mapped you can submit an issue or [contribute](../../misc/4_contributing/index.md#mapping-python-imports). 
:::

### PEP-723 inline script metadata

Windmill supports **PEP-723** inline script metadata, providing a standardized way to specify script dependencies and Python version requirements directly within your script. This implements the official Python packaging standard for inline script metadata.

```python
