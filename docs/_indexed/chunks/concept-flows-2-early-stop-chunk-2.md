---
doc_id: concept/flows/2-early-stop
chunk_id: concept/flows/2-early-stop#chunk-2
heading_path: ["Early stop / Break", "Early stop for step"]
chunk_type: prose
tokens: 191
summary: "Early stop for step"
---

## Early stop for step

For each step of the flow, an early stop can be defined. The result of the step will be compared to a previously defined predicate expression, and if the condition is met, the flow will stop after that step.

<video
    className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
    controls
    src="/videos/early_stop.mp4"
/>

<br/>

- Pick the step you want to stop after.

- Go to `Advanced`, then `Early stop/Break`.

- Toggle on "Early stop or Break if condition met".

- Write the condition you want to stop on, based on the step's results.

- Optionally, toggle on "Label flow as "skipped" if stopped". Skipped flows are just a label useful to not see them in the [runs](./meta-5_monitor_past_and_future_runs-index.md) page.

If stop early is run within a forloop, it will just break the for-loop and have it stop at that iteration instead of stopping the whole flow.
