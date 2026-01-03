---
doc_id: tutorial/windmill/flows-guide
chunk_id: tutorial/windmill/flows-guide#chunk-1
heading_path: ["Windmill Flows Guide"]
chunk_type: prose
tokens: 196
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>windmill</category>
  <title>Windmill Flows Guide</title>
  <description>This guide covers creating and managing Windmill flows in this repository.</description>
  <created_at>2026-01-02T19:55:27.360139</created_at>
  <updated_at>2026-01-02T19:55:27.360139</updated_at>
  <language>en</language>
  <sections count="20">
    <section name="Quick Reference" level="2"/>
    <section name="Flow File Structure" level="2"/>
    <section name="Flow YAML Structure" level="2"/>
    <section name="Input Transforms" level="2"/>
    <section name="Static Value" level="3"/>
    <section name="Resource Reference" level="3"/>
    <section name="From Previous Step" level="3"/>
    <section name="From Resume Payload (approval flows)" level="3"/>
    <section name="Approval/Prompt Flows" level="2"/>
    <section name="Step with Suspend + Resume Form" level="3"/>
  </sections>
  <features>
    <feature>accessing_resume_data</feature>
    <feature>approvalprompt_flows</feature>
    <feature>cancel_suspended_flow</feature>
    <feature>common_issues</feature>
    <feature>enotdir_on_flow_push</feature>
    <feature>flow_file_structure</feature>
    <feature>flow_not_syncing_with_wmill_sync_push</feature>
    <feature>flow_yaml_structure</feature>
    <feature>from_previous_step</feature>
    <feature>from_resume_payload_approval_flows</feature>
    <feature>input_transforms</feature>
    <feature>js_main</feature>
    <feature>js_urls</feature>
    <feature>oauth_flow_pattern</feature>
    <feature>pushing_flows_via_api</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="feature">ops/windmill/development-guide</dependency>
    <dependency type="feature">tutorial/windmill/11-flow-approval</dependency>
    <dependency type="feature">meta/windmill/index-68</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">${auth_url}</entity>
    <entity relationship="uses">./DEVELOPMENT_GUIDE.md</entity>
    <entity relationship="uses">./flows/11_flow_approval.mdx</entity>
    <entity relationship="uses">./core_concepts/4_webhooks/index.mdx</entity>
  </related_entities>
  <examples count="13">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,tutorial,beginner</tags>
</doc_metadata>
-->

# Windmill Flows Guide

> **Context**: This guide covers creating and managing Windmill flows in this repository.

This guide covers creating and managing Windmill flows in this repository.
