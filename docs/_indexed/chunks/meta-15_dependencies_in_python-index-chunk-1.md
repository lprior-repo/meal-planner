---
doc_id: meta/15_dependencies_in_python/index
chunk_id: meta/15_dependencies_in_python/index#chunk-1
heading_path: ["Dependencies in Python"]
chunk_type: prose
tokens: 250
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Dependencies in Python

> **Context**: import DocCard from '@site/src/components/DocCard';

In Windmill [standard mode](#lockfile-per-script-inferred-from-imports-standard), dependencies in [Python](./meta-1_typescript_quickstart-index.md) are handled directly within their scripts without the need to manage separate dependency files.
From the import lines, Windmill automatically handles the resolution and caching of the script dependencies to ensure fast and consistent execution (this is standard mode).

There are however methods to have more control on your dependencies:
- Leveraging [standard mode](#lockfile-per-script-inferred-from-imports-standard) on [web IDE](#web-ide) or [locally](#cli).
- Using [PEP-723 inline script metadata](#pep-723-inline-script-metadata) for standardized dependency specification.
- Overriding dependencies [providing a requirements.txt](#lockfile-per-script-inferred-from-a-requirementstxt).

Moreover, there are other tricks, compatible with the methodologies mentioned above:
- [Sharing common logic with Relative Imports](#sharing-common-logic-with-relative-imports).
- [Pinning dependencies and requirements](#pinning-dependencies-and-requirements).
- [Private PyPI Repository](#private-pypi-repository).
- [Python runtime settings](#python-runtime-settings).

To learn more about how dependencies from other languages are handled, see [Dependency management & imports](./meta-6_imports-index.md).

![Dependency management & imports](../6_imports/dependency_management.png "Dependency management & imports")

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Dependency management & imports"
		description="Windmill's strength lies in its ability to run scripts without having to manage a requirements.txt directly."
		href="/docs/advanced/imports"
	/>
	<DocCard
		title="Dependencies in TypeScript"
		description="How to manage dependencies in TypeScript scripts."
		href="/docs/advanced/dependencies_in_typescript"
	/>
</div>
