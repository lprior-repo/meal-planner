---
doc_id: meta/21_scaling/index
chunk_id: meta/21_scaling/index#chunk-1
heading_path: ["Scaling workers"]
chunk_type: prose
tokens: 75
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';
import WorkerQueueSimulator from '@site/src/components/WorkerQueueSimulator';

# Scaling workers

> **Context**: import DocCard from '@site/src/components/DocCard'; import WorkerQueueSimulator from '@site/src/components/WorkerQueueSimulator';

Windmill uses a worker queue architecture where workers pull jobs from a shared queue and execute them one at a time. Understanding this pattern is essential for properly sizing your worker pool to meet your business requirements.
