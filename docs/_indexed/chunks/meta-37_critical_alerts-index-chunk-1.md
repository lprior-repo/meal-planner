---
doc_id: meta/37_critical_alerts/index
chunk_id: meta/37_critical_alerts/index#chunk-1
heading_path: ["Critical alerts"]
chunk_type: prose
tokens: 184
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Critical alerts

> **Context**: import DocCard from '@site/src/components/DocCard';

Get a notification everytime a job is re-run after a crash.

This feature is available in the [Enterprise Edition](/pricing).

If the node it which it runs halt suddenly (such as a power loss), then the [job](./meta-20_jobs-index.md) will be restarted automatically. Windmill itself doesn't crash and other softer interruptions like a pod termination involve a grace period (300s) to let the job finish.

Critical alerts are generated under the following conditions:

- [Job](./meta-20_jobs-index.md) is re-run after a crash.
- [License key](../../misc/7_plans_details/index.mdx#using-the-license-key-self-host) does not renew.
- [Workspace error handler](./meta-10_error_handling-index.md#workspace-error-handler) fails.
- Number of running workers in a group falls below a specified threshold (has to be configured in the [worker group](./meta-9_worker_groups-index.md) config).
- Number of [jobs waiting in queue](./meta-9_worker_groups-index.md#queue-metric-alerts) is above a threshold for more than a specified amount of time.
