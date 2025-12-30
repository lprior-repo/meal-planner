---
doc_id: meta/24_caching/index
chunk_id: meta/24_caching/index#chunk-2
heading_path: ["Caching", "Cache scripts"]
chunk_type: prose
tokens: 180
summary: "Cache scripts"
---

## Cache scripts

Caching a script means caching the results of that script for a certain duration. If the script is triggered with the same inputs during the given duration, it will return the cached result.

<video
    className="border-2 rounded-xl object-cover w-full h-full"
    controls
    src="/videos/caching_script.mp4"
/>

<br/>

You can enable caching for a script directly in the script Settings. Here's how you can do it:

1. **Settings**: From the Script editor, pick the "Settings" menu an scroll to "Cache".

2. **Enable Caching**: To enable caching, toggle on "Cache the results for each possible inputs" and specify the desired duration for caching results (in seconds.)

In the above example, the result of step the script will be cached for 180 seconds (4 minutes). If `u/henri/slow_function___base_11` is re-triggered with the same input within this period, Windmill will immediately return the cached result.
