---
doc_id: ref/windmill/23-job-debouncing
chunk_id: ref/windmill/23-job-debouncing#chunk-1
heading_path: ["Job debouncing"]
chunk_type: prose
tokens: 175
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Job debouncing

> **Context**: import DocCard from '@site/src/components/DocCard';

Job debouncing prevents redundant job executions by canceling pending jobs with identical characteristics when new ones are submitted within a specified time window. This feature helps optimize resource usage and prevents unnecessary duplicate computations.

Job debouncing is a [Cloud plans and Pro Enterprise Self-Hosted](/pricing) only.

Debouncing can be set from the Settings menu. When jobs with matching characteristics are submitted within the debounce window, pending jobs are automatically canceled in favor of the newest one.

The Job debouncing operates globally and across flow runs. It involves two key parameters:
- [Debounce delay in seconds](./meta-windmill-index-38.md#debounce-delay-in-seconds)
- [Custom debounce key](./meta-windmill-index-38.md#custom-debounce-key)

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Job debouncing"
		description="Job debouncing prevents redundant job executions by canceling pending jobs with identical characteristics."
		href="/docs/core_concepts/job_debouncing"
	/>
</div>
