---
doc_id: concept/windmill/13-flow-branches
chunk_id: concept/windmill/13-flow-branches#chunk-4
heading_path: ["Branches", "Predicate expression"]
chunk_type: prose
tokens: 75
summary: "Predicate expression"
---

## Predicate expression

The predicate expression is the JavaScript expression that will be evaluated to determine if the branch should be executed. It can be simple `true`/`false` but also comparison operators (`results.c.command === 'email'`, `flow_input.number >= 2` etc.)

It can be set with a prompt using [Windmill AI](./meta-windmill-index-37.md):

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/branch_predicate_copilot.mp4"
/>
