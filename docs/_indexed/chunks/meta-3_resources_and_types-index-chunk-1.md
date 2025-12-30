---
doc_id: meta/3_resources_and_types/index
chunk_id: meta/3_resources_and_types/index#chunk-1
heading_path: ["Resources and resource types"]
chunk_type: prose
tokens: 328
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Resources and resource types

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

Resources are rich objects in JSON that allow to store configuration and credentials.

In Windmill, Resources represent connections to third-party systems. Resources are a good way to define a
connection to a frequently used third-party system such as a database. Think of
Resources as a structured way to store configuration and credentials, and access them from scripts.

Each Resource has a **Resource Type** (RT for short) - for example [MySQL](https://hub.windmill.dev/resource_types/111/mysql),
[MongoDB](https://hub.windmill.dev/resource_types/22/mongodb), [OpenAI](https://hub.windmill.dev/resource_types/61/openai), etc. - that defines the schema that the resource of this type
needs to implement. Schemas implement the
[JSON Schema specification](https://json-schema.org/).

![Recap Resources and Types](./recap_resources_and_types.png 'Recap Resources and Types')

While resources store configuration and credentials for connections, [Assets](./meta-52_assets-index.md) track data flows and visualize datasets. Assets automatically detect when you reference [S3 objects](./meta-38_object_storage_in_windmill-index.md#workspace-object-storage) (`s3://storage/path/to/file.csv`) or resources (`res://path/to/resource`) directly in your code, creating a visual representation of your data pipeline. This helps you understand how data moves through your workflows and identify dependencies between different data sources.

:::tip

Check our [list of integrations](../../integrations/0_integrations_on_windmill.mdx) (or, pre-made resource types). If one is missing, this very page details how to [create your own](#create-a-resource-type).

:::

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="List of integrations"
		description="Windmill provides a framework to easily add integrations."
		href="/docs/integrations/integrations_on_windmill"
	/>
	<DocCard
		title="JSON Schema"
		description="JSON Schema is a declarative language that allows you to annotate and validate JSON documents."
		href="https://json-schema.org/"
		target="_blank"
	/>
</div>
