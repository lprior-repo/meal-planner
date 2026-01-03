---
id: ops/windmill/cli-sync
title: "CLI sync"
category: ops
tags: ["windmill", "cli", "operations"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>CLI sync</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.376392</created_at>
  <updated_at>2026-01-02T19:55:27.376392</updated_at>
  <language>en</language>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="feature">meta/windmill/index-14</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../3_cli/index.mdx</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>windmill,cli,operations</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# CLI sync

> **Context**: import DocCard from '@site/src/components/DocCard';

You can use [Windmill CLI](./meta-windmill-index-14.md) to sync workspace to a git repository using `wmill sync pull` & `wmill sync push`.

For more details, see:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Command-line interface - Sync"
		description="Synchronize folders & git repositories to a Windmill instance"
		href="/docs/advanced/cli/sync"
	/>
</div>

For options to do Version control on Windmill, see:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Version control in Windmill"
		description="Sync your workspace to a git repository."
		href="/docs/advanced/version_control"
	/>
</div>

For options to do Deploy to prod on Windmill, see:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Deploy to prod"
		description="Deploy to prod using a staging workspace"
		href="/docs/advanced/deploy_to_prod"
	/>
</div>

## See Also

- [Windmill CLI](../3_cli/index.mdx)
