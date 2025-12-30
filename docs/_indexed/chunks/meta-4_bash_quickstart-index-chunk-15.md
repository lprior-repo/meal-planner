---
doc_id: meta/4_bash_quickstart/index
chunk_id: meta/4_bash_quickstart/index#chunk-15
heading_path: ["TypeScript quickstart", "Run!"]
chunk_type: prose
tokens: 161
summary: "Run!"
---

## Run!

We're done! Now let's look at what users of the script will do. Click on the [Deploy](./meta-0_draft_and_deploy-index.md) button
to load the script. You'll see the user input form we defined earlier.

Note that Scripts are [versioned](./meta-34_versioning-index.md#script-versioning) in Windmill, and
each script version is uniquely identified by a hash.

Fill in the input field, then hit "Run". You should see a run view, as well as
your logs. All script runs are also available in the [Runs](./meta-5_monitor_past_and_future_runs-index.md) menu on
the left.

![Run Hello in Bash](./run_bash.png.webp)

You can also choose to [run the script from the CLI](./meta-3_cli-index.md) with the pre-made Command-line interface call.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Triggers"
		description="Trigger scripts and flows on-demand, by schedule or on external events."
		href="/docs/getting_started/triggers"
	/>
</div>
