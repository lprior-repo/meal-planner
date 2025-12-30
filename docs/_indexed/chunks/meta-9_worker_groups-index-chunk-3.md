---
doc_id: meta/9_worker_groups/index
chunk_id: meta/9_worker_groups/index#chunk-3
heading_path: ["Workers and worker groups", "Alerts"]
chunk_type: prose
tokens: 145
summary: "Alerts"
---

## Alerts

You can set an alert to receive notification via Email, Slack, or Microsoft Teams when the number of running workers in a group falls below a given number. It's available in the worker group config.

![Workers alerts Slack](./critical_alert_slack.png 'Workers alerts Slack')

Enable 'Send an alert when the number of alive workers falls below a given threshold', and enter a number of workers below which the notification will be sent.

You need to configure [Critical alert channels](./meta-37_critical_alerts-index.md) to receive notifications.

![Workers alerts](./workers_alerts.png 'Workers alerts')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Critical alerts"
		description="Get a notification for critical events such as everytime a job is re-run after a crash."
		href="/docs/core_concepts/critical_alerts"
	/>
</div>
