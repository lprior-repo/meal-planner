---
doc_id: tutorial/windmill/script-kinds
chunk_id: tutorial/windmill/script-kinds#chunk-4
heading_path: ["Script kind", "Approval scripts"]
chunk_type: prose
tokens: 107
summary: "Approval scripts"
---

## Approval scripts

Suspend a flow until it's approved. An Approval Script will interact with the Windmill API using any of the Windmill clients to retrieve a secret approval URL and resume/cancel endpoints. Most common scenario for Approval scripts is to send an external notification with an URL that can be used to resume or cancel a flow.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Suspend & Approval / Prompts"
		description="Flows can be suspended until resumed or canceled event(s) are received."
		href="/docs/flows/flow_approval"
	/>
</div>
