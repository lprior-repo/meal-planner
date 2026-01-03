---
doc_id: ops/windmill/18-test-flows
chunk_id: ops/windmill/18-test-flows#chunk-1
heading_path: ["Testing flows"]
chunk_type: prose
tokens: 236
summary: "<!--"
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
