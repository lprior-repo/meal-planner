---
doc_id: tutorial/script_editor/script-kinds
chunk_id: tutorial/script_editor/script-kinds#chunk-3
heading_path: ["Script kind", "Trigger scripts"]
chunk_type: prose
tokens: 141
summary: "Trigger scripts"
---

## Trigger scripts

These are used as the first step in flows, most commonly with an internal state and a schedule to watch for changes on a external system, and compare it to the previously saved state. If there are changes,it _triggers_ the rest of the flow, i.e. subsequent Scripts.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Trigger scripts"
		description="Trigger scripts are designed to pull data from an external source and return all of the new items since the last run, without resorting to external webhooks."
		href="/docs/flows/flow_trigger"
	/>
	<DocCard
		title="Schedules"
		description="Windmill provides the same set of features as CRON, but with a user interface and control panels."
		href="/docs/core_concepts/scheduling"
	/>
</div>
