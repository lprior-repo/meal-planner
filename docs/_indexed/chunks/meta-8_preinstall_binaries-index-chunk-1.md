---
doc_id: meta/8_preinstall_binaries/index
chunk_id: meta/8_preinstall_binaries/index#chunk-1
heading_path: ["Preinstall binaries"]
chunk_type: prose
tokens: 124
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Preinstall binaries

> **Context**: import DocCard from '@site/src/components/DocCard';

[Workers](./meta-9_worker_groups-index.md) in Windmill can preinstall binaries. This allows them to execute these binaries in subprocesses or directly within bash. While some common binaries like npm, aws-cli, kubectl, and helm are already present in the standard images, you can add more by extending the base image of Windmill.

:::tip Init scripts

For an efficient way to preinstall binaries without the need to modify the base image, see [Init scripts](#init-scripts).

:::

Below are the steps and examples to extend the base image:

```dockerfile
FROM ghcr.io/windmill-labs/windmill:main
