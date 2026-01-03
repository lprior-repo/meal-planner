---
doc_id: tutorial/windmill/11-flow-approval
chunk_id: tutorial/windmill/11-flow-approval#chunk-5
heading_path: ["Suspend & Approval / Prompts", "Permissions"]
chunk_type: prose
tokens: 273
summary: "Permissions"
---

## Permissions

Customizing permissions of approval steps is a [Cloud & Enterprise Self-Hosted](/pricing) only feature.

### Require approvers to be logged in

By enabling this option, only users logged in to Windmill can approve the step.

![Approval Logged In](../assets/flows/approval-logged-in.png 'Approval Logged In')

### Disable self-approval

The user who triggered the flow will not be allowed to approve it.

![Disable self-approval](../assets/flows/disable-self-approval.png 'Disable self-approval')

### Require approvers to be members of a group

By enabling this option, only logged in users who are members of the specified [group](./meta-windmill-index-79.md) can approve the step.

![Require approvers to be members of a group](../assets/flows/approval-require-group.png 'Require approvers to be members of a group')

You can also dynamically set the group by connecting it to another node's output.

![Approval group dynamic](../assets/flows/approval-group-dynamic.png 'Approval group dynamic')

### Get the users who approved the flow

The input `approvers` is an array of the users who approved the flow.

To get the list of users, just have the step after the approval step return the `approvers` key. For example by taking an input [connected](./tutorial-windmill-16-architecture.md) to the `approvers` key.

The step could be as simple as:

```ts
export async function main(list_of_approvers) {
  return list_of_approvers
}
```

With input list_of_approvers taking as JavaScript expression `approvers`.

<video
	className="border-2 rounded-lg object-cover w-full h-full"
	controls
	src="/videos/list_of_approvers.mp4"
/>
