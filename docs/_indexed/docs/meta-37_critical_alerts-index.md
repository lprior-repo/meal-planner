---
id: meta/37_critical_alerts/index
title: "Critical alerts"
category: meta
tags: ["meta", "37_critical_alerts", "critical"]
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

## Critical alert channels

You just need to [configure SMTP](./meta-18_instance_settings-index.md#smtp) and setup a critical alert channel (aka email address) in the [instance settings](./meta-18_instance_settings-index.md#smtp) and/or connect your instance to [Slack and Microsoft Teams](./meta-18_instance_settings-index.md#critical-alert-channels) and fill in a channel name.

![Critical alert channels Config](../../advanced/18_instance_settings/critical_alerts_channels.png "Critical alert channels Config")

You can also set an alert to receive notification when the number of running workers in a group falls below a given number. It's available in the [worker group config](./meta-9_worker_groups-index.md#alerts).

![Workers alerts Slack](../9_worker_groups/critical_alert_slack.png 'Workers alerts Slack')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Workers Alerts"
		description="Set an alert to receive notification when the number of running workers in a group falls below a given number."
		href="/docs/core_concepts/worker_groups#alerts"
	/>
</div>

## Critical alerts in UI

Windmill itself sends critical alerts notifications through the UI.

You can disable this in the [instance settings](./meta-18_instance_settings-index.md#mute-critical-alerts-in-ui).

![Critical alerts UI](./critical_alerts_ui.png "Critical alerts UI")

### Visibility

Instance wide Critical Alerts are only visible to users with the [superadmin](./meta-16_roles_and_permissions-index.md#superadmin) or [devops](./meta-16_roles_and_permissions-index.md#devops) roles. For workspace specifc alerts, users need to have admin privilege over that workspace.


## See Also

- [Enterprise Edition](/pricing)
- [job](../20_jobs/index.mdx)
- [Job](../20_jobs/index.mdx)
- [License key](../../misc/7_plans_details/index.mdx#using-the-license-key-self-host)
- [Workspace error handler](../10_error_handling/index.mdx#workspace-error-handler)
