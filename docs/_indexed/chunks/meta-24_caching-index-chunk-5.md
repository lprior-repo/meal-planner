---
doc_id: meta/24_caching/index
chunk_id: meta/24_caching/index#chunk-5
heading_path: ["Caching", "Cache app inline scripts"]
chunk_type: prose
tokens: 189
summary: "Cache app inline scripts"
---

## Cache app inline scripts

Caching an app inline script means caching the results of that script for a certain duration. If the script is triggered with the same inputs during the given duration, it will return the cached result.

<video
    className="border-2 rounded-xl object-cover w-full h-full"
    controls
    src="/videos/caching_app.mp4"
/>

<br/>

You can enable caching for an app inline script directly its editor settings. Here's how you can do it:

1. **Settings**: From the Code editor, go to the top bar and pick the `Cache` tab.
2. **Enable Caching**: To enable caching, toggle on "Cache the results for each possible inputs" and specify the desired duration for caching results (in seconds.)

In the above example, the result of step the script will be cached for 5 minutes. If `Inline Script 0` is re-triggered with the same input within this period, Windmill will immediately return the cached result.
