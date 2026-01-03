---
doc_id: concept/windmill/custom-environment-variables
chunk_id: concept/windmill/custom-environment-variables#chunk-1
heading_path: ["Custom environment variables"]
chunk_type: prose
tokens: 208
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Custom environment variables</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:28.162393</created_at>
  <updated_at>2026-01-02T19:55:28.162393</updated_at>
  <language>en</language>
  <dependencies>
    <dependency type="feature">meta/windmill/index-65</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../core_concepts/47_environment_variables/index.mdx</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>windmill,concept,custom</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Custom environment variables

> **Context**: import DocCard from '@site/src/components/DocCard';

In a self-hosted environment, Windmill allows you to set custom [environment variables](./meta-windmill-index-65.md) for your scripts. This feature is useful when a script needs an environment variable prior to the main function executing itself. For instance, some libraries in Go do some setup in the 'init' function that depends on environment variables.

To add a custom environment variable to a script in Windmill, you should follow this format: `<KEY>=<VALUE>`. Where `<KEY>` is the name of the environment variable and `<VALUE>` is the corresponding value of the environment variable.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Environment variables"
		description="Environment variables are used to configure the behavior of scripts and services, allowing for dynamic and flexible execution across different environments."
		href="/docs/core_concepts/environment_variables"
	/>
</div>
