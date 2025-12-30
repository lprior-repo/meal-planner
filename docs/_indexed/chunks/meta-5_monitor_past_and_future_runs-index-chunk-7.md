---
doc_id: meta/5_monitor_past_and_future_runs/index
chunk_id: meta/5_monitor_past_and_future_runs/index#chunk-7
heading_path: ["Jobs runs", "Batch actions"]
chunk_type: prose
tokens: 292
summary: "Batch actions"
---

## Batch actions

You can cancel or re-run multiple job runs at once. You can manually select them, or you can cancel or re-run all jobs matching current filters if you are admin.

When re-running jobs, you can set their inputs statically or with a JavaScript expression. By default, jobs re-run with the same arguments.
You may choose to re-run the job on their original script version or the latest one. Flows can only run on their latest version.

In the example below, we choose to re-run the job on the latest version of the script. We use the original bannedAt value when available, but bannedAt was not defined in older versions, so we fallback to the job original scheduled date. We also transform the username by adding a `@` prefix.

![Batch re-run Example](./batch-reruns-example.png 'Batch re-run Example')

Multiple jobs may have run different versions of a script, which may have different schemas. Checking for the script hash narrows the type of the input, which allows the linter to show you the correct input type depending on the script version. Windmill will automatically generate code like this by default:

```js
// 'a' has different types depending on the script version
if (job.script_hash === 'edaf364678e4672a') {
	job.input.a // 'a' is a boolean
} else if (job.script_hash === '1df16d1abdd02f6b') {
	job.input.a // 'a' is a number
}
```
