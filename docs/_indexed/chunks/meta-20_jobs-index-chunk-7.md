---
doc_id: meta/20_jobs/index
chunk_id: meta/20_jobs/index#chunk-7
heading_path: ["Jobs", "Retention policy"]
chunk_type: prose
tokens: 153
summary: "Retention policy"
---

## Retention policy

The retention policy for jobs runs details varies depending on your team's [plan](/pricing):

- Community plan (cloud): Jobs runs details are retained for 60 days.
- Team plan (cloud): Jobs runs details are retained for 60 days.
- Enterprise plan (cloud): Unlimited retention period.
- Open Source (self-host): Jobs runs details are retained for maximum 30 days.
- Enterprise plan (self-host): Unlimited retention period.

You can set a custom retention period for the jobs runs details. The retention period can be configured in the [instance settings](./meta-18_instance_settings-index.md#retention-period-in-secs), in the "Core" tab.

![Set Retention Period](./set_retention_policy.png 'Set Retention Period')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Plans & How to Upgrade"
		description="Details on each Windmill Plan"
		href="/pricing"
	/>
</div>
