---
doc_id: tutorial/flows/11-flow-approval
chunk_id: tutorial/flows/11-flow-approval#chunk-8
heading_path: ["Suspend & Approval / Prompts", "Tutorial: a Slack approval step conditioning flow branches"]
chunk_type: prose
tokens: 521
summary: "Tutorial: a Slack approval step conditioning flow branches"
---

## Tutorial: a Slack approval step conditioning flow branches

The answer to the arguments of an approval page can be used as an input to condition branches in human-in-the-loop workflows.

Here is a basic example we will detail below.

<video
	className="border-2 rounded-lg object-cover w-full h-full"
	controls
	src="/videos/example_approval_branches.mp4"
/>

<br />

This flow:

1. Receives a refund request form a user.
2. Asks on Slack via an approval step what action to take.
3. The answer is a condition to [branches](./concept-flows-13-flow-branches.md) that lead either a refund, a refusal or a deeper investigation.

:::tip Fork and try the flow

An [automated trigger version](#automated-trigger-version) of this flow is available on [Windmill Hub](https://hub.windmill.dev/flows/49/).

:::

For the sake of the example, we made this flow simple with a [manual trigger](./meta-8_triggers-index.md). Two input were used: "User email" and "Order number", both strings.

![Flow inputs](../assets/flows/tuto_approval_input.png.webp)

Then, we picked an approval step on the Hub to [Request Interactive Slack Approval](https://hub.windmill.dev/scripts/slack/11402/request-interactive-slack-approval-slack). With inputs:

- "slackResourcePath": the path to your [Slack resource](../integrations/slack.mdx).
- "channel": Slack channel to publish message, as string.
- "text: `Refund request by _${flow_input["User email"]}_ on order ${flow_input["Order number"]}.`.

This will alow the user to approve or reject the refund request directly from Slack without having to go back to the Windmill UI.

![Slack inputs](../assets/flows/tuto_approval_slack.png.webp)

In the `Advanced` settings of the step, for "Suspend/Approval". We added the following properties to the form.

![Form settings](../assets/flows/tuto_approval_form_0.png.webp)

![Form settings](../assets/flows/tuto_approval_form.png.webp)

![Form settings 2](../assets/flows/tuto_approval_form_2.png.webp)

This will lead to the following approval page and slack form:

![Approval page](../assets/flows/tuto_approval_page.png.webp)

![Approval form slack](../assets/flows/tuto_approval_slack_form.png.webp)

This approval page will generate two keys you can use for further steps: `resume["Action"]` and `resume["Message"]`. `resume` is the resume payload.

Those are the keys you can use as predicate expressions for your [branches](./concept-flows-13-flow-branches.md).

![Branches predicate expressions](../assets/flows/tuto_approval_branches.png.webp 'Branches predicate expressions')

> With [Branch one](./concept-flows-13-flow-branches.md#branch-one), the first branch whose predicate expression is `true` will execute.

<br />

The content of each branch is of little importance for this tutorial as it depends each operations and tech stack. For the example we used two Hub scripts: [Send Email](https://hub.windmill.dev/scripts/gmail/1291/) with [Gmail](../integrations/gmail.md) and [Send Message to Channel](https://hub.windmill.dev/scripts/slack/1284/) with [Slack](../integrations/slack.mdx).

<details>
  <summary>Example of arguments used for Gmail and Slack scripts:</summary>

![Gmail inputs](../assets/flows/tuto_approval_gmail.png.webp)

<br />

![Slack inputs](../assets/flows/tuto_approval_slack2.png.webp)

</details>

### Automated trigger version

You could use the [Mailchimp Mandrill integration](../integrations/mailchimp_mandrill.md) to trigger this flow manually by an email reception.

<video
	className="border-2 rounded-lg object-cover w-full h-full"
	controls
	src="/videos/automated_refund.mp4"
/>

<br />

This flow can be found and forked on [Windmill Hub](https://hub.windmill.dev/flows/49/).
