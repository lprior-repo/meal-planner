---
doc_id: meta/5_monitor_past_and_future_runs/index
chunk_id: meta/5_monitor_past_and_future_runs/index#chunk-2
heading_path: ["Jobs runs", "Aggregated view"]
chunk_type: prose
tokens: 153
summary: "Aggregated view"
---

## Aggregated view

The Runs menu in each workspace provides a time series view where you can monitor different time slots.
The green (respectively, red) dots being the tasks that succeeded (respectively, failed).

You can filter the view per datetime, toggle "CRON schedules" to disable the display of past [scheduled](./meta-1_scheduling-index.md) jobs and "Planned later" to disable the display of [schedules](./meta-1_scheduling-index.md) planned for later.

![Time series](./1-runs-menu.png 'Time series')

> All past and future runs of the workspace are visible from the menu.

<br/>

The graph can represent jobs on their Duration (default) or by Concurrency, meaning the number of concurrent jobs at a given time.

![Aggregated view by concurrency](aggregated_concurrency.png "Aggregated view by concurrency")

> Graphical view by concurrent jobs.
