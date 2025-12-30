---
doc_id: tutorial/flows/11-flow-approval
chunk_id: tutorial/flows/11-flow-approval#chunk-3
heading_path: ["Suspend & Approval / Prompts", "Core"]
chunk_type: prose
tokens: 270
summary: "Core"
---

## Core

### Number of approvals/events required for resuming flow

The number of required approvals can be customized.
This allows flexibility and security for cases where you either require approvals from all authorized people or only from one.

**Important**: The flow will remain suspended and will not proceed to the next step until the exact number of required approval events is received. If fewer approvals than required are received, the flow stays suspended indefinitely (unless a timeout is configured).

![Required approvals](../assets/flows/flow-number-of-approvals.png 'Required approvals')

Note that approval steps can be applied the same configurations as regular steps ([Retries](./ops-flows-14-retries.md), [Early stop/Break](./concept-flows-2-early-stop.md) or [Suspend](./tutorial-flows-15-sleep.md)).

### Timeout

Set a custom timeout after which the flow will be automatically canceled if no approval is received.

![Approval Timeout](../assets/flows/approvals-timeout.png 'Approval Timeout')

### Continue on disapproval/timeout

If set, instead of failing the flow and bubbling up the error, continue to the next step which would allow to put a [branchone](./concept-flows-13-flow-branches.md) right after to handle both cases separately. If any disapproval/timeout event is received, the resume payload will be similar to every error result in Winmdill, an object containing an `error` field which you can use to distinguish between approvals and disapproval/timeouts.

![Continue on disapproval/timeout](../assets/flows/continue_on_disapproval.png 'Continue on disapproval/timeout')

<video
	className="border-2 rounded-lg object-cover w-full h-full"
	controls
	src="/videos/continue_on_disapproval.mp4"
/>
