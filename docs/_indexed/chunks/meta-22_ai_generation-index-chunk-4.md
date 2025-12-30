---
doc_id: meta/22_ai_generation/index
chunk_id: meta/22_ai_generation/index#chunk-4
heading_path: ["Windmill AI", "Windmill AI for flows"]
chunk_type: prose
tokens: 414
summary: "Windmill AI for flows"
---

## Windmill AI for flows

### AI Flow Chat

The [flow editor](./tutorial-flows-1-flow-editor.md) includes an integrated AI chat panel that lets you create and modify flows using natural language. 
Just describe what you want to achieve, and the AI will build the flow for you, step by step.

It can add scripts, [loops](./tutorial-flows-12-flow-loops.md), and [branches](./concept-flows-13-flow-branches.md), searching your workspace and [Windmill Hub](https://hub.windmill.dev/) for relevant scripts or generating new ones when needed or on request.
It automatically sets up flow inputs and connects steps by filling in parameters based on context.
For loops and branches, the AI sets suitable iterator expressions and predicates based on your flow's data.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/L7JPHDtbSNM"
	title="AI Flow Chat"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

### Script mode in AI Flow Chat

If you're working on an inline script in your flow, you can switch to script mode using the toggle to access the same AI assistance as in the script editor — including the ability to add context like database schemas, diffs, and preview errors, along with granular apply/reject controls and quick actions.

### Summary copilot for steps

From your code, the AI assistant can generate a summary for flow steps.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/summary_copilot_steps.mp4"
/>

### Step input copilot

When adding a new step to a flow, the AI assistant will suggest inputs based on the previous steps' results and flow inputs.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/step_input_copilot.mp4"
/>

### Flow loops iterator expressions from context

When adding a [for loop](./tutorial-flows-12-flow-loops.md), the AI assistant will suggest iterator expressions based on the previous steps' results.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/iterator_prefill.mp4"
/>

### Flow branches predicate expressions from prompts

When adding a [branch](./concept-flows-13-flow-branches.md), the AI assistant will suggest predicate expressions from a prompt.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/branch_predicate_copilot.mp4"
/>
