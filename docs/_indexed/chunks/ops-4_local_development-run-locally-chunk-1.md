---
doc_id: ops/4_local_development/run-locally
chunk_id: ops/4_local_development/run-locally#chunk-1
heading_path: ["Run locally"]
chunk_type: prose
tokens: 146
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Run locally

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

Windmill has [its own integrated development environment](../../code_editor/index.mdx). But for iteration, integration with CI/CD and testing purposes you may need to run a script locally that also interacts with Windmill (for example, to retrieve resources).
It will allow you to integrate Windmill with any testing framework.

To setup a local development environment for Windmill, see the dedicated [Local development page](./meta-4_local_development-index.md).

To run scripts locally, you will need to [fill out the context variables](#interacting-with-windmill-locally) that would otherwise be filled out by the Windmill runtime for you.
