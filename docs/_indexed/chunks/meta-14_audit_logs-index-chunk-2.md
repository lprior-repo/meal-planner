---
doc_id: meta/14_audit_logs/index
chunk_id: meta/14_audit_logs/index#chunk-2
heading_path: ["Audit logs", "Retention policy"]
chunk_type: prose
tokens: 148
summary: "Retention policy"
---

## Retention policy

For self-hosted Windmill instances, you can set the retention period via [instance settings](./meta-18_instance_settings-index.md#retention-period-in-secs), accessible in the top right corner of the workspace settings. Instance settings are accessible only to [superadmins](./meta-16_roles_and_permissions-index.md#superadmin). Audit logs are maintained in Postgres and output to the FileSystem as logs.

On Windmill's cloud service, audit log retention varies by plan:

- Community plan: Audit logs are redacted.
- Team plan (cloud): Retained for 7 days.
- Enterprise plan (cloud): Kept for 60 days, with logs stored in Postgres and the cloud for up to a year, extendable upon request.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Plans & How to Upgrade"
		description="Details on each Windmill Plan"
		href="/pricing"
	/>
</div>
