---
doc_id: meta/1_self_host/index
chunk_id: meta/1_self_host/index#chunk-1
heading_path: ["Self-host"]
chunk_type: prose
tokens: 315
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Self-host Windmill

> **Context**: import DocCard from '@site/src/components/DocCard';

Self-host Windmill on your own infrastructure.

For small setups, use [Docker](#docker) and Docker Compose on a single instance.
For larger and production use-cases, use our [Helm chart](#helm-chart) to deploy on Kubernetes.
You can also run [Windmill workers on Windows](../../misc/17_windows_workers/index.mdx) without Docker.

![Self-hosted Windmill](./self_hosted_windmill.png 'Self-hosted Windmill')

> Example of a self-hosted Windmill instance on [localhost](#docker).

<br />

Windmill itself just requires 3 components:

- A Postgres database, which contains the entire state of Windmill, including the job queue.
- The Windmill container running in server mode (and replicated for high availability). It serves both the frontend and the API. It needs to connect to the database and is what is exposed publicly to serve the frontend. It does not need to communicate to the workers directly.
- The Windmill container running in worker mode (and replicated to handle more job throughput). It needs to connect to the database and does not communicate to the servers.

There are 3 optional components:

- Windmill LSP to provide intellisense on the [Monaco web Editor](../../code_editor/index.mdx).
- Windmill [Multiplayer](./meta-7_multiplayer-index.md) ([Cloud & Enterprise Selfhosted only](/pricing)) to provide real time collaboration.
- A reverse proxy (caddy in our [Docker compose](#docker)) to the Windmill server, LSP and multiplayer in order to expose a single port to the outside world.

The docker-compose file [below](#docker) uses all six components, and we recommend handling TLS termination outside of the provided Caddy service..
