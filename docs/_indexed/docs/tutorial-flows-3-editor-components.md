---
id: tutorial/flows/3-editor-components
title: "Flow editor components"
category: tutorial
tags: ["beginner", "flows", "tutorial", "flow"]
---

import DocCard from '@site/src/components/DocCard';

# Flow editor components

> **Context**: import DocCard from '@site/src/components/DocCard';

The Flow Builder has the following major components we will detail below:

- [Toolbar](#toolbar): the toolbar allows you to export the flow, configure the flow settings, and test the flow.
- [Settings](#settings): configure the flow settings.
- [Static Inputs](#static-inputs): view all flow static inputs.
- [Flow Inputs](#flow-inputs): view all flow inputs.
- [Action](#flow-actions): steps are the building blocks of a flow. They are the actions that will be executed when the flow is run.
- [Action editor](#action-editor): configure the action.

<br />

![Example of a flow](../assets/flows/flow_example.png)

> _Example of a [flow](https://hub.windmill.dev/flows/38/automatically-populate-crm-contact-details-from-simple-email) in Windmill._

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

## Settings

Each flow has metadata associated with it, enabling it to be defined and configured in depth.

### Summary

Summary (optional) is a short, human-readable summary of the Script. It will be displayed as a title across Windmill. If omitted, the UI will use the `path` by default.

#### Path

**Path** is the Flow's unique identifier that consists of the [flow's owner](./meta-16_roles_and_permissions-index.md#permissions-and-access-control), and the script's name.
The owner can be either a user, or a group of users ([folder](./meta-8_groups_and_folders-index.md#folders)).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Roles and permissions"
		description="Control access and manage permissions within your instance and workspaces."
		href="/docs/core_concepts/roles_and_permissions"
		color="teal"
	/>
	<DocCard
		title="Groups and folders"
		description="Groups and folders enable efficient permission management by grouping users with similar access levels."
		href="/docs/core_concepts/groups_and_folders"
		color="teal"
	/>
</div>

#### Description

This is where you can give instructions to users on how to run your Flow. It supports markdown.

![Flow Metadata](../assets/flows/flow_settings_metadata.png 'Flow Metadata')

![Flow Metadata Markdown](../assets/flows/flow_settings_metadata_markdown.png 'Flow Metadata Markdown')

### Advanced

![Flow Advanced](../assets/flows/flow_advanced_settings.png 'Flow Advanced')

The advanced section allows to configure the following:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Worker groups and tags"
		description="Worker Groups allow users to run scripts and flows on different machines with varying specifications."
		href="/docs/core_concepts/worker_groups"
	/>
	<DocCard
		color="teal"
		title="Caching"
		description="Caching a flow means caching the results of that flow for a certain duration."
		href="/docs/flows/cache"
	/>
	<DocCard
		color="teal"
		title="Early stop for flow"
		description="Stop early a flow based on a condition."
		href="/docs/flows/early_stop#early-stop-for-flow"
	/>
	<DocCard
		color="teal"
		title="Early return"
		description="Define a node at which the flow will return at for sync endpoints. The rest of the flow will continue asynchronously."
		href="/docs/flows/early_return"
	/>
	<DocCard
		color="teal"
		title="Shared Directory"
		description="The Shared Directory allows steps within a flow to share data by storing it in a designated folder"
		href="/docs/core_concepts/persistent_storage/within_windmill#shared-directory"
	/>
</div>

## Triggers

Flows can be triggered manually or in reaction to external events.

![Flow triggers](../assets/flows/flow_triggers.png 'Flow triggers')

See [Triggering flows](./meta-8_triggers-index.md) for more details.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Triggering flows"
		description="Trigger scripts and flows on-demand, by schedule or on external events."
		href="/docs/getting_started/triggers"
	/>
</div>

## Test flow

Test your current version of the flow with the `Test flow` button. This will opens a menu with an [auto-generated UI](./meta-6_auto_generated_uis-index.md) of your current configuration.

You can also test up to a certain step by clicking on an action (x) and then on `Test up to x`.

At last, you can directly [test a step](#test-this-step).

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/flow_test_flow.mp4"
/>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Instant preview & testing"
		description="Windmill allows users to see and test what they are building directly from the editor, even before deployment."
		href="/docs/core_concepts/instant_preview"
		color="teal"
	/>
</div>

## Static inputs

This menu centralizes the static inputs of every steps. It is akin to a file containing all constants. Modifying a value here modify it in the step input directly. It is especially useful when forking a flow to get an overview of all the variables to parametrize that are not exposed directly as flow inputs.

## Flow inputs

In this section, you will learn how to add and configure flow inputs.

There are three ways to add flow inputs:

- **Customize** the flow inputs.
- Using a **Request**: send a POST request to a specific endpoint to add a flow input.
- **Copying** the first step inputs.

Flows input are used to create an [auto-generated UI](./meta-6_auto_generated_uis-index.md) for the flow.

### Customize the flow inputs

To manually configure the flow inputs, click on `Input`. It will open a slider where you can configure the flow input.
You can add one by filling its name and click on `+ Add field`. For each field, you can configure the following:

- **Name**: the name of the flow input.
- **Type**: the type of the flow input: Integer, Number, String, Boolean, Array, Object, or Any.
- **Description**: the description of the flow input.
- **Custom Title**: will be displayed in the UI instead of the field name.
- **Placeholder**: will be displayed in the input field when the field is empty. If not set, the default value (directly set from the script code) will be used. The placeholder is disabled depending on the field type, format, etc.
- **Field settings**: advanced settings depending on the type of the field.

main function's arguments can be given advanced settings that will affect the inputs' [auto-generated UI](./meta-6_auto_generated_uis-index.md) and [JSON Schema](./meta-13_json_schema_and_parsing-index.md).

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/autogenerated_uis_flows.mp4"
/>

<br />

Below is the list of all available advanced settings for each argument type:

| Type     | Advanced Configuration                                                                                                                                                                                                                                                                       |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Integer  | Min and Max. Currency. Currency locale.                                                                                                                                                                                                                                                      |
| Number   | Min and Max. Currency. Currency locale.                                                                                                                                                                                                                                                      |
| String   | Min textarea rows. Disable variable picker. Is Password (will create a [variable](./meta-2_variables_and_secrets-index.md) when filled). Field settings: - File (base64) &#124; Enum &#124; Format: email, hostname, uri, uuid, ipv4, yaml, sql, date-time &#124; Pattern (Regex) |
| Boolean  | No advanced configuration for this type.                                                                                                                                                                                                                                                     |
| Resource | [Resource type](./meta-3_resources_and_types-index.md).                                                                                                                                                                                                                           |
| Object   | Object properties, or a Template (path to a [`json_schema` resource](./meta-3_resources_and_types-index.md#json-schema-resources)) that contains a JSON schema with the properties.                                                                                                                                                                 |
| Array    | - Items are strings &#124; Items are strings from an enum &#124; Items are objects (JSON) &#124; Items are numbers &#124; Items are bytes                                                                                                                                                    |
| Any      | No advanced configuration for this type.                                                                                                                                                                                                                                                     |

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Auto-generated UIs"
		description="Windmill creates auto-generated user interfaces for scripts and flows based on their parameters."
		href="/docs/core_concepts/auto_generated_uis"
		color="teal"
	/>
	<DocCard
		title="JSON schema and parsing"
		description="JSON Schemas are used for defining the input specification for scripts and flows, and specifying resource types."
		href="/docs/core_concepts/json_schema_and_parsing"
		color="teal"
	/>
</div>

### Using a request

For this example, we will use the following flow at path: `u/test-user/my_flow`.

You can send a POST request to the following endpoint with a payload to add a flow input: the payload will be interpreted to extract the flow input.

For example, using CURL:

```bash
curl -X POST https://app.windmill.dev/api/w/windmill-labs/capture_u/u/test-user/my_flow \
   -H 'Content-Type: application/json' \
   -d '{"foo": 42}'
```

The flow input will be added with the following properties:

- **Name**: foo
- **Type**: Integer
- **Default value**: 42

### Copying the first step inputs

To copy the first step inputs, click on the `First step inputs` button.

## Flow actions

An action script is simply a script that is neither a [trigger](./concept-flows-10-flow-trigger.md) nor an [approval](./tutorial-flows-11-flow-approval.md)
script. Those are the majority of the scripts.

There are two ways to create an action script:

- Write it directly in the flow editor.
- Import it from the Hub.
- Import it from the workspace.

## Inline action script

You can either create a new action script in:

- [Python](./meta-2_python_quickstart-index.md): Windmill provides a Python 3.11 environment.
- [TypeScript](./meta-1_typescript_quickstart-index.md): Windmill uses Deno as the TypeScript runtime.
- [Go](./meta-3_go_quickstart-index.md).
- [Bash](./meta-4_bash_quickstart-index.md).
- [Nu](./meta-4_bash_quickstart-index.md).
- Any language [running any docker container](./meta-7_docker-index.md) through Windmill's bash support.

There are special kinds of scripts, [SQL and query languages](./meta-5_sql_quickstart-index.md):

- Postgres
- MySQL
- MS SQL
- BigQuery
- Snowflake

- [Rest](./meta-6_rest_grapqhql_quickstart-index.md)
- [GrapQL](./meta-6_rest_grapqhql_quickstart-index.md)
- [Powershell](./meta-4_bash_quickstart-index.md)

These are essentially TypeScript template to easily write queries to a database.

### Triggering an action script from the Hub

You can refer to and trigger an action script from the [Hub](https://hub.windmill.dev/). You also have the possibility to fork it (copy it as an inline script) directly to modify its behavior.

### Triggering an action script from the workspace

You can refer to and trigger an action script from the workspace. Similar to the previous section, you can copy the script to an inline flow script and modify it.

![Flow action](../assets/flows/flow_new_action.png.webp)

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


## See Also

- [Toolbar](#toolbar)
- [Settings](#settings)
- [Static Inputs](#static-inputs)
- [Flow Inputs](#flow-inputs)
- [Action](#flow-actions)
