---
doc_id: meta/14_audit_logs/index
chunk_id: meta/14_audit_logs/index#chunk-1
heading_path: ["Audit logs"]
chunk_type: prose
tokens: 171
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Audit logs

> **Context**: import DocCard from '@site/src/components/DocCard';

Windmill provides audit logs for every operation and action that has side-effects. These logs capture the user responsible for the operation and include metadata specific to the type of operation.

As a user, you can only see your own audit logs unless you are an admin.

Audit logs can be filtered by Date, Username, Action (Create, Update, Delete, Execute), and specific Operation. The [Runs menu](./meta-5_monitor_past_and_future_runs-index.md) is another feature that allows you to visualise all past and future runs.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	autoPlay
	controls
	id="main-video"
	src="/videos/audit_logs.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Runs Menu"
		description="The Runs menu is another feature that allows you to visualise all past and future runs."
		href="/docs/core_concepts/monitor_past_and_future_runs"
	/>
</div>
