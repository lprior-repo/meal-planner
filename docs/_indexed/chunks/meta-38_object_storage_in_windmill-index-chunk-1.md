---
doc_id: meta/38_object_storage_in_windmill/index
chunk_id: meta/38_object_storage_in_windmill/index#chunk-1
heading_path: ["Object storage in Windmill (S3)"]
chunk_type: prose
tokens: 158
summary: "import Tabs from '@theme/Tabs';"
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';
import DocCard from '@site/src/components/DocCard';

# Object storage in Windmill (S3)

> **Context**: import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem'; import DocCard from '@site/src/components/DocCard';

Instance and workspace object storage are different from using [S3 resources](../../integrations/s3.mdx) within scripts, flows, and apps, which is free and unlimited.

At the [workspace level](#workspace-object-storage), what is exclusive to the [Enterprise](/pricing) version is using the integration of Windmill with S3 that is a major convenience layer to enable users to read and write from S3 without having to have access to the credentials.

Additionally, for [instance integration](#instance-object-storage), the Enterprise version offers advanced features such as large-scale log management and distributed dependency caching.

![Object storage in Windmill](./object_storage_in_windmill.png 'Object storage in Windmill')
