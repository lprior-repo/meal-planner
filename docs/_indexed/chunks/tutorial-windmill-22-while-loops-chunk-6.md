---
doc_id: tutorial/windmill/22-while-loops
chunk_id: tutorial/windmill/22-while-loops#chunk-6
heading_path: ["While loops", "Advanced settings"]
chunk_type: prose
tokens: 292
summary: "Advanced settings"
---

## Advanced settings

### Early stop / Break

See [above](#early-stop--break).

### Suspend/Approval/Prompt

Flows can be suspended until resumed or canceled event(s) are received. This feature is most useful for implementing approval steps but can be used for other purposes as well.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Suspend & Approval / Prompts"
		description="Suspend a flow until specific event(s) are received, such as approvals or cancellations."
		href="/docs/flows/flow_approval"
	/>
</div>

### Sleep

Executions within a flow can be suspended for a given time.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Sleep / Delays in flows"
		description="Executions within a flow can be suspended for a given time."
		href="/docs/flows/sleep"
	/>
</div>

### Mock

Step mocking / Pin result allows faster iteration while building flows. When a step is mocked, it will immediately return the mocked value without performing any computation.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Step mocking / Pin result"
		description="When a step is mocked, it will immediately return the mocked value without performing any computation."
		href="/docs/flows/step_mocking"
	/>
</div>

### Lifetime

The logs, arguments and results of this flow step will be completely deleted from Windmill once the flow is complete.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Lifetime / Delete after use"
		description="The logs, arguments and results of this flow step will be completely deleted from Windmill once the flow is complete."
		href="/docs/flows/lifetime"
	/>
</div>
