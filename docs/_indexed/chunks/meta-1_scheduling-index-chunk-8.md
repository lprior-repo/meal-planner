---
doc_id: meta/1_scheduling/index
chunk_id: meta/1_scheduling/index#chunk-8
heading_path: ["Schedules", "Schedule to run later"]
chunk_type: prose
tokens: 156
summary: "Schedule to run later"
---

## Schedule to run later

From a script or flow's page (after being [deployed](./meta-0_draft_and_deploy-index.md)), you can "Schedule to run later" to schedule the execution to a given time without being recurring, therefore executing only once.

Go the the script or flow's page, click on the `Advanced` button, fill in the date and time, choose to "Override Worker group tag", or pick a specific [worker group tag](./meta-9_worker_groups-index.md#set-tags-to-assign-specific-queues), and click on `Run`.

![Schedule to run later](./16_schedule_to_run_later.png 'Schedule to run later')

You can see the future runs in the [Runs menu](./meta-5_monitor_past_and_future_runs-index.md), with toggle 'Planned later'. You can find the created_at date when the run was scheduled on from the API [get job endpoint](https://app.windmill.dev/openapi.html#tag/job/GET/w/{workspace}/jobs_u/get/{id}) .

<!-- Resources -->

[flows]: ../../getting_started/6_flows_quickstart/index.mdx
[scripts]: ../../getting_started/0_scripts_quickstart/index.mdx
[apps]: ../../getting_started/7_apps_quickstart/index.mdx
