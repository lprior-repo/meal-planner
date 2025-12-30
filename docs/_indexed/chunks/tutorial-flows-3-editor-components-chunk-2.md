---
doc_id: tutorial/flows/3-editor-components
chunk_id: tutorial/flows/3-editor-components#chunk-2
heading_path: ["Flow editor components", "Toolbar"]
chunk_type: prose
tokens: 443
summary: "Toolbar"
---

## Toolbar

![Flow Toolbar](../assets/flows/flow_toolbar.png)

The toolbar allows you to export the flow, configure the flow settings, and test the flow.
Here are the different options available in the toolbar:

- **Summary**: shortcut to edit the flow [summary](#summary).
- **Previous/Next**: undo actions.
- **[Path](./meta-16_roles_and_permissions-index.md#path)**: define the permissions of the flow.
- **`⋮` menu**:
  - **Deployment History**: view the [deployment](./meta-0_draft_and_deploy-index.md#deployment-history) history of the flow.
  - **Export**: view the flow as JSON or YAML.
  - **Edit in YAML**: edit the flow in YAML.
- **Tutorial button**: follow the tutorials, reset them or skip them.
- **Diff**: view the diff between the current and the last [version](./meta-0_draft_and_deploy-index.md) of the flow.
- **AI Builder**: [build flow with AI](./concept-flows-17-ai-flows.md).
- **Sticky notes button**: add [sticky notes](./concept-flows-24-sticky-notes.md) to annotate the flow.
- **Notes toggle**: hide or show all sticky notes on the canvas.
- **Selection/Pan mode toggle**: switch between selection mode for creating group notes and pan mode for navigation.
- **Test flow**: open the flow [test](./meta-23_instant_preview-index.md) slider.
- **Test up to**: open the flow [test](./meta-23_instant_preview-index.md) slider.
- **Draft**: save the flow as [draft](./meta-0_draft_and_deploy-index.md) (you can do it with shortcut `Ctrl + S` / `⌘ S`).
- **Deploy**: [deploy](./meta-0_draft_and_deploy-index.md) the flow.

### Export flow

The flow can be exported as JSON or YAML. The export will include the flow metadata, settings, and steps.

![Flow Export](../misc/1_share_on_hub/export_flow.png.webp 'Flow Export')

### Edit in YAML

You can edit directly the yaml of flows within the flow editor.

In particular, you can:

- Edit flow metadata.
- Edit steps ids.
- Edit steps features.
- Edit steps code.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/edit_flow_yaml.mp4"
/>

### Tutorials

The tutorial button allows you to follow the tutorials, reset them or skip them.

The current tutorials on the Flow editor are:

- Simple flow tutorial
- [For loops](./tutorial-flows-12-flow-loops.md) tutorial
- [Branch one](./concept-flows-13-flow-branches.md#branch-one) tutorial
- [Branch all](./concept-flows-13-flow-branches.md#branch-all) tutorial
- [Error handler](./tutorial-flows-7-flow-error-handler.md) tutorial

### Diff

The diff button allows you to view the diff between the current and the latest [version](./meta-0_draft_and_deploy-index.md) of the flow.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/diff_viewer.mp4"
/>
