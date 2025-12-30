---
doc_id: meta/37_critical_alerts/index
chunk_id: meta/37_critical_alerts/index#chunk-2
heading_path: ["Critical alerts", "Critical alert channels"]
chunk_type: prose
tokens: 146
summary: "Critical alert channels"
---

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
