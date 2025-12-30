---
doc_id: meta/1_scheduling/index
chunk_id: meta/1_scheduling/index#chunk-4
heading_path: ["Schedules", "Configure schedules from flow editor"]
chunk_type: prose
tokens: 156
summary: "Configure schedules from flow editor"
---

## Configure schedules from flow editor

The same method can also be done from the [flow editor](./meta-6_flows_quickstart-index.md).

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/schedule-cron.mp4"
/>

<br />

From your workspace, pick the workflow you want to schedule.

![Go to workflow](./1-from-workspace.png.webp 'Go to workflow')

Go to the `Schedule` menu ...

![Pick Schedule menu](./2-schedule-menu.png.webp 'Pick Schedule menu')

and either schedule in [cron](https://crontab.guru) or in Basic mode that will automatically be translated in cron. Once it's done, you can see in next picture that the cron expression is now visible on the toolbar.

![Basic or cron schedule](./3-basic-schedule.png.webp 'Basic or cron schedule')

Fill in the inputs, toggle the Schedule Enabled option, save, and you're all set!

![Save and schedule](./4-inputs-toggle.png 'Save and schedule')
