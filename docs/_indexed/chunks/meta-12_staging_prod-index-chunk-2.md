---
doc_id: meta/12_staging_prod/index
chunk_id: meta/12_staging_prod/index#chunk-2
heading_path: ["Deploy to prod using the UI", "How it works"]
chunk_type: prose
tokens: 315
summary: "How it works"
---

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
