---
doc_id: ref/windmill/6-concurrency-limit
chunk_id: ref/windmill/6-concurrency-limit#chunk-1
heading_path: ["Concurrency limits"]
chunk_type: prose
tokens: 204
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Concurrency limits

> **Context**: import DocCard from '@site/src/components/DocCard';

The Concurrency limits feature allows you to define concurrency limits for scripts, flows and inline scripts within flows. Its primary goal is to prevent exceeding the API Limit of the targeted API, eliminating the need for complex workarounds using worker groups.

Concurrency limit is a [Cloud plans and Pro Enterprise Self-Hosted](/pricing) only.

Concurrency limit can be set from the Settings menu. When jobs reach the concurrency limit, they are automatically queued for execution at the next available optimal slot given the time window.

The Concurrency limit operates globally and across flow runs. It involves three key parameters:
- [Max number of executions within the time window](./meta-windmill-index-36.md#max-number-of-executions-within-the-time-window)
- [Time window in seconds](./meta-windmill-index-36.md#time-window-in-seconds)
- [Custom concurrency key](./meta-windmill-index-36.md#custom-concurrency-key)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Concurrency limits"
		description="The Concurrency limits feature allows you to define concurrency limits for scripts, flows and inline scripts within flows."
		href="/docs/core_concepts/concurrency_limits"
	/>
</div>
