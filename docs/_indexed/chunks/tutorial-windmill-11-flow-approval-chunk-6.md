---
doc_id: tutorial/windmill/11-flow-approval
chunk_id: tutorial/windmill/11-flow-approval#chunk-6
heading_path: ["Suspend & Approval / Prompts", "Slack approval step"]
chunk_type: code
tokens: 418
summary: "Slack approval step"
---

## Slack approval step

The Windmill [Python](./ops-windmill-python-client.md) and [TypeScript](./ops-windmill-ts-client.md) clients both have a helper function to request an interactive approval on Slack. An interactive approval is a Slack message that can be approved or rejected directly from Slack without having to go back to the Windmill UI.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/wUvqom8nmM4"
	title="Slack approval step"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

The following hub scripts can be used:
 - Python: [Request Interactive Slack Approval](https://hub.windmill.dev/scripts/slack/11403/request-interactive-slack-approval-(python)-slack)
 - TypeScript [Request Interactive Slack Approval](https://hub.windmill.dev/scripts/slack/11402/request-interactive-slack-approval-slack)

If you define a [form](./flow_approval#form) on the approval step, the form will be displayed in the Slack message as a modal.

![Approval form slack](../assets/flows/tuto_approval_slack_form.png.webp)

Both of these scripts are using the Windmill client helper function:

<Tabs className="unique-tabs">
<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>
```python
wmill.request_interactive_slack_approval(
    slack_resource_path="/u/username/my_slack_resource",
    channel_id="admins-slack-channel",
    message="Please approve this request",
    approver="approver123",
    default_args_json={"key1": "value1", "key2": 42},
	dynamic_enums_json={"foo": ["choice1", "choice2"], "bar": ["optionA", "optionB"]},
)
```
</TabItem>


<TabItem value="bun" label="Bun" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>
```ts
 await wmill.requestInteractiveSlackApproval({
   slackResourcePath: "/u/username/my_slack_resource",
   channelId: "admins-slack-channel",
   message: "Please approve this request",
   approver: "approver123",
   defaultArgsJson: { key1: "value1", key2: 42 },
   dynamicEnumsJson: { foo: ["choice1", "choice2"], bar: ["optionA", "optionB"] },
 });
```
</TabItem>
</Tabs>

Where [dynamic_enums](./flow_approval#slack-approval-step) can be used to dynamically set the options of enum form arguments and [default_args](./flow_approval#default-args) can be used to dynamically set the default values of form arguments.

If multiple approvals are required you can use the client helper directly and send approval requests to different channels:

<Tabs className="unique-tabs">
<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>
```python
import wmill

def main():
	# Send approval request to customers
    wmill.request_interactive_slack_approval(
        'u/username/slack_resource',
        'customers',
    )

	# Send approval request to admins
    wmill.request_interactive_slack_approval(
        'u/username/slack_resource',
        'admins',
    )
```
</TabItem>

<TabItem value="bun" label="Bun" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>
```ts
import * as wmill from "windmill-client"

export async function main() {
  await wmill.requestInteractiveSlackApproval({
    slackResourcePath: "/u/username/slack_resource",
   channelId: "customers"
  })
  await wmill.requestInteractiveSlackApproval({
    slackResourcePath: "/u/username/slack_resource",
    channelId: "admins"
  })
}
```
</TabItem>
</Tabs>
