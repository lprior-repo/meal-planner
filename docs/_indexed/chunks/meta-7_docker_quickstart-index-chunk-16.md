---
doc_id: meta/7_docker_quickstart/index
chunk_id: meta/7_docker_quickstart/index#chunk-16
heading_path: ["Docker quickstart", "if using the 'docker' mode, name it with $WM_JOB_ID for windmill to monitor it"]
chunk_type: code
tokens: 291
summary: "if using the 'docker' mode, name it with $WM_JOB_ID for windmill to monitor it"
---

## if using the 'docker' mode, name it with $WM_JOB_ID for windmill to monitor it
docker run --name $WM_JOB_ID -it -d $IMAGE $COMMAND
```

`msg` is just a normal Bash variable. It can be used to pass arguments to the script. This syntax is the standard Bash one to assign default values to parameters.

```
docker run --name $WM_JOB_ID -it -d $IMAGE $COMMAND
```

Windmill has a native docker support if the `# docker` annotation is used. It will assume a a docker socket is mounted like in the example above and will take over management of the container as soon as the script ends, assuming that the container was ran with the `$WM_JOB_ID` as name.
Which is why you should use docker `-d` deamon mode so that the bash script terminates early.

### Instant preview & testing

Look at the UI preview on the right: it was updated to match the input
signature. Run a test (`Ctrl` + `Enter`) to verify everything works.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/auto_g_ui_landing.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Instant preview & testing"
		description="On top of its integrated editors, Windmill allows users to see and test what they are building directly from the editor, even before deployment."
		href="/docs/core_concepts/instant_preview"
	/>
</div>

Now let's go to the last step: the "Generated UI" settings.
