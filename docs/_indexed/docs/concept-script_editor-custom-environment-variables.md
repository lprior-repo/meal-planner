---
id: concept/script_editor/custom-environment-variables
title: "Custom environment variables"
category: concept
tags: ["concept", "script_editor", "custom"]
---

import DocCard from '@site/src/components/DocCard';

# Custom environment variables

> **Context**: import DocCard from '@site/src/components/DocCard';

In a self-hosted environment, Windmill allows you to set custom [environment variables](./meta-47_environment_variables-index.md) for your scripts. This feature is useful when a script needs an environment variable prior to the main function executing itself. For instance, some libraries in Go do some setup in the 'init' function that depends on environment variables.

To add a custom environment variable to a script in Windmill, you should follow this format: `<KEY>=<VALUE>`. Where `<KEY>` is the name of the environment variable and `<VALUE>` is the corresponding value of the environment variable.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Environment variables"
		description="Environment variables are used to configure the behavior of scripts and services, allowing for dynamic and flexible execution across different environments."
		href="/docs/core_concepts/environment_variables"
	/>
</div>


## See Also

- [environment variables](../core_concepts/47_environment_variables/index.mdx)
