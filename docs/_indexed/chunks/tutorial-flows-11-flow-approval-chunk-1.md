---
doc_id: tutorial/flows/11-flow-approval
chunk_id: tutorial/flows/11-flow-approval#chunk-1
heading_path: ["Suspend & Approval / Prompts"]
chunk_type: prose
tokens: 410
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Suspend & Approval / Prompts

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

Flows can be suspended until resumed or canceled event(s) are received. This
feature is most useful for implementing approval steps.

![Approval step diagram](../assets/flows/approval_diagram.png 'Approval step diagram')

An approval step is a normal script with the **Suspend** option enabled in the step's advanced settings. This will suspend the execution of a flow until it has been approved through the resume endpoints or the approval page by and solely by the recipients of the secret URLs.

:::info Suspending a flow in Windmill

Other ways to pause a workflow include:

- [Early stop/Break](./concept-flows-2-early-stop.md): if defined, at the end of the step, the predicate expression will be evaluated to decide if the flow should stop early.
- [Sleep](./tutorial-flows-15-sleep.md): if defined, at the end of the step, the flow will sleep for a number of seconds before scheduling the next job (if any, no effect if the step is the last one).
- [Retry](./ops-flows-14-retries.md) a step a step until it comes successful.
- [Schedule the trigger](./meta-1_scheduling-index.md) of a script or flow.

:::

An event can be:

- a cancel
- a pre-set number of approval that is met.

The approval step generates a unique URL for each required approval using `wmill.getResumeUrls()` (or `wmill.get_resume_urls()` in [Python](./meta-2_python_quickstart-index.md)). The approval step works like a webhook mechanism - the flow remains suspended until the required number of approval events are received via HTTP requests to these generated URLs. Each approval event is an HTTP request to one of these URLs, which then resumes or cancels the flow execution.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="WindmillHub | Approval"
		description="Find a library of Approval scripts on WindmillHub."
		href="https://hub.windmill.dev/approvals"
		color="teal"
	/>
</div>

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	autoPlay
	controls
	id="main-video"
	src="/videos/flow-approval.mp4"
/>

<br />
