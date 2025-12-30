---
id: concept/flows/5-step-mocking
title: "Step mocking / Pin result"
category: concept
tags: ["step", "flows", "concept"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>flows</category>
  <title>Step Mocking</title>
  <description>Mock flow steps for faster development iteration</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Step mocking / Pin result" level="1"/>
    <section name="Mocking vs Pinning" level="2"/>
    <section name="Accessing step results" level="2"/>
  </sections>
  <features>
    <feature>step_mocking</feature>
    <feature>pin_result</feature>
    <feature>development_iteration</feature>
    <feature>history_exploration</feature>
  </features>
  <dependencies>
    <dependency type="feature">caching</dependency>
  </dependencies>
  <examples count="2">
    <example>Pin successful run result</example>
    <example>Mock step with custom value</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>windmill,mock,pin,result,development,testing,iteration,cache</tags>
</doc_metadata>
-->

# Step mocking / Pin result

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>flows</category> <title>Step Mocking</title> <description>Mock flow steps for faster development 

Step mocking and pinning results allows faster iteration while building flows. When a step is mocked or pinned, it will immediately return the specified value without performing any computation.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/-cATEh8saqU"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br/>

## Mocking vs Pinning

There are two ways to control step execution:

1. **Mocking**: Set a custom return value that will be used instead of running the step.
2. **Pinning**: Use a previous successful run result as the return value.

## Accessing step results

You can access and manage step results in two ways:
1. Directly by clicking on the step bottom arrow in the flow view for quick access.

![Bottom arrow](../assets/flows/bottom_arrow.png "Bottom arrow")

2. From the step's `Test this step` menu.

![Test this step](../assets/flows/test_this_step.png "Test this step")

## Features

### History exploration
- Use the history button to explore previous step results.
- View and select from past successful runs.
- Imported flows and scripts retain their run history.

### Pinning results

Pin any successful run result to reuse it.

![Pin result](../assets/flows/pin_result.png "Pin result")

You can edit pinned data by overriding pin functionality (you can still test the step).

  ![Override pin](../assets/flows/override_pin.png "Override pin")

### Mocking

You can also edit the mocked value directly.

  ![Direct editing](../assets/flows/direct_editing.png "Direct editing")
  
[Test step](./ops-flows-18-test-flows.md) functionality remains available even with pinned results.

:::tip Cache for steps

The [cache for steps feature](./tutorial-flows-4-cache.md) allows you to cache the results of a step for a specified number of seconds, thereby reducing the need for redundant computations when re-running the same step with identical input.

:::


## See Also

- [Bottom arrow](../assets/flows/bottom_arrow.png "Bottom arrow")
- [Test this step](../assets/flows/test_this_step.png "Test this step")
- [Pin result](../assets/flows/pin_result.png "Pin result")
- [Override pin](../assets/flows/override_pin.png "Override pin")
- [Direct editing](../assets/flows/direct_editing.png "Direct editing")
