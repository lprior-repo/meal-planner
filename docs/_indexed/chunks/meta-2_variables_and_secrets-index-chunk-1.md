---
doc_id: meta/2_variables_and_secrets/index
chunk_id: meta/2_variables_and_secrets/index#chunk-1
heading_path: ["Variables and secrets"]
chunk_type: prose
tokens: 144
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Variables and secrets

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

When writing scripts, you may want to reuse variables, or safely pass secrets to
scripts. You can do that with Variables. Windmill has user-defined variables
and contextual variables.

Variables are dynamic values that have a key associated to them and can be retrieved during the execution of a Script or Flow.

All Variables (not just secrets) are encrypted with a workspace specific symmetric key to avoid leakage.

There are 2 types of Variables in Windmill: user-defined and contextual (including environment variables).
