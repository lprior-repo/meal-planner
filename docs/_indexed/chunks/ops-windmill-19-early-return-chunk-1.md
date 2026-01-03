---
doc_id: ops/windmill/19-early-return
chunk_id: ops/windmill/19-early-return#chunk-1
heading_path: ["Early return"]
chunk_type: prose
tokens: 143
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Early return

> **Context**: import DocCard from '@site/src/components/DocCard';

It is possible to define a node at which the flow will return at for [sync endpoints](./meta-windmill-index-68.md#synchronous). The rest of the flow will continue asynchronously.

Useful when some webhooks need to return extremely fast but not just the uuid (define first step as early return) or when the expected return from the webhook doesn't need to the full flow being computed.

![Set early return](../assets/flows/set_early_return.png.webp 'Set early return')

Webooks can be found on the flow page once [deployed](./meta-windmill-index-23.md).

![Early webhooks](../assets/flows/early_webooks.png.webp 'Early webhooks')

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Webhooks"
		description="Trigger scripts and flows from webhooks."
		href="/docs/core_concepts/webhooks"
	/>
</div>
