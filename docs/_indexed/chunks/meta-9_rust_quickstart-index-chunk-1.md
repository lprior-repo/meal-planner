---
doc_id: meta/9_rust_quickstart/index
chunk_id: meta/9_rust_quickstart/index#chunk-1
heading_path: ["Rust quickstart"]
chunk_type: prose
tokens: 356
summary: "import DocCard from '@site/src/components/DocCard';"
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
