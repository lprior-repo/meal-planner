---
doc_id: tutorial/flows/11-flow-approval
chunk_id: tutorial/flows/11-flow-approval#chunk-7
heading_path: ["Suspend & Approval / Prompts", "Microsoft Teams approval step"]
chunk_type: code
tokens: 399
summary: "Microsoft Teams approval step"
---

## Microsoft Teams approval step

The Windmill [TypeScript](./ops-2_clients-ts-client.md) client exposes helper functions to request a approval on Microsoft Teams. The interactive approval is a Teams message that can be approved or rejected directly from Teams without having to go back to the Windmill UI where as the non-interactive approval will be a simple link that will open the approval page in the Windmill UI in your browser.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/gc6P7nnMORk"
	title="Microsoft Teams approval step"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

The following hub scripts can be used:
 - [Request Interactive Teams Approval](https://hub.windmill.dev/scripts/teams/13935/interactive-microsoft-teams-approval-teams)
 - [Request Basic Teams Approval](https://hub.windmill.dev/scripts/teams/13936/microsoft-teams-approval-teams)

If you define a [form](./flow_approval#form) on the approval step, the form will be displayed in the Teams message as a modal.

![Approval form teams](../assets/flows/tuto_approval_teams.png.webp)

Both of these scripts are using the Windmill client helper function:

<Tabs className="unique-tabs">
<TabItem value="ts_interactive" label="TypeScript Interactive" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>
```javascript
  await wmill.requestInteractiveTeamsApproval({
      teamName: "Windmill",
      channelName: "General",
      message: "Please approve this request",
      approver: "approver123",
      defaultArgsJson: { key1: "value1", key2: 42 },
      dynamicEnumsJson: { foo: ["choice1", "choice2"], bar: ["optionA", "optionB"] },
  });
```
</TabItem>


<TabItem value="ts_basic" label="TypeScript Basic" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>
```ts
const card_block = {
        "type": "message",
        "attachments": [
            {
                "contentType": "application/vnd.microsoft.card.adaptive",
                "content": {
                    "type": "AdaptiveCard",
                    "$schema": "https://adaptivecards.io/schemas/adaptive-card.json",
                    "version": "1.6",
                    "body": [
                        ... // card body
                    ],
                },
            }
        ],
        "conversation": {"id": `${conversation_id}`},
    }

  await wmill.TeamsService.sendMessageToConversation({
    requestBody: { conversation_id, text: "A workflow has been suspended and is waiting for approval!", card_block }
  })
```
</TabItem>
</Tabs>

Where [dynamic_enums](./flow_approval#slack-approval-step) can be used to dynamically set the options of enum form arguments and [default_args](./flow_approval#default-args) can be used to dynamically set the default values of form arguments.

If multiple approvals are required you can use the client helper directly and send approval requests to different channels (same as the Slack example above).
