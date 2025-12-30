---
id: meta/12_staging_prod/index
title: "Deploy to prod using the UI"
category: meta
tags: ["12_staging_prod", "meta", "deploy"]
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

## How it works

For users with admin rights on the source workspace, in the `Workspace` settings, go to the "Deployment UI" tab and pick a workspace for "Workspace to link to".

Items that can be deployed are:
- [Scripts](./meta-script_editor-index.md)
- [Flows](./tutorial-flows-1-flow-editor.md)
- [Resources](./meta-3_resources_and_types-index.md)
- [Variables](./meta-2_variables_and_secrets-index.md)
- [Triggers](./meta-8_triggers-index.md)

You can filter out on each of these types so that they won't be deployed.

![Link to a workspace](./workspace_to_link_to.png 'Link to a workspace')

The workspace to link to can for example be:

- a Staging workspace to test scripts and flows
- a Prod workspace where you can deploy scripts and flows when ready.

Then, from the workspace, on the `⋮` menu of each [deployed](./meta-0_draft_and_deploy-index.md#deployed-version) script or flow, pick "Deploy to staging/prod". This can be done also from the [Resources](./meta-3_resources_and_types-index.md) and [Variables](./meta-2_variables_and_secrets-index.md) menus or directly from a script or flow `Details` page.

This can be done by users with both View rights on the deployed-from workspace and edit rights on the deployed-to workspace.

You can deploy one by one flows, scripts (including each script within flow), variables and resources. Or toggle more than one and "Deploy all".

![Deploy to staging/prod](./deploy_to_staging_prod.png.webp 'Deploy to staging/prod')

Items are called:

- "Missing" if not yet present in the deployed workspace.
- "New" if the item will be created with the deployment.
- "diff" if the item was already deployed previously. This opens a difference viewer tab where you can see differences with the previous version.

![Diff menu](./diff_menu.png.webp 'Diff menu')

## Shareable page

A static page is created for each potential deployment to Staging/Prod.

This can be useful for non-admin (for example, operators) to share a page to properly-permissioned users to have them review or do the deployment.

![Shareable link](./shareable_link.png.webp 'Shareable link')

> Even users who are not admin can see the "Deploy to staging/prod", from where they can get the link of the shareable page.

<br/>

![Shareable page](./shareable_page.png.webp 'Shareable page')

> This page then allows users with the right permissions to deploy the given items.


## See Also

- [Cloud plans and Self-Hosted Enterprise Edition](/pricing)
- [Deploy to prod](../../advanced/12_deploy_to_prod/index.mdx)
- [Draft and deploy](../0_draft_and_deploy/index.mdx)
- [Scripts](../../script_editor/index.mdx)
- [Flows](../../flows/1_flow_editor.mdx)
