---
doc_id: tutorial/windmill/11-flow-approval
chunk_id: tutorial/windmill/11-flow-approval#chunk-2
heading_path: ["Suspend & Approval / Prompts", "Add approval script"]
chunk_type: prose
tokens: 128
summary: "Add approval script"
---

## Add approval script

You can think of a scenario where only specific people can resume or cancel a
Flow. To achieve this they would need to receive a personalized URL via some
external communication channel (like e-mail, SMS or chat message).

When adding a step to a flow, pick `Approval`, and write a new approval script or pick one from [WindmillHub](https://hub.windmill.dev/approvals). This will create a step where the option in tab "Advanced" - "Suspend" is enabled.

![Adding approval step](../assets/flows/approval-step.png 'Adding approval step')

Use `wmill.getResumeUrls()` in [TypeScript](./meta-windmill-index-87.md) or `wmill.get_resume_urls()` in [Python](./meta-windmill-index-88.md) from the [wmill client](./ops-windmill-ts-client.md) to generate secret URLs.
