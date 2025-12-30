---
doc_id: meta/24_caching/index
chunk_id: meta/24_caching/index#chunk-4
heading_path: ["Caching", "Cache flow steps"]
chunk_type: prose
tokens: 235
summary: "Cache flow steps"
---

## Cache flow steps

Caching a flow step means caching the results of that step for a certain duration. If the step is triggered with the same inputs during the given duration, it will return the cached result.

<video
    className="border-2 rounded-xl object-cover w-full h-full"
    controls
    src="/videos/cache_for_steps.mp4"
/>

<br/>

You can enable caching for a step directly in the step configuration. Here's how you can do it:

1. **Select a step**: From the Flow editor, select the step for which you want to cache the results.

2. **Enable Caching**: To enable caching, navigate to the `Advanced` menu and select `Cache`. Toggle it on and specify the desired duration for caching results (in seconds.)

![Caching result example](../../assets/flows/cache_steps.gif)

In the above example, the result of step `a` will be cached for 86400 seconds (1 day). If `a` is re-triggered with the same input within this period, Windmill will immediately return the cached result.

:::tip Step mocking / Pin result

[Step mocking / Pin result](./concept-flows-5-step-mocking.md) allows faster iteration. When a step is mocked, it will immediately return the mocked value without performing any computation.

:::
