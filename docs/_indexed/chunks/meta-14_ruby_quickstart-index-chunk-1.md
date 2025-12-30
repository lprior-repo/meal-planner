---
doc_id: meta/14_ruby_quickstart/index
chunk_id: meta/14_ruby_quickstart/index#chunk-1
heading_path: ["Ruby quickstart"]
chunk_type: prose
tokens: 478
summary: "import DocCard from '@site/src/components/DocCard';"
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
