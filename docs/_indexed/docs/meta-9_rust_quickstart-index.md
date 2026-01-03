---
id: meta/9_rust_quickstart/index
title: "Rust quickstart"
category: meta
tags: ["9_rust_quickstart", "rust", "advanced", "meta"]
---

import DocCard from '@site/src/components/DocCard';

# Rust quickstart

> **Context**: import DocCard from '@site/src/components/DocCard';

In this quick start guide, we will write our first script in [Rust](https://www.rust-lang.org/).

![Editor for Rust](./editor_rust.png "Script in Rust")

This tutorial covers how to create a simple script through Windmill web IDE. See the dedicated page to [develop scripts locally](./meta-4_local_development-index.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Local development"
		description="Develop from various environments such as your terminal, VS Code, and JetBrains IDEs."
		href="/docs/advanced/local_development"
	/>
</div>

Scripts are the basic building blocks in Windmill. They can be [run and scheduled](./meta-8_triggers-index.md) as standalone, chained together to create [Flows](./tutorial-flows-1-flow-editor.md) or displayed with a personalized User Interface as [Apps](./meta-7_apps_quickstart-index.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Script editor"
		description="All the details on scripts."
		href="/docs/script_editor"
	/>
	<DocCard
		title="Triggers"
		description="Trigger scripts and flows on-demand, by schedule or on external events."
		href="/docs/getting_started/triggers"
	/>
</div>

Scripts consist of 2 parts:

- [Code](#code): for Rust scripts, it must have at least a main function.
- [Settings](#settings): settings & metadata about the Script such as its path, summary, description, [JSON Schema](./meta-13_json_schema_and_parsing-index.md) of its inputs (inferred from its signature).

When stored in a code repository, these 2 parts are stored separately at `<path>.rs` and `<path>.script.yaml`

Windmill automatically manages [dependencies](./meta-6_imports-index.md) for you. When you import libraries in your Rust script, Windmill parses these imports upon saving the script and automatically generates a list of dependencies. It then spawns a dependency job to associate these PyPI packages with a lockfile, ensuring that the same version of the script is always executed with the same versions of its dependencies.

From the Home page, click `+Script`. This will take you to the first step of script creation: [Metadata](./tutorial-script_editor-settings.md#metadata).

## Settings

![New script](../../../../static/images/script_languages.png "New script")

As part of the [settings](./tutorial-script_editor-settings.md) menu, each script has metadata associated with it, enabling it to be defined and configured in depth.

- **Summary** (optional) is a short, human-readable summary of the Script. It will be displayed as a title across Windmill. If omitted, the UI will use the `path` by default.
- **Path** is the Script's unique identifier that consists of the [script's owner](./meta-16_roles_and_permissions-index.md), and the script's name. The owner can be either a user, or a group ([folder](./meta-8_groups_and_folders-index.md#folders)).
- **Description** is where you can give instructions through the [auto-generated UI](./meta-6_auto_generated_uis-index.md) to users on how to run your Script. It supports markdown.
- **Language** of the script.
- **Script kind**: Action (by default), [Trigger](./concept-flows-10-flow-trigger.md), [Approval](./tutorial-flows-11-flow-approval.md), [Error handler](./tutorial-flows-7-flow-error-handler.md) or [Preprocessor](./meta-43_preprocessors-index.md). This acts as a tag to filter appropriate scripts from the [flow editor](./meta-6_flows_quickstart-index.md).

This menu also has additional settings on [Runtime](./tutorial-script_editor-settings.md#runtime), [Generated UI](#generated-ui) and [Triggers](./tutorial-script_editor-settings.md#triggers).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Settings"
		description="Each script has metadata & settings associated with it, enabling it to be defined and configured in depth."
		href="/docs/script_editor/settings"
	/>
</div>

Now click on the code editor on the left side.

## Code

Windmill provides an online editor to work on your Scripts. The left-side is
the editor itself. The right-side [previews the UI](./meta-6_auto_generated_uis-index.md) that Windmill will
generate from the Script's signature - this will be visible to the users of the
Script. You can preview that UI, provide input values, and [test your script](#instant-preview--testing) there.

![Editor for Rust](./editor_rust.png "Editor for Rust")

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Code editor"
		description="The code editor is Windmill's integrated development environment."
		href="/docs/code_editor"
	/>
	<DocCard
		title="Auto-generated UIs"
		description="Windmill creates auto-generated user interfaces for scripts and flows based on their parameters."
		href="/docs/core_concepts/auto_generated_uis"
	/>
</div>

As we picked `rust` for this example, Windmill provided some rust
boilerplate. Let's take a look:

```rust
//! Add dependencies in the following partial Cargo.toml manifest
//!
//! ```cargo
//! [dependencies]
//! anyhow = "1.0.86"
//! rand = "0.7.2"
//! # wmill = "^1.0"  # Windmill client SDK for API interactions
//! ```
//!
//! Note that serde is used by default with the `derive` feature.
//! You can still reimport it if you need additional features.

use anyhow::anyhow;
use rand::seq::SliceRandom;
use serde::Serialize;

#[derive(Serialize, Debug)]
struct Ret {
    msg: String,
    number: i8,
}

fn main(who_to_greet: String, numbers: Vec<i8>) -> anyhow::Result<Ret> {
    println!(
        "Person to greet: {} -  numbers to choose: {:?}",
        who_to_greet, numbers
    );
    Ok(Ret {
        msg: format!("Greetings {}!", who_to_greet),
        number: *numbers
            .choose(&mut rand::thread_rng())
            .ok_or(anyhow!("There should be some numbers to choose from"))?,
    })
}
```

In Windmill, scripts need to have a `main` function that will be the script's
entrypoint. There are a few important things to note about the `main`.

- The main arguments are used for generating
  1.  the [input spec](./meta-13_json_schema_and_parsing-index.md) of the Script
  2.  the [frontend](./meta-6_auto_generated_uis-index.md) that you see when running the Script as a standalone app.
- Type annotations are used to generate the UI form, and help pre-validate
  inputs. While not mandatory, they are highly recommended. You can customize
  the UI in later steps (but not change the input type!).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="JSON schema and parsing"
		description="JSON Schemas are used for defining the input specification for scripts and flows, and specifying resource types."
		href="/docs/core_concepts/json_schema_and_parsing"
	/>
</div>

Packages can be installed using cargo. Just add the dependencies you need in the partial Cargo.toml manifest and Windmill will install them for you:

```rust
//! ```cargo
//! [dependencies]
//! anyhow = "1.0.86"
//! rand = "0.7.2"
//! ```
```

## Instant preview & testing


Look at the UI preview on the right: it was updated to match the input
signature. Run a test (`Ctrl` + `Enter`) to verify everything works.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/auto_g_ui_landing.mp4"
/>

## Generated UI

From the Settings menu, the "Generated UI" tab lets you customize the script's arguments.

The UI is generated from the Script's main function signature, but you can add additional constraints here. For example, we could use the `Customize property`: add a regex by clicking on `Pattern` to make sure users are providing a name with only alphanumeric characters: `^[A-Za-z0-9]+$`. Let's still allow numbers in case you are some tech billionaire's kid.

![Advanced settings for rust](./customize_rust.png "Advanced settings for rust")

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Script kind"
		description="You can attach additional functionalities to Scripts by specializing them into specific Script kinds."
		href="/docs/script_editor/script_kinds"
	/>
	<DocCard
		title="Generated UI"
		description="main function's arguments can be given advanced settings that will affect the inputs' auto-generated UI and JSON Schema."
		href="/docs/script_editor/customize_ui"
	/>
</div>

## Run!

We're done! Now let's look at what users of the script will do. Click on the [Deploy](./meta-0_draft_and_deploy-index.md) button
to load the script. You'll see the user input form we defined earlier.

Note that Scripts are [versioned](./meta-34_versioning-index.md#script-versioning) in Windmill, and
each script version is uniquely identified by a hash.

Fill in the input field, then hit "Run". You should see a run view, as well as
your logs. All script runs are also available in the [Runs](./meta-5_monitor_past_and_future_runs-index.md) menu on
the left.

![Run in rust](./run_rust.png "Run in rust")

You can also choose to [run the script from the CLI](./meta-3_cli-index.md) with the pre-made Command-line interface call.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Triggers"
		description="Trigger scripts and flows on-demand, by schedule or on external events."
		href="/docs/getting_started/triggers"
	/>
</div>

## Caching

Every bundle on Rust is cached on disk by default. Furtherfore if you use the [Distributed cache storage](../../../misc/13_s3_cache/index.mdx), it will be available to every other worker, allowing fast startup for every worker.

## Fast development iteration

Windmill optimizes Rust development for faster iteration cycles. When developing and testing scripts:

- **Debug mode builds**: Preview and test runs use debug mode compilation, which is significantly faster to build but produces unoptimized binaries
- **Shared build directory**: All Rust scripts share a common build directory, reducing redundant compilation and improving cache efficiency
- **Release mode deployment**: When scripts are deployed to production, they are compiled in release mode for optimal performance

This approach provides the best of both worlds - fast development cycles during script creation and testing, with optimized performance in production deployments.

## What's next?

This script is a minimal working example, but there's a few more steps that can be useful in a real-world use case:

- Pass [variables and secrets](./meta-2_variables_and_secrets-index.md)
  to a script.
- Connect to [resources](./meta-3_resources_and_types-index.md).
- Use the [Rust client SDK](./ops-2_clients-rust-client.md) to interact with Windmill's API from your applications.
- [Trigger that script](./meta-8_triggers-index.md) in many ways.
- Compose scripts in [Flows](./tutorial-flows-1-flow-editor.md) or [Apps](../../../apps/0_app_editor/index.mdx).
- You can [share your scripts](../../../misc/1_share_on_hub/index.md) with the community on [Windmill Hub](https://hub.windmill.dev). Once
  submitted, they will be verified by moderators before becoming available to
  everyone right within Windmill.

Scripts are immutable and there is an hash for each deployment of a given script. Scripts are never overwritten and referring to a script by path is referring to the latest deployed hash at that path.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Versioning"
		description="Scripts, when deployed, can have a parent script identified by its hash."
		href="/docs/core_concepts/versioning#script-versioning"
	/>
</div>

For each script, a UI is autogenerated from the jsonchema inferred from the script signature, and can be customized further as standalone or embedded into rich UIs using the [App builder](./meta-7_apps_quickstart-index.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Auto-generated UIs"
		description="Windmill creates auto-generated user interfaces for scripts and flows based on their parameters."
		href="/docs/core_concepts/auto_generated_uis"
	/>
	<DocCard
		title="Generated UI"
		description="main function's arguments can be given advanced settings that will affect the inputs' auto-generated UI and JSON Schema."
		href="/docs/script_editor/customize_ui"
	/>
</div>

In addition to the UI, sync and async [webhooks](./meta-4_webhooks-index.md) are generated for each deployment.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Webhooks"
		description="Trigger scripts and flows from webhooks."
		href="/docs/core_concepts/webhooks"
	/>
</div>

## See Also

- [Editor for Rust](./editor_rust.png "Script in Rust")
- [develop scripts locally](../../../advanced/4_local_development/index.mdx)
- [run and scheduled](../../8_triggers/index.mdx)
- [Flows](../../../flows/1_flow_editor.mdx)
- [Apps](../../7_apps_quickstart/index.mdx)
