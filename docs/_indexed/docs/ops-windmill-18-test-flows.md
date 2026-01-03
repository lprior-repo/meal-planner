---
id: ops/windmill/18-test-flows
title: "Testing flows"
category: ops
tags: ["windmill", "testing", "operations"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Testing flows</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.959847</created_at>
  <updated_at>2026-01-02T19:55:27.959847</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="Instant preview in Flow editor" level="2"/>
    <section name="Test flow" level="3"/>
    <section name="Test up to step" level="3"/>
    <section name="Test an iteration" level="3"/>
    <section name="Restart from step, iteration or branch" level="3"/>
    <section name="Test this step" level="3"/>
  </sections>
  <features>
    <feature>instant_preview_in_flow_editor</feature>
    <feature>restart_from_step_iteration_or_branch</feature>
    <feature>test_an_iteration</feature>
    <feature>test_flow</feature>
    <feature>test_this_step</feature>
    <feature>test_up_to_step</feature>
  </features>
  <dependencies>
    <dependency type="feature">meta/windmill/index-101</dependency>
    <dependency type="feature">tutorial/windmill/1-flow-editor</dependency>
    <dependency type="feature">tutorial/windmill/3-editor-components</dependency>
    <dependency type="feature">meta/windmill/index-76</dependency>
    <dependency type="feature">meta/windmill/index-77</dependency>
    <dependency type="feature">tutorial/windmill/12-flow-loops</dependency>
    <dependency type="feature">tutorial/windmill/22-while-loops</dependency>
    <dependency type="feature">meta/windmill/index-23</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../script_editor/index.mdx</entity>
    <entity relationship="uses">./1_flow_editor.mdx</entity>
    <entity relationship="uses">../apps/0_app_editor/index.mdx</entity>
    <entity relationship="uses">./3_editor_components.mdx</entity>
    <entity relationship="uses">../core_concepts/23_instant_preview/flow_status.png &apos;Flow status&apos;</entity>
    <entity relationship="uses">../core_concepts/5_monitor_past_and_future_runs/index.mdx</entity>
    <entity relationship="uses">../core_concepts/6_auto_generated_uis/index.mdx</entity>
    <entity relationship="uses">../core_concepts/23_instant_preview/input_library.png &apos;Input library&apos;</entity>
    <entity relationship="uses">../core_concepts/23_instant_preview/fill_from_request.png &apos;Fill from request&apos;</entity>
    <entity relationship="uses">../flows/12_flow_loops.md</entity>
  </related_entities>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,testing,operations</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Testing flows

> **Context**: import DocCard from '@site/src/components/DocCard';

On top of its integrated editors ([scripts](./meta-windmill-index-101.md), [flows](./tutorial-windmill-1-flow-editor.md), [apps](../apps/0_app_editor/index.mdx)), Windmill allows users to see and test what they are building directly from the editor, even before deployment.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Instant preview & testing"
		description="Windmill allows users to see and test what they are building directly from the editor, even before deployment."
		href="/docs/core_concepts/instant_preview"
	/>
</div>

## Instant preview in Flow editor

The flow editor has several methods of previewing results instantly.

Testing the flow or certain steps is often required to have the outputs of previous steps suggested as input for another step:

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/flow_test_preview_results.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Flow editor"
		description="Windmill's Flow editor allows you to build flows with a low-code builder."
		href="/docs/flows/flow_editor"
	/>
</div>

### Test flow

While editing the flow, you can run the whole flow as a test.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/flow_test_flow.mp4"
/>

<br />

Click on `Test flow`. This will open a drawer with the [flow's inputs](./tutorial-windmill-3-editor-components.md#flow-inputs) and its status.

Upon execution, you can graphically preview (as a directed acyclic graph) the execution of the flow & the results & logs of each step.

![Flow status](../core_concepts/23_instant_preview/flow_status.png 'Flow status')

From the menu, you can also access [past runs](./meta-windmill-index-76.md) & [saved inputs](./meta-windmill-index-77.md#saved-inputs).

![Input library](../core_concepts/23_instant_preview/input_library.png 'Input library')

At last, you can fill arguments from a request.

![Fill from request](../core_concepts/23_instant_preview/fill_from_request.png 'Fill from request')

### Test up to step

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/flow_test_up_to.mp4"
/>

<br />

As for `Test flow`, you will get the same components (Flow inputs, status, input library etc.), only the flow will execute until a given step, included.

### Test an iteration

[For loops](./tutorial-windmill-12-flow-loops.md) and [While loops](./tutorial-windmill-22-while-loops.md) can be tested for a specific iteration.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/test_iteration.mp4"
	description="Test an iteration"
/>

### Restart from step, iteration or branch

Restart a flow at any given top level step. For-loop and branch-all can be restarted at a specific iteration/branch.
In the flow preview page, just select a top level node and a "Re-start from X" button will appear at the top, next to "Test flow".

To see how it works, see our [dedicated blog post](/blog/launch-week-1/restartable-flows).

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/5_NRFmUxfW0?vq=hd1440"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

Under [Cloud plans & Self-Hosted Enterprise Edition](/pricing), this feature is also available for [deployed](./meta-windmill-index-23.md) flows.

![Restart deployed flow](../core_concepts/23_instant_preview/restart_flow_2.png 'Restart deployed flow')

### Test this step

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/flow_test_this_step.mp4"
/>

<br />

`Test this step` is a way to test a single step of the flow. It comes useful to check your code or to have the results of your current steps suggested as inputs for further steps.

The arguments are pre-filled from the step inputs (if the arguments use results from previous steps, they will be used if those were tested before), but you can change them manually.


## See Also

- [scripts](../script_editor/index.mdx)
- [flows](./1_flow_editor.mdx)
- [apps](../apps/0_app_editor/index.mdx)
- [flow's inputs](./3_editor_components.mdx#flow-inputs)
- [Flow status](../core_concepts/23_instant_preview/flow_status.png 'Flow status')
