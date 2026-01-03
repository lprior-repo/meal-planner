---
doc_id: tutorial/windmill/4-cache
chunk_id: tutorial/windmill/4-cache#chunk-1
heading_path: ["Caching"]
chunk_type: prose
tokens: 193
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Caching

> **Context**: import DocCard from '@site/src/components/DocCard';

Caching is used to cache the results of a script, flow, flow step or app inline scripts for a specified number of seconds, thereby reducing the need for redundant computations when re-running the same step with identical input.

When you configure caching, Windmill stores the result in a cache for the duration you specify. If the same runnable is re-triggered with the same input within this duration, Windmill instantly retrieves the cached result instead of re-computing it.

This feature can significantly improve the performance of your scripts & flows, especially for steps that are computationally demanding or dependent on external resources, such as APIs or databases.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Caching"
		description="Caching is used to cache the results of a script, flow or flow step for a specified number of seconds."
		href="/docs/core_concepts/caching"
	/>
</div>
