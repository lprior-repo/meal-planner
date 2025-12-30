---
doc_id: meta/5_monitor_past_and_future_runs/index
chunk_id: meta/5_monitor_past_and_future_runs/index#chunk-4
heading_path: ["Jobs runs", "Filters"]
chunk_type: prose
tokens: 159
summary: "Filters"
---

## Filters

You can adjust the level of details by picking playing with filters on:

- **Datetime**
- **Metadata**: [Path](./meta-16_roles_and_permissions-index.md#path) / [User](./meta-16_roles_and_permissions-index.md#users) / [Folder](./meta-8_groups_and_folders-index.md) / [Worker](./meta-9_worker_groups-index.md) / [Concurrency key](./meta-21_concurrency_limits-index.md#custom-concurrency-key) / [Labels](#jobs-labels)
- **Kind**: All / Runs / Previews / Dependencies
- **Status**: All / Success / Failure
- **Skipped flows**
- **Arguments**
- **Results**

Example of filters in use:

![Filters](./4-filters.png 'Filters')

> Here were filtered successful runs from August 2023 which returned `{"baseNumber": 11}`.

<br/>

Filter by worker, labels or tags support wildcards (*) by enabling `allow wildcards (*)` in the filter.

![Allow wildcards](./allow_wildcards.png 'Allow wildcards')

> Enable wildcards to filter a [label](#jobs-labels)

You can also filter by argument directly from a script / flow [deployed](./meta-0_draft_and_deploy-index.md) page.

![Filter by argument](./filter_by_argument.png 'Filter by argument')
