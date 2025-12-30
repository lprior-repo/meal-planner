---
doc_id: meta/15_dependencies_in_python/index
chunk_id: meta/15_dependencies_in_python/index#chunk-19
heading_path: ["Dependencies in Python", "///"]
chunk_type: code
tokens: 408
summary: "///"
---

## ///

import requests
import pandas as pd
import numpy as np

def main():
    response = requests.get("https://api.example.com/data")
    df = pd.DataFrame(response.json())
    return df.to_dict()
```

The PEP-723 format allows you to:
- Specify exact Python version requirements with `requires-python`
- List dependencies with version constraints in the `dependencies` array
- Use standard [PEP 440](https://peps.python.org/pep-0440/) version specifiers

**Python version shortcut**

For Python version requirements, Windmill also provides a convenient shortcut. Instead of using the full PEP-723 `requires-python` field, you can use the simple annotation format:

```python
#py: >=3.12

def main():
    return "Hello from Python 3.12+"
```

This shortcut is equivalent to specifying `requires-python = ">=3.12"` in the PEP-723 format.


<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Select Python version"
		description="Learn more about Python version selection and version specifiers."
		href="/docs/getting_started/scripts_quickstart/python#select-python-version"
		color="teal"
	/>
</div>
### Private PyPI repository

Environment variables can be set to customize `uv`'s index-url and extra-index-url and certificate.
This is useful for private repositories.

In a docker-compose file, you would add following lines:

```dockerfile
windmill_worker:
  ...
  environment:
    ...
    # Completely whitelist pypi.org
    - PY_TRUSTED_HOST=pypi.org
    # or specificy path to custom certificate 
    - PY_INDEX_CERT=/custom-certs/root-ca.crt
```
:::note
UV is not using system certificates by default, if you wish to use them, set `PY_NATIVE_CERT=true`
:::


`UV index url` and `UV extra index url` are filled through Windmill UI, in [Instance settings](./meta-18_instance_settings-index.md#registries) under [Enterprise Edition](/pricing).

![Private PyPI Repository](./private_pip.png 'Private PyPI Repository')

### Python runtime settings

For a given [worker group](./meta-9_worker_groups-index.md), you can add Python [runtime specific settings](./meta-9_worker_groups-index.md#python-runtime-settings) like additional Python paths and PIP local dependencies.

### Select Python version

You can annotate the version of Python you would like to use for a script using the annotations like py310, py311, py312, or py313.

More details:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Select Python version"
		description="You can annotate the version of Python you would like to use for a script using the annotations like py310, py311, py312, or py313:"
		href="/docs/getting_started/scripts_quickstart/python#select-python-version"
	/>
</div>
