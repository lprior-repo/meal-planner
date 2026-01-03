---
doc_id: tutorial/windmill/11-flow-approval
chunk_id: tutorial/windmill/11-flow-approval#chunk-4
heading_path: ["Suspend & Approval / Prompts", "Form"]
chunk_type: code
tokens: 1531
summary: "Form"
---

## Form

You can add an arbitrary schema form to be provided and displayed on the approval page. Users opening the approval page would then be offered to fill arguments you can use in the flow.

Adding a form to an approval step is a [Cloud & Enterprise Self-Hosted](/pricing) only feature.

<video
	className="border-2 rounded-lg object-cover w-full h-full"
	controls
	src="/videos/form_approval_page.mp4"
/>

<br />

In the `Advanced` menu of a step, go to the "Suspend/Approval" tab and enable the `Add a form to the approval page` button.

Add properties and define their Name, Description, Type, Default Value and Advanced settings.

![Add argument](../assets/flows/add_argument.png.webp 'Add argument')

That will the be displayed on the approval page.

![Fill argument](../assets/flows/page_arguments.png.webp 'Fill argument')

### Use arguments

The approval form argument values can be accessed in the subsequent step by [connecting](./tutorial-windmill-16-architecture.md#input-transform) input fields to either `resume["argument_name"]` for a specific argument, or simply `resume` to obtain the complete payload.

![Use argument](../assets/flows/approval_argument.png.webp 'Use argument')

This is a way to introduce human-in-the-loop workflows and condition branches on approval steps inputs.

### Prompts

A prompt is simply an approval step that can be self-approved. To do this, include the resume url in the returned payload of the step. The UX will automatically adapt and show the prompt to the operator when running the flow. e.g:

<Tabs className="unique-tabs">
<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from "windmill-client"

export async function main() {
    const resumeUrls = await wmill.getResumeUrls("approver1")

    return {
        resume: resumeUrls['resume'],
        default_args: {}, // optional
        enums: {} // optional
    }
}
```

Find this script on [Windmill Hub](https://hub.windmill.dev/scripts/windmill/7120/approval-prompt-windmill).

</TabItem>
<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from "npm:windmill-client@^1.158.2"

export async function main() {
    const resumeUrls = await wmill.getResumeUrls("approver1")

    return {
        resume: resumeUrls['resume'],
        default_args: {}, // optional
        enums: {} // optional
    }
}
```

</TabItem>
<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
import wmill

def main():
    urls = wmill.get_resume_urls()
    return {
        "resume": urls["resume"],
        "default_args": {}, # optional
        "enums": {} # optional
    }
```

</TabItem>
<TabItem value="go" label="Go" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```go
package inner

import (
	wmill "github.com/windmill-labs/windmill-go-client"
)

func main() (map[string]interface{}, error) {
	urls, err := wmill.GetResumeUrls("approver1")
	if err != nil {
		return nil, err
	}
	return map[string]interface{}{
		"resume":      urls.Resume,
		"default_args": make(map[string]interface{}), // optional
		"enums":       make(map[string]interface{}), // optional
	}, nil
}
```

</TabItem>
</Tabs>

In the video below, you can see a user creating an approval step within a flow including the resume url in the returned payload of the step.
Then another user ([operator](./meta-windmill-index-30.md#operator), since is only "Viewer" in the [folder](./meta-windmill-index-79.md) of the flow), runs the flow and sees the prompt automatically shown when running the flow.

<video
	className="border-2 rounded-lg object-cover w-full h-full"
	controls
	src="/videos/prompt_example.mp4"
/>

<br />

### Default args

As one of the return key of this step, return an object `default_args` that contains the default arguments of the form argument. e.g:

```ts
//this assumes the Form tab has a string field named "foo" and a checkbox named "bar"

import * as wmill from 'npm:windmill-client@^1.158.2';

export async function main() {
	// if no argument is passed, if user is logged in, it will use the user's username
	const resumeUrls = await wmill.getResumeUrls('approver1');

	// send the resumeUrls to the recipient or see Prompt section above

	return {
		default_args: {
			foo: 'foo',
			bar: true
		}
	};
}
```

Find this script on [Windmill Hub](https://hub.windmill.dev/scripts/windmill/7121/default-arguments-in-approval-steps-windmill).

### Dynamics enums

As one of the return key of this step, return an object `enums` that contains the default options of the form argument. e.g:

```ts
//this assumes the Form tab has a string field named "foo"

import * as wmill from 'npm:windmill-client@^1.158.2';

export async function main() {
	// if no argument is passed, if user is logged in, it will use the user's username
	const resumeUrls = await wmill.getResumeUrls('approver1');

	// send the resumeUrls to the recipient or see Prompt section above

	return {
		enums: {
			foo: ['choice1', 'choice2']
		}
	};
}
```

Find this script on [Windmill Hub](https://hub.windmill.dev/scripts/windmill/7122/dynamics-enums-in-approval-step-windmill).

That's a powerful way of having dynamic enums as flow inputs. As shown in the video below, you can have a dynamic list of choices as a first step of a flow. Just run the flow and see the list of choices.

<video
	className="border-2 rounded-lg object-cover w-full h-full"
	controls
	src="/videos/dynamic_input.mp4"
/>

<br />

And below is the flow YAML used for this example:

```yaml
summary: ""
value:
  modules:
    - id: a
      value:
        type: rawscript
        content: >-
          import * as wmillClient from "windmill-client"


          export async function main() {
            // Constant array, but could come from dynamic source
            const customers: string[] = [
              "New York",
              "Los Angeles",
              "Chicago",
              "Houston",
              "Phoenix",
              "Philadelphia",
              "San Antonio",
              "San Diego",
              "Dallas",
              "San Jose"
            ];

            const resumeUrls = await wmillClient.getResumeUrls("approver1");

            // Remove duplicates and sort the customers array in alphabetical order
            const sortedCustomers = Array.from(new Set(customers)).sort();

            return {
              resume: resumeUrls['resume'],
              enums: {
                "Customers to send to": sortedCustomers
              },
              default_args: {
                "Customers to send to": sortedCustomers
              }
            }
          }
        language: bun
        input_transforms: {}
        is_trigger: false
      continue_on_error: false
      suspend:
        required_events: 1
        timeout: 1800
        hide_cancel: false
        resume_form:
          schema:
            properties:
              Customers to send to:
                items:
                  type: string
                type: array
                description: ""
            required: []
            order:
              - Customers to send to
      summary: Approval step with dynamic enum
    - id: b
      summary: Use the selected arguments
      value:
        type: rawscript
        content: |-
          # import wmill


          def main(x):
              return x
        language: python3
        input_transforms:
          x:
            type: javascript
            expr: resume["Customers to send to"]
        is_trigger: false
  same_worker: false
schema:
  $schema: https://json-schema.org/draft/2020-12/schema
  properties: {}
  required: []
  type: object
```

### Description

You can add a description to give clear instructions that support the whole range of [rich display rendering](./meta-windmill-index-33.md) (including markdown).

```ts
import * as wmill from "windmill-client@^1.158.2"

export async function main(approver?: string) {
  const urls = await wmill.getResumeUrls(approver)
  // send the urls to their intended recipients


  // if the resumeUrls are part of the response, they will be available to any persons having access
  // to the run page and allowed to be approved from there, even from non owners of the flow
  // self-approval is disablable in the suspend options
  return {
        ...urls,
        default_args: {},
        enums: {},
        description: {
      render_all: [
        {
          markdown: "# We have located the secret vault with thousands of H100"
        },
        {
          map: { lat: -30, lon: 10, markers: [{lat: -30, lon: 0, title: "It's here"}]}
        },
        "Just kidding"
      ]
    }
        // supports all formats from rich display rendering such as simple strings,
        // but also markdown, html, images, tables, maps, render_all, etc...
        // https://www.windmill.dev/docs/core_concepts/rich_display_rendering
  }
}
```

![Description](../assets/flows/description.png 'Description')

### Hide cancel button on approval page

By enabling this option, the cancel button will not be displayed on the approval page to force more complex patterns using forms with enums processed in ulterior steps.

![Hide cancel approval settings](../assets/flows/hide_cancel_approval.png 'Hide cancel approval settings')

![Hide cancel approval page](../assets/flows/hide_cancel_approval_page.png 'Hide cancel approval page')

Alternatively, adding the cancel url as a result of the stpep will also render a cancel button, providing the operator with an option to cancel the step. e.g:

```ts
import * as wmill from "windmill-client"

export async function main() {
    const urls = await wmill.getResumeUrls("approver1")

    return {
        resume: urls['resume'],
        cancel: urls['cancel'],
    }
}
```
