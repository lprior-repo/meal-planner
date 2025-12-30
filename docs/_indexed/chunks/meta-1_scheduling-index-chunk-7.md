---
doc_id: meta/1_scheduling/index
chunk_id: meta/1_scheduling/index#chunk-7
heading_path: ["Schedules", "Control permissions and errors"]
chunk_type: prose
tokens: 833
summary: "Control permissions and errors"
---

## Control permissions and errors

### Schedule error handler

From the schedule configuration, add a special script or flow to execute in case of an error.

![Schedule Error handler](./14_schedule_error_handler.png.webp)

For example, this can be a script that sends an error notification to [Slack](https://hub.windmill.dev/scripts/slack/1284/), [Microsoft Teams](../../integrations/teams.mdx), or [Discord](https://hub.windmill.dev/scripts/discord/1292/).

You can pick the Slack or Microsoft Teams pre-set schedule error handler.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/schedule_error_handler.mp4"
/>

<br/>

Schedule Error hander is an [Enterprise Edition](/pricing) feature.

### Schedule recovery handler

From the schedule configuration, add a special script or flow to execute in case of of recovery from Error.

You can pick the Slack or Microsoft Teams pre-set schedule recovery handler.

![Schedule Recovery Handler](./15_schedule_recovery_handler.png.webp)

### Dynamic skip validation

Schedules can use a validation script to determine whether a scheduled run should execute. The validator receives the scheduled datetime and returns a boolean indicating whether to proceed.

The dynamic skip handler is useful for:
- Skipping runs on weekends, holidays, or specific dates
- Checking external conditions before execution (e.g., API availability, data freshness)
- Implementing custom scheduling logic beyond standard cron expressions

#### How it works

1. Configure a schedule with a dynamic skip handler script
2. Before the scheduled job executes, Windmill runs the handler script
3. The handler receives `scheduled_for` (ISO 8601 datetime string) as a parameter
4. If the handler returns `true`, the scheduled job executes normally
5. If the handler returns any other value, the job is skipped (marked as success with `skipped` flag)
6. If the handler throws an exception, normal error handling applies and the job fails

#### Example handler

```typescript
export async function main(scheduled_for: string): Promise<boolean> {
  const date = new Date(scheduled_for);
  const dayOfWeek = date.getUTCDay();

  // Skip on weekends (0 = Sunday, 6 = Saturday)
  if (dayOfWeek === 0 || dayOfWeek === 6) {
    return false;
  }

  // Check if it's a holiday (example: checking external API)
  const isHoliday = await checkHolidayAPI(date);
  return !isHoliday;
}
```

From the schedule configuration, select your validation script in the "Dynamic skip" section.

![Dynamic skip configuration](./dynamic_skip.png 'Dynamic skip configuration')

:::info

If the validation handler script is deleted or archived after the schedule is created, the schedule will fail at runtime with a clear error message indicating the handler script was not found.

:::

### Be notified every time a scheduled workflow has been executed

For scheduled flows, add a simple step to be notified about the execution of the scheduled flow.

In this example I chose to [receive an email](https://hub.windmill.dev/scripts/gmail/1291/), but you can use other notification methods like [Slack](https://hub.windmill.dev/scripts/slack/1284/), [Microsoft Teams](../../integrations/teams.mdx), [Discord](https://hub.windmill.dev/scripts/discord/1292/) or any other other method your imagination and API calls can create.

![Add an email step](./7-add-email-step.png.webp 'Add an email step')

<br />

Configure the email.

![Configure email](./8-configure-email.png.webp 'Configure email')

<br />

And watch your mailbox.

![Receive the email](./9-receive-email.png 'Receive the email')

<br />

Given how [flows][flows] work on Windmill, it means that once the previous step has been successful, the Email step will trigger.

:::tip Error handler

If you want to handle failure and receive another message in that case, add an [Error handler](./tutorial-flows-7-flow-error-handler.md) to your workflow that will let you know if a failure happened at any step.

:::

### Manage permissions from the workflow

From the settings menu, change the owner to a [folder](./meta-8_groups_and_folders-index.md#folders) (group of people) to manage view and editing rights.

![Manage permissions](./5-manage-rights.png.webp 'Manage permissions')

<br />

The process is very simple but it will allow you to schedule tasks with confidence and get an aggregated view on them.

Not only can you build scheduled jobs [from Windmill](./meta-00_how_to_use_windmill-index.md) but also you can import all your existing scripts - as Windmill supports TypeScript, Python, Go, PHP, Bash or SQL - [as did one of our esteemed users](/blog/stantt-case-study) for their own scheduled [jobs](./meta-20_jobs-index.md).

### Failure to re-schedule

If a scheduled job fails to re-schedule, it will trigger a [workspace error handler](./meta-10_error_handling-index.md#workspace-error-handler).
