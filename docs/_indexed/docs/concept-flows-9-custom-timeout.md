---
id: concept/flows/9-custom-timeout
title: "Custom timeout for step"
category: concept
tags: ["concept", "flows", "custom"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>flows</category>
  <title>Custom Timeout</title>
  <description>Define timeout for individual flow steps</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="1">
    <section name="Custom timeout for step" level="1"/>
  </sections>
  <features>
    <feature>custom_timeout</feature>
    <feature>timeout_management</feature>
  </features>
  <dependencies>
    <dependency type="feature">instance_settings</dependency>
  </dependencies>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,timeout,execution-limit,step,instance</tags>
</doc_metadata>
-->

# Custom timeout for step

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>flows</category> <title>Custom Timeout</title> <description>Define timeout for individual flow st

For each step can be defined a timeout. If the execution takes longer than the time limit, the execution of the step will be interrupted.

If defined, the custom timeout will be used instead of the instance timeout for the step (for self-hosted, defined by the [environment variable](./meta-47_environment_variables-index.md) `TIMEOUT`). The step's timeout cannot be greater than the [instance timeout](./meta-18_instance_settings-index.md#default-timeout).

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	autoPlay
	controls
	id="main-video"
	src="/videos/custom_timeout.mp4"
/>

## See Also

- [environment variable](../core_concepts/47_environment_variables/index.mdx)
- [instance timeout](../advanced/18_instance_settings/index.mdx#default-timeout)
