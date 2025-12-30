---
doc_id: meta/1_scheduling/index
chunk_id: meta/1_scheduling/index#chunk-3
heading_path: ["Schedules", "Set a schedule"]
chunk_type: prose
tokens: 426
summary: "Set a schedule"
---

## Set a schedule

Scripts and flows can have unique [primary schedules](#primary-schedule) and multiple [other schedules](#other-schedules).

### Primary schedule

Each script and flow can have a primary schedule that can be configured from the script or flow settings.

There can only be one primary schedule per script or flow.

From the script [settings](./tutorial-script_editor-settings.md), toggle on 'Schedule enabled' and [Deploy](./meta-0_draft_and_deploy-index.md) the script.

![Primary schedule](./primary_schedule.png 'Primary schedule')

### Other schedules

From your workspace, navigate to the dedicated `Schedules` menu and select `New Schedule`. You can also do that in the Other schedules section of a script.

There can be multiple other schedules per script.

![Schedules menu](./6-schedules-menu.png.webp 'Schedules menu')

1. Configure the schedule frequency using cron syntax, the simplified builder or a prompt with [Windmill AI](./meta-22_ai_generation-index.md).

2. Select a runnable ([script][scripts] or [flow][flows]) from your workspace.

3. Fill in the arguments that will be used for the automation. The arguments are the ones of the given script or flow. If you want your arguments to be dynamic, you might want to use a [workflow][flows].

4. Optional: Add an [Error handler](#schedule-error-handler).

5. Optional: Add a [Recovery Handler](#schedule-recovery-handler).

Note that modifying a script or flow that was previously scheduled will not un-schedule it and the said script or flow will run on its modified version after [deployment](./meta-0_draft_and_deploy-index.md).

![Schedule a task](./12-schedule-a-task.png.webp 'Schedule a task')

Click the `Schedule` button and you're good to go! The schedule will be automatically 'Enabled'. Toggle it off if needed.

![Scheduled task](./13-scheduled-script.png.webp 'Scheduled task')

:::tip Handle Several Schedules for the Same Workflow

The previous configuration can be replicated multiple times for the same workflow and therefore several schedules can work in parallel.

:::

If the Schedules menu allows you to control future executions of scripts and workflows, you can check all past and future runs clicking on `Runs`. This will lead you to the [Runs menu](./meta-5_monitor_past_and_future_runs-index.md), with a filtered view on your runnable.

![Runs menu](./10-runs-menu.png.webp 'Runs menu')

... where you can get details on each run:

![Run details](./11-run-details.png.webp 'Run details')
