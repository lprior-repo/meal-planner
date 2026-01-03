---
doc_id: tutorial/windmill/3-editor-components
chunk_id: tutorial/windmill/3-editor-components#chunk-1
heading_path: ["Flow editor components"]
chunk_type: prose
tokens: 299
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>Flow editor components</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.978106</created_at>
  <updated_at>2026-01-02T19:55:27.978106</updated_at>
  <language>en</language>
  <sections count="30">
    <section name="Toolbar" level="2"/>
    <section name="Export flow" level="3"/>
    <section name="Edit in YAML" level="3"/>
    <section name="Tutorials" level="3"/>
    <section name="Diff" level="3"/>
    <section name="Settings" level="2"/>
    <section name="Summary" level="4"/>
    <section name="Path" level="4"/>
    <section name="Description" level="4"/>
    <section name="Advanced" level="3"/>
  </sections>
  <features>
    <feature>action_editor</feature>
    <feature>advanced</feature>
    <feature>copying_the_first_step_inputs</feature>
    <feature>customize_the_flow_inputs</feature>
    <feature>description</feature>
    <feature>diff</feature>
    <feature>dynamic</feature>
    <feature>edit_in_yaml</feature>
    <feature>export_flow</feature>
    <feature>flow_actions</feature>
    <feature>flow_inputs</feature>
    <feature>header</feature>
    <feature>inline_action_script</feature>
    <feature>insert_mode</feature>
    <feature>path</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="library">requests</dependency>
    <dependency type="service">postgres</dependency>
    <dependency type="service">mysql</dependency>
    <dependency type="service">docker</dependency>
    <dependency type="feature">meta/windmill/index-30</dependency>
    <dependency type="feature">meta/windmill/index-23</dependency>
    <dependency type="feature">concept/windmill/17-ai-flows</dependency>
    <dependency type="feature">concept/windmill/24-sticky-notes</dependency>
    <dependency type="feature">meta/windmill/index-39</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">../assets/flows/flow_example.png</entity>
    <entity relationship="uses">../assets/flows/flow_toolbar.png</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">../core_concepts/16_roles_and_permissions/index.mdx</entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>12</estimated_reading_time>
  <tags>windmill,tutorial,beginner,flow</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Flow editor components

> **Context**: import DocCard from '@site/src/components/DocCard';

The Flow Builder has the following major components we will detail below:

- [Toolbar](#toolbar): the toolbar allows you to export the flow, configure the flow settings, and test the flow.
- [Settings](#settings): configure the flow settings.
- [Static Inputs](#static-inputs): view all flow static inputs.
- [Flow Inputs](#flow-inputs): view all flow inputs.
- [Action](#flow-actions): steps are the building blocks of a flow. They are the actions that will be executed when the flow is run.
- [Action editor](#action-editor): configure the action.

<br />

![Example of a flow](../assets/flows/flow_example.png)

> _Example of a [flow](https://hub.windmill.dev/flows/38/automatically-populate-crm-contact-details-from-simple-email) in Windmill._
