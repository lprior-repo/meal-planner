---
doc_id: concept/flows/8-error-handling
chunk_id: concept/flows/8-error-handling#chunk-3
heading_path: ["Error handling in flows", "Retries"]
chunk_type: prose
tokens: 94
summary: "Retries"
---

## Retries

Steps within a flow can be retried a specified number of times and at a defined frequency in case of an error.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/retries_example.mp4"
/>

<br />

> Example of a flow step giving error if random number = 0 and re-trying 5 times

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Retries"
		description="Re-try a step in case of error."
		href="/docs/flows/retries"
	/>
</div>
