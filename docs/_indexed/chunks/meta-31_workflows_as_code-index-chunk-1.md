---
doc_id: meta/31_workflows_as_code/index
chunk_id: meta/31_workflows_as_code/index#chunk-1
heading_path: ["Workflows as code"]
chunk_type: prose
tokens: 362
summary: "import Tabs from '@theme/Tabs';"
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Workflows as code

> **Context**: import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

[Flows](./tutorial-flows-1-flow-editor.md) are not the only way to write distributed programs that execute distinct jobs. Another approach is to write a program that defines the jobs and their dependencies, and then execute that program. This is known as workflows as code.

![Script in python executing workflow as code](./python_editor.png 'Script in python executing workflow as code')

One way of doing this is to use the [API of Windmill](https://app.windmill.dev/openapi.html) itself, to run jobs imperatively, using run_script and run_flow (their sync or async counterparts). This is a powerful way to define workflows, but it can be complex and verbose.

It also requires to define the different jobs in different scripts. This is why Windmill supports defining workflows as code in a single script in both [Python](./meta-2_python_quickstart-index.md) and [TypeScript](./meta-1_typescript_quickstart-index.md) using intuitive and lightweight syntax.

The syntax is highlighted in the below examples, note that the subtask are indeed executed as distinct jobs, with their own logs, and their relationship with their parent task is recorded which allows for the timeline of each task to be displayed in the UI.

To have some steps refer to other scripts and flows not in this file, use the normal functions `run_script` from the Windmill SDK. The script below is a normal script and does not need special consideration. As such, it will already work with all the features of normal script and can be [synced with the git](./meta-11_git_sync-index.md) and the [CLI](./ops-11_git_sync-cli-sync.md).

<Tabs className="unique-tabs">
<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
from wmill import task

import pandas as pd
import numpy as np

@task()
