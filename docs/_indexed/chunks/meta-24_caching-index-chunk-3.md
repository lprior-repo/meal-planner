---
doc_id: meta/24_caching/index
chunk_id: meta/24_caching/index#chunk-3
heading_path: ["Caching", "Cache flows"]
chunk_type: prose
tokens: 182
summary: "Cache flows"
---

## Cache flows

Caching a flow means caching the results of that flow for a certain duration. If the flow is triggered with the same flow inputs during the given duration, it will return the cached result.

<video
    className="border-2 rounded-xl object-cover w-full h-full"
    controls
    src="/videos/caching_flow.mp4"
/>

<br/>

You can enable caching for a flow directly in the flow settings. Here's how you can do it:

1. **Settings**: From the Flow editor, go to the "Settings" menu and pick the `Cache` tab.
2. **Enable Caching**: To enable caching, toggle on "Cache the results for each possible inputs" and specify the desired duration for caching results (in seconds.)

In the above example, the result of step the flow will be cached for 60 seconds. If `u/henri/example_flow_quickstart_no_slack` is re-triggered with the same input within this period, Windmill will immediately return the cached result.
