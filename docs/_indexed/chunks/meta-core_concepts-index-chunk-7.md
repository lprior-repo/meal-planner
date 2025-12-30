---
doc_id: meta/core_concepts/index
chunk_id: meta/core_concepts/index#chunk-7
heading_path: ["Core concepts", "Flow-specific features"]
chunk_type: prose
tokens: 508
summary: "Flow-specific features"
---

## Flow-specific features

All details on Flows can be found in the [Flows section](./tutorial-flows-1-flow-editor.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Triggering flows"
		description="Trigger scripts and flows on-demand, by schedule or on external events."
		href="/docs/getting_started/triggers"
	/>
	<DocCard
		color="teal"
		title="Testing flows"
		description="Iterate quickly and get control on your flow testing."
		href="/docs/flows/test_flows"
	/>
	<DocCard
		color="teal"
		title="AI-generated flows"
		description="Generate flows from prompts."
		href="/docs/flows/ai_flows"
	/>
	<DocCard
		color="teal"
		title="Branches"
		description="Split the execution of the flow based on a condition."
		href="/docs/flows/flow_branches"
	/>
	<DocCard
		color="teal"
		title="For loops"
		description="Iterate a series of tasks."
		href="/docs/flows/flow_loops"
	/>
	<DocCard
		color="teal"
		title="While loops"
		description="While loops execute a sequence of code indefinitely until the user cancels or a step set to Early stop stops."
		href="/docs/flows/while_loops"
	/>
	<DocCard
		color="teal"
		title="Error handler"
		description="Configure a script to handle errors."
		href="/docs/flows/flow_error_handler"
	/>
	<DocCard
		color="teal"
		title="Trigger scripts"
		description="Trigger scripts are designed to pull data from an external source and return all of the new items since the last run, without resorting to external webhooks."
		href="/docs/flows/flow_trigger"
	/>
	<DocCard
		color="teal"
		title="Retries"
		description="Re-try a step in case of error."
		href="/docs/flows/retries"
	/>
	<DocCard
		color="teal"
		title="Concurrency limits"
		description="The Concurrency limit feature allows you to define concurrency limits for scripts and inline scripts within flows."
		href="/docs/flows/concurrency_limit"
	/>
	<DocCard
		color="teal"
		title="Custom timeout for step"
		description="If the execution takes longer than the time limit, the execution of the step will be interrupted."
		href="/docs/flows/early_stop"
	/>
	<DocCard
		color="teal"
		title="Priority for steps"
		description="Prioritize a flow step in the execution queue."
		href="/docs/flows/priority"
	/>
	<DocCard
		color="teal"
		title="Lifetime / Delete after use"
		description="The logs, arguments and results of this flow step will be completely deleted from Windmill once the flow is complete."
		href="/docs/flows/lifetime"
	/>
	<DocCard
		color="teal"
		title="Cache for steps"
		description="Re-use a step's previous results."
		href="/docs/flows/cache"
	/>
	<DocCard
		color="teal"
		title="Early stop / Break"
		description="Stop early a flow based on a step's result."
		href="/docs/flows/early_stop"
	/>
	<DocCard
		color="teal"
		title="Early return"
		description="Define a node at which the flow will return at for sync endpoints. The rest of the flow will continue asynchronously."
		href="/docs/flows/early_return"
	/>
	<DocCard
		color="teal"
		title="Suspend & Approval / Prompts"
		description="Suspend a flow until specific event(s) are received, such as approvals or cancellations."
		href="/docs/flows/flow_approval"
	/>
	<DocCard
		color="teal"
		title="Sleep / Delays in flows"
		description="Executions within a flow can be suspended for a given time."
		href="/docs/flows/sleep"
	/>
	<DocCard
		color="teal"
		title="Step mocking / Pin result"
		description="When a step is mocked, it will immediately return the mocked value without performing any computation."
		href="/docs/flows/step_mocking"
	/>
</div>

<div className="grid grid-cols-2 gap-6 mb-4"></div>
