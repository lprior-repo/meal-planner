---
doc_id: meta/openflow/index
chunk_id: meta/openflow/index#chunk-1
heading_path: ["OpenFlow"]
chunk_type: prose
tokens: 196
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# OpenFlow Spec

> **Context**: import DocCard from '@site/src/components/DocCard';

OpenFlow is an open standard for defining "Flows". Flows are directed
graphs - [directed acyclic graphs](https://en.wikipedia.org/wiki/Directed_acyclic_graph) to be exact - in which every node represents
a step of computation. In other words, it is a declarative model for chaining
scripts.

Windmill is the open-source reference implementation for it, providing a UI
to build Flows and highly scalable executors. However, everyone is welcome to
build upon it and to develop new UIs that target OpenFlow, or create new
executors.

Flows can be shared and showcased on
[Windmill Hub](https://hub.windmill.dev/flows). To see an example of an OpenFlow
in practice, go to the Hub and pick a Flow (e.g
[Upon new user sign up, check for existence in postgres, hash password, add record to postgres and Airtable, send an email to new user](https://hub.windmill.dev/flows/23/)),
then select the JSON tab to see its specification.
