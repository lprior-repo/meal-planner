---
doc_id: meta/2_python_quickstart/index
chunk_id: meta/2_python_quickstart/index#chunk-1
heading_path: ["Python quickstart"]
chunk_type: prose
tokens: 487
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Python quickstart

> **Context**: import DocCard from '@site/src/components/DocCard';

In this quick start guide, we will write our first script in Python.


<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/QRf8C8qF7CY"
	title="Scripts quickstart"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br/>

This tutorial covers how to create a simple script through Windmill web IDE. See the dedicated page to [develop scripts locally](./meta-4_local_development-index.md) and other methods of [handling dependencies in Python](./meta-15_dependencies_in_python-index.md).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Local development"
		description="Develop from various environments such as your terminal, VS Code, and JetBrains IDEs."
		href="/docs/advanced/local_development"
	/>
	<DocCard
		title="Dependencies in Python"
		description="How to manage dependencies in Python scripts."
		href="/docs/advanced/dependencies_in_python"
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

- [Code](#code): for Python scripts, it must have at least a main function.
- [Settings](#settings): settings & metadata about the Script such as its path, summary, description, [JSON Schema](./meta-13_json_schema_and_parsing-index.md) of its inputs (inferred from its signature).

When stored in a code repository, these 2 parts are stored separately at `<path>.py` and `<path>.script.yaml`

Windmill automatically manages [dependencies](./meta-15_dependencies_in_python-index.md) for you. When you import libraries in your Python script, Windmill parses these top-level imports upon saving the script and automatically generates a list of dependencies. For automatic dependency installation, Windmill will only consider these top-level imports. It then spawns a dependency job to associate these PyPI packages with a lockfile, ensuring that the same version of the script is always executed with the same versions of its dependencies

[This](https://hub.windmill.dev/scripts/%22%22/1530/do-sentiment-analysis-with-nltk-%22%22) is a simple example of a script built in Python with Windmill:

```py
#import wmill
import nltk
from nltk.sentiment import SentimentIntensityAnalyzer
nltk.download("vader_lexicon")

def main(text: str = "Wow, NLTK is really powerful!"):
    return SentimentIntensityAnalyzer().polarity_scores(text)
```

In this quick start guide, we'll create a script that greets the operator running it.

From the Home page, click `+Script`. This will take you to the first step of script creation: [Metadata](./tutorial-script_editor-settings.md#metadata).
