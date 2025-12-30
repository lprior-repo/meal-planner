---
doc_id: meta/12_staging_prod/index
chunk_id: meta/12_staging_prod/index#chunk-1
heading_path: ["Deploy to prod using the UI"]
chunk_type: prose
tokens: 243
summary: "<!--"
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>core_concepts</category>
  <title>Staging/Production Deployment</title>
  <description>Deploy items between workspaces (staging to production)</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Deploy to prod using the UI" level="1"/>
    <section name="How it works" level="2"/>
    <section name="Items are called" level="2"/>
    <section name="Shareable page" level="2"/>
  </sections>
  <features>
    <feature>staging_prod</feature>
    <feature>deployment</feature>
    <feature>workspace_sync</feature>
    <feature>version_management</feature>
    <feature>diff_viewer</feature>
  </features>
  <dependencies>
    <dependency type="tool">wmill_cli</dependency>
    <dependency type="feature">enterprise_edition</dependency>
  </dependencies>
  <examples count="2">
    <example>Deploy from dev to staging to prod</example>
    <example>Shareable deployment pages for operators</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>6</estimated_reading_time>
  <tags>windmill,deploy,staging,prod,workspace,sync,version,diff</tags>
</doc_metadata>
-->

# Deploy to prod using the UI

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>core_concepts</category> <title>Staging/Production Deployment</title> <description>Deploy items b

From a workspace in Windmill, you can deploy a item and all its dependencies to another workspace. This is a natural way of implementing staging/prod. This feature is available for [Cloud plans and Self-Hosted Enterprise Edition](/pricing) only.

:::info Deploy to prod

For all details on Deployments to prod in Windmill, see [Deploy to prod](./meta-12_deploy_to_prod-index.md).

:::

<video
    className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
    controls
    id="main-video"
    src="/videos/staging_prod.mp4"
/>

<br/>

:::tip Draft and deploy

The [Draft and deploy](./meta-0_draft_and_deploy-index.md) is another feature that offers a lightweight solution for implementing a staging and production workflow, suitable for various scenarios.

:::
