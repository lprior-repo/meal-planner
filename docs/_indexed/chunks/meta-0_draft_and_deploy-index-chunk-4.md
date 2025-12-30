---
doc_id: meta/0_draft_and_deploy/index
chunk_id: meta/0_draft_and_deploy/index#chunk-4
heading_path: ["Draft and deploy", "Deployed version"]
chunk_type: prose
tokens: 196
summary: "Deployed version"
---

## Deployed version

The deployed version is the authoritative version of a runnable. Once deployed, it is not only visible by workspace members [with the right permissions](./meta-16_roles_and_permissions-index.md) but has its own [auto-generated UI](./meta-6_auto_generated_uis-index.md), [webhooks](./meta-4_webhooks-index.md), or can be called from flows and apps (for scripts and flows). This also means that local edits and drafts can be made in parallel to a deployed version of a runnable without affecting its behavior.

### Deployment history

Scripts and flows can be added a Deployment message on each deployment. You can find versions and their deployment message in the "History" menu.

If you want to have several versions of the same runnable, just fork it with the `Fork` button on the drop down menu of `Deploy`. Past versions can be retrieved from the `History` menu with "Restore as fork" or "Redeploy with that version" buttons.

![Deployment History](../../assets/script_editor/deployment_history.png 'Deployment History')

> Deployment History of a flow.
