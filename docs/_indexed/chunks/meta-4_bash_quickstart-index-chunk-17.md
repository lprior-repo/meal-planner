---
doc_id: meta/4_bash_quickstart/index
chunk_id: meta/4_bash_quickstart/index#chunk-17
heading_path: ["TypeScript quickstart", "Run Docker containers"]
chunk_type: prose
tokens: 145
summary: "Run Docker containers"
---

## Run Docker containers

In some cases where your task requires a complex set of dependencies or is implemented in a non-supported language, you can still include it as a flow step or individual script.

Windmill supports running any docker container through its Bash support. As a pre-requisite, the host docker daemon needs to be mounted into the worker container. This is done through a simple volume mount: `/var/run/docker.sock:/var/run/docker.sock`.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Run Docker containers"
		description="In some cases where your task requires a complex set of dependencies or is implemented in a non-supported language, you can still include it as a flow step or individual script."
		href="/docs/advanced/docker"
	/>
</div>
