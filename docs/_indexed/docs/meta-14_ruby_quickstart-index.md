---
id: meta/14_ruby_quickstart/index
title: "Ruby quickstart"
category: meta
tags: ["advanced", "14_ruby_quickstart", "ruby", "meta"]
---

import DocCard from '@site/src/components/DocCard';

# Ruby quickstart

> **Context**: import DocCard from '@site/src/components/DocCard';

In this quick start guide, we will write our first script in [Ruby](https://www.ruby-lang.org/).

<div className="mb-4">
	<video
		className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
		autoPlay
		loop
		controls
		src="/videos/ruby.mp4"
		alt="Ruby Demo"
		muted
	/>
</div>


<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Local development"
		description="Develop from various environments such as your terminal, VS Code, and JetBrains IDEs."
		href="/docs/advanced/local_development"
	/>
	<DocCard
		title="Dependencies in Ruby"
		description="How to manage dependencies in Ruby scripts."
		href="/docs/getting_started/scripts_quickstart/ruby#dependencies-management"
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

- [Code](#code): for Ruby scripts, they can optionally have a main function. Scripts without a main function will execute the entire file.
- [Settings](#settings): settings & metadata about the Script such as its path, summary, description, [jsonschema](./meta-13_json_schema_and_parsing-index.md) of its inputs (inferred from its signature).

When stored in a code repository, these 2 parts are stored separately at `<path>.rb` and `<path>.script.yaml`

Windmill automatically manages [dependencies](/docs/getting_started/scripts_quickstart/ruby#dependencies-management) for you.
When you use gems in your Ruby script through `gemfile` blocks (compatible with bundler/inline syntax),
Windmill parses these dependencies upon saving the script and automatically generates a Gemfile.lock,
ensuring that the same version of the script is always executed with the same versions of its dependencies.
More to it, to remove vendor lock-in barrier you have ability to extract the lockfile and use it outside Windmill if you want.

This is a simple example of a script built in Ruby with Windmill:

```ruby
require 'windmill/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'httparty'
  gem 'json'
end

def main(url: "https://httpbin.org/get", message: "Hello from Windmill!")
  response = HTTParty.get(url, query: { message: message })
  return {
    status: response.code,
    body: JSON.parse(response.body),
    message: "Request completed successfully"
  }
end
```

In this quick start guide, we'll create a script that greets the operator running it.

From the Home page, click `+Script`. This will take you to the first step of script creation: Metadata.

## Settings

![Ruby Settings](./ruby-settings.png "Ruby Settings")

As part of the [settings](./tutorial-script_editor-settings.md) menu, each script has metadata associated with it, enabling it to be defined and configured in depth.

- **Path** is the Script's unique identifier that consists of the
  [script's owner](./meta-16_roles_and_permissions-index.md), and the script's name.
  The owner can be either a user, or a group ([folder](./meta-8_groups_and_folders-index.md#folders)).
- **Summary** (optional) is a short, human-readable summary of the Script. It
  will be displayed as a title across Windmill. If omitted, the UI will use the `path` by
  default.
- **Language** of the script.
- **Description** is where you can give instructions through the [auto-generated UI](./meta-6_auto_generated_uis-index.md)
  to users on how to run your Script. It supports markdown.
- **Script kind**: Action (by default), [Trigger](./concept-flows-10-flow-trigger.md), [Approval](./tutorial-flows-11-flow-approval.md) or [Error handler](./tutorial-flows-7-flow-error-handler.md). This acts as a tag to filter appropriate scripts from the [flow editor](./meta-6_flows_quickstart-index.md).

This menu also has additional settings on [Runtime](./tutorial-script_editor-settings.md#runtime), [Generated UI](#generated-ui) and [Triggers](./tutorial-script_editor-settings.md#triggers).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Settings"
		description="Each script has metadata & settings associated with it, enabling it to be defined and configured in depth."
		href="/docs/script_editor/settings"
	/>
</div>

Now click on the code editor on the left side, and let's build our Hello World!

## Code

Windmill provides an online editor to work on your Scripts. The left-side is
the editor itself. The right-side [previews the UI](./meta-6_auto_generated_uis-index.md) that Windmill will
generate from the Script's signature - this will be visible to the users of the
Script. You can preview that UI, provide input values, and [test your script](#instant-preview--testing) there.

![Ruby Editor](./ruby-startpage.png "Ruby Editor")

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

As we picked `ruby` for this example, Windmill provided some Ruby
boilerplate. Let's take a look:

```ruby
## Builtin mini windmill client
require 'windmill/mini'
require 'windmill/inline'

## Add your gem dependencies here using gemfile syntax
gemfile do
  source 'https://rubygems.org'
  gem 'httparty', '~> 0.21'
  gem 'json', '~> 2.6'
end

## You can import any gem from RubyGems.
## See here for more info: https://www.windmill.dev/docs/advanced/dependencies_in_ruby

def main(
  name = "Nicolas Bourbaki",
  age = 42,
  obj = { "even" => "hashes" },
  l = ["or", "arrays!"]
)
  puts "Hello World and a warm welcome especially to #{name}"
  puts "and its acolytes.. #{age} #{obj} #{l}"

  # retrieve variables, resources using built-in methods
  begin
		# Imported from windmill mini client
    secret = get_variable("f/examples/secret")
  rescue => e
    secret = "No secret yet at f/examples/secret!"
  end
  puts "The variable at `f/examples/secret`: #{secret}"

  # fetch context variables
  user = ENV['WM_USERNAME']

  # return value is converted to JSON
  return {
    "splitted" => name.split,
    "user" => user,
    "message" => "Hello from Ruby!"
  }
end
```

In Windmill, scripts can optionally have a `main` function that will be the script's
entrypoint. If no main function is defined, the entire script will be executed. There are a few important things to note about the `main` function:

- The main arguments are used for generating
  1.  the [input spec](./meta-13_json_schema_and_parsing-index.md) of the Script
  2.  the [frontend](./meta-6_auto_generated_uis-index.md) that you see when running the Script as a standalone app.
- Default values are used to infer argument types and generate the UI form. String defaults create string inputs, numeric defaults create number inputs, hash/array defaults create appropriate JSON inputs, etc.
- You can customize the UI in later steps (but not change the input type!).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="JSON schema and parsing"
		description="JSON Schemas are used for defining the input specification for scripts and flows, and specifying resource types."
		href="/docs/core_concepts/json_schema_and_parsing"
	/>
</div>

The first import line imports the Windmill Ruby client, which provides access to built-in methods for accessing
[variables](./meta-2_variables_and_secrets-index.md) and
[resources](./meta-3_resources_and_types-index.md).

Back to our Hello World. We can clean up the boilerplate, change the
main to take in the user's name. Let's also return the `name`, maybe we can use
this later if we use this Script within a [flow](./tutorial-flows-1-flow-editor.md) or [app](../../../apps/0_app_editor/index.mdx) and need to pass its result on.

```ruby
def main(name = "World")
  puts "Hello #{name}! Greetings from Ruby!"
  return name
end
```

## Instant preview & testing

Look at the UI preview on the right: it was updated to match the input
signature. Run a test (`Ctrl` + `Enter`) to verify everything works.

You can change how the UI behaves by changing the main signature. For example,
if you remove the default for the `name` argument, the UI will consider this field
as required.

```ruby
def main(name)
```

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Instant preview & testing"
		description="On top of its integrated editors, Windmill allows users to see and test what they are building directly from the editor, even before deployment."
		href="/docs/core_concepts/instant_preview"
	/>
</div>

Now let's go to the last step: the "Generated UI" settings.

## Generated UI

From the Settings menu, the "Generated UI" tab lets you customize the script's arguments.

The UI is generated from the Script's main function signature, but you can add additional constraints here. For example, we could use the `Customize property`: add a regex by clicking on `Pattern` to make sure users are providing a name with only alphanumeric characters: `^[A-Za-z0-9]+$`. Let's still allow numbers in case you are some tech billionaire's kid.

![Generated UI](./customize-ui.png "Generated UI")

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

You can also choose to [run the script from the CLI](./meta-3_cli-index.md) with the pre-made Command-line interface call.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Triggers"
		description="Trigger scripts and flows on-demand, by schedule or on external events."
		href="/docs/getting_started/triggers"
	/>
</div>

## Dependencies management

Ruby dependencies are managed using a `gemfile` block that is fully compatible with bundler/inline syntax. The gemfile block must include a single global source:

```ruby
require 'windmill/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'httparty', '~> 0.21'
  gem 'redis', '>= 4.0'
  gem 'activerecord', '7.0.0'
  gem 'pg', require: 'pg'
  gem 'dotenv', require: false
end
```

### Private gem sources

You can use private gem repositories using different syntax options:

**Option 1: Per-gem source specification**
```ruby
require 'windmill/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'httparty'
  gem 'private-gem', source: 'https://gems.example.com'
end
```

**Option 2: Source block syntax**
```ruby
require 'windmill/inline'

gemfile do
  source 'https://rubygems.org'
  
  source 'https://gems.example.com' do
    gem 'private-gem-1'
    gem 'private-gem-2'
  end
end
```

For authentication with private sources, specify the source URL without credentials in your script. For [Enterprise Edition](/pricing) users, add the authenticated URL to Ruby repositories in instance settings. Navigate to **Instance Settings > Registries > Ruby Repos** and add:

```
https://admin:123@gems.example.com/
```

![Ruby Private repos Instance Settings](./ruby-gems-instance-settings.png "Ruby Private repos Instance Settings")

Windmill will automatically match the source URL from your script with the authenticated URL from settings and handle authentication seamlessly.

### Network configuration

- **TLS/SSL**: Automatically handled as long as the remote certificate is trusted by the system
- **Proxy**: Proxy environment variables are automatically handled during lockfile generation, gem installation, and runtime stages

Windmill will automatically:
- Parse your gemfile block when you save the script
- Generate a Gemfile and Gemfile.lock
- Install dependencies in an isolated environment
- Cache dependencies for faster execution

## Caching

Every gem dependency in Ruby is cached on disk by default. Furthermore if you use the [Distributed cache storage](../../../misc/13_s3_cache/index.mdx), it will be available to every other worker, allowing fast startup for every worker.

## What's next?

This script is a minimal working example, but there's a few more steps that can be useful in a real-world use case:

- Pass [variables and secrets](./meta-2_variables_and_secrets-index.md)
  to a script.
- Connect to [resources](./meta-3_resources_and_types-index.md).
- [Trigger that script](./meta-8_triggers-index.md) in many ways.
- Compose scripts in [Flows](./tutorial-flows-1-flow-editor.md) or [Apps](../../../apps/0_app_editor/index.mdx).
- You can [share your scripts](../../../misc/1_share_on_hub/index.md) with the community on [Windmill Hub](https://hub.windmill.dev). Once
  submitted, they will be verified by moderators before becoming available to
  everyone right within Windmill.

Scripts are immutable and there is a hash for each deployment of a given script. Scripts are never overwritten and referring to a script by path is referring to the latest deployed hash at that path.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Versioning"
		description="Scripts, when deployed, can have a parent script identified by its hash."
		href="/docs/core_concepts/versioning#script-versioning"
	/>
</div>

For each script, a UI is autogenerated from the jsonschema inferred from the script signature, and can be customized further as standalone or embedded into rich UIs using the [App builder](./meta-7_apps_quickstart-index.md).

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

- [run and scheduled](../../8_triggers/index.mdx)
- [Flows](../../../flows/1_flow_editor.mdx)
- [Apps](../../7_apps_quickstart/index.mdx)
- [Code](#code)
- [Settings](#settings)
