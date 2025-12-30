---
doc_id: meta/55_workspace_dependencies/index
chunk_id: meta/55_workspace_dependencies/index#chunk-5
heading_path: ["Workspace dependencies", "requirements: ml"]
chunk_type: code
tokens: 67
summary: "requirements: ml"
---

## requirements: ml

import pandas as pd
import requests

def main():
    return "Uses only ml.requirements.in"
```

```typescript
// package_json: frontend

import axios from 'axios';
import lodash from 'lodash';

export async function main() {
    return "Uses only frontend.package.json";
}
```

### Including workspace defaults

Use `default` token to include unnamed default files:

```python
