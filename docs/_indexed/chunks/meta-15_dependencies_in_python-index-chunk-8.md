---
doc_id: meta/15_dependencies_in_python/index
chunk_id: meta/15_dependencies_in_python/index#chunk-8
heading_path: ["Dependencies in Python", "otherwise if you need to access the folder 'folder'"]
chunk_type: code
tokens: 362
summary: "otherwise if you need to access the folder 'folder'"
---

## otherwise if you need to access the folder 'folder'
from ..folder.common_logic import foo
```

Beware that you can only import scripts that you have view rights on at time of execution.

The folder layout is identical with the one that works with the CLI for syncing
scripts locally and on Windmill. See [Developing scripts locally](./meta-4_local_development-index.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Sharing common logic"
		description="It is common to want to share common logic between your scripts. This can be done easily using relative imports in both Python and TypeScript."
		href="/docs/advanced/sharing_common_logic"
	/>
</div>

### Pinning dependencies and requirements
#### Requirements
If the imports are not properly analyzed, there exists an escape hatch to
override the inferred imports. One needs to head the Script with the `requirements` comment followed by dependencies.
The standard pip [requirement specifiers](https://pip.pypa.io/en/stable/reference/requirement-specifiers/) are supported. Some examples:

```python
#requirements:
#dependency1[optional_module]
#dependency2>=0.40
#dependency3@git+https://github.com/myrepo/dependency3.git

import dependency1
import dependency2
import dependency3

def main(...):
  ...
```

#### Extra requirements

To add extra dependencies or pin the version of some dependencies

To combine both the inference of Windmill and being able to pin dependencies, use `extra_requirements`:

```python
#extra_requirements:
#dependency==0.4

import pandas
import dependency

def main(...):
  ...
```

#### Pin and Repin

It is possible to pin specific import to different version or even another dependency

```python
import pandas
import dependency # pin: dependency==0.4
import nested.modules # pin: nested-modules

def main(...):
  ...
```

If import was pinned once, whenever you use the same import again it will be pinned.

It is possible to have several pins to same import and all of them will be included.
However if you want to override all pins associated with an import you can use `repin`
```python
