---
doc_id: meta/7_docker_quickstart/index
chunk_id: meta/7_docker_quickstart/index#chunk-8
heading_path: ["Docker quickstart", "if using the 'docker' mode, name it with $WM_JOB_ID for windmill to monitor it"]
chunk_type: prose
tokens: 83
summary: "if using the 'docker' mode, name it with $WM_JOB_ID for windmill to monitor it"
---

## if using the 'docker' mode, name it with $WM_JOB_ID for windmill to monitor it
docker run --name $WM_JOB_ID -it -d $IMAGE $COMMAND
```

To see more details about to setup your kubernetes or docker-compose setup to run docker containers, see [Run docker containers](./meta-7_docker-index.md)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Run docker containers"
		description="Setup kubernetes or docker-compose to run docker containers"
		href="/docs/advanced/docker"
	/>
</div>
