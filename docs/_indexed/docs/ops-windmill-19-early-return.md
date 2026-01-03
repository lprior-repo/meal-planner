---
id: ops/windmill/19-early-return
title: "Early return"
category: ops
tags: ["windmill", "operations", "early"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Early return</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.962895</created_at>
  <updated_at>2026-01-02T19:55:27.962895</updated_at>
  <language>en</language>
  <dependencies>
    <dependency type="feature">meta/windmill/index-68</dependency>
    <dependency type="feature">meta/windmill/index-23</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../core_concepts/4_webhooks/index.mdx</entity>
    <entity relationship="uses">../assets/flows/set_early_return.png.webp &apos;Set early return&apos;</entity>
    <entity relationship="uses">../core_concepts/0_draft_and_deploy/index.mdx</entity>
    <entity relationship="uses">../assets/flows/early_webooks.png.webp &apos;Early webhooks&apos;</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>windmill,operations,early</tags>
</doc_metadata>
-->

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


## See Also

- [sync endpoints](../core_concepts/4_webhooks/index.mdx#synchronous)
- [Set early return](../assets/flows/set_early_return.png.webp 'Set early return')
- [deployed](../core_concepts/0_draft_and_deploy/index.mdx)
- [Early webhooks](../assets/flows/early_webooks.png.webp 'Early webhooks')
