---
doc_id: tutorial/flows/3-editor-components
chunk_id: tutorial/flows/3-editor-components#chunk-10
heading_path: ["Flow editor components", "Action editor"]
chunk_type: code
tokens: 1019
summary: "Action editor"
---

## Action editor

Windmill provide a web editor to write your scripts. It is available in the flow editor.

The script editor in split in three parts:

- [Header](#header): edit the summary of the script, navigate to advanced configuration.
- [Script editor](#script-editor): edit the code.
- [Step configuration/Test this step](#step-configurationtest-this-step): the bottom part is composed of three parts:
  - [Step input](#step-input): define the input of the step.
  - [Test this step](#test-this-step): test the step on its own.
  - [Advanced](#advanced): advanced configuration.

### Header

![Action editor header](../assets/flows/flow_action_editor_header.png.webp)

The header is composed of:

- **Summary**: edit the summary of the script.
- **Shortcuts**: shortcut to advanced configuration.
  1. [Retries](./ops-flows-14-retries.md): configure the number of retries and the delay between each retry.
  2. [Concurrency limit](./ref-flows-6-concurrency-limit.md): set concurrency limits to prevent exceeding the API Limit of the targeted API.
  3. [Cache](./tutorial-flows-4-cache.md): cache the results of a step for a specified time.
  4. [Early stop/Break](./concept-flows-2-early-stop.md): if defined, at the end of the step, the predicate expression will be evaluated to decide if the flow should stop early. Skipped flows are just a label useful to not see them in the runs page. If stop early is run within a forloop, it will just break the for-loop and have it stop at that iteration instead of stopping the whole flow.
  5. [Suspend](./tutorial-flows-11-flow-approval.md): if defined, at the end of the step, the flow will be suspended until it receives external requests to be resumed or canceled. This is most useful for implementing approval steps but can be used flexibly for other purpose. To get the resume urls, use `wmill.getResumeUrls()` in TypeScript, or `wmill.get_resume_urls()` in Python.
  6. [Sleep](./tutorial-flows-15-sleep.md): if defined, at the end of the step, the flow will sleep for a number of seconds before scheduling the next job (if any, no effect if the step is the last one). Sleeping is passive and does not consume any resources.
  7. [Mock](./concept-flows-5-step-mocking.md): when a step is mocked, it will immediately return the mocked value without performing any computation.

### Script editor

- Context var: add a context variable to the script.
- Var: add an input variable to the script.
- Resource: add a resource to the script.
- Reset: reset the script to its initial state.
- Assistant: reload the LSP assistant.
- Format: format the script. Can be triggerd on save (CTRL+S).
- Script: view hub or workspace script code.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Script editor"
		description="In Windmill, Scripts are the basis of all major features."
		href="/docs/script_editor"
	/>
</div>

### Step configuration/Test this step

The step configuration is composed of three parts:

- [Step input](#step-input): define the input of the step
- [Test this step](#test-this-step): test the step on its own
- [Advanced](#advanced): advanced configuration

#### Step input

![Step input](../assets/flows/flow_step_input.png.webp)

Inputs of a script can be defined in the step configuration. They can be configured in three ways:

- **Templatable string**: a templatable string is a string that can be templated with context variables. It is defined by wrapping the string with `${` and `}`. For example, `${context.var}` is a templatable string that will be replaced by the value of the context variable `var`.
- **Dynamic**: JS expression that will be evaluated at runtime. The expression can use context variables and input variables. For example, `context.var` is a dynamic expression that will be replaced by the value of the context variable `var`.
- **Static**: a static value that will be used as is. For example, `static value` is a static value that will be used as is.

#### Templatable string/Static

The templatable string and static value can be combined. For example, `${context.var} static value` is a templatable string that will be replaced by the value of the context variable `var` and then concatenated with the static value `static value`.

```js
`${context.var} static value`;
```

#### Dynamic

JS expression that will be evaluated at runtime.

```js
[1, 2, 3, 4].reduce((acc, val) => acc + val, 0);
```

#### Insert mode

There are two insert modes:

- **Append**: append a context variable, a flow input or a resource at the cursor position
- **Connect**: replace the current value by a context variable, a flow input or a resource

Clicking on a field will set the mode to "Append". Clicking on the "Connect" button will set the mode to "Connect".

#### Test this step

![Test this step](../assets/flows/flow_test_this_step.png.webp)

The test this step section allows to test the step on its own. You can set the input and run the script.
The result and logs are displayed on the left-hand side.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Instant preview & testing"
		description="Windmill allows users to see and test what they are building directly from the editor, even before deployment."
		href="/docs/core_concepts/instant_preview"
		color="teal"
	/>
</div>
