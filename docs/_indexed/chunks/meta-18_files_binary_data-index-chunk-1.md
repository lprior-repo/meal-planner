---
doc_id: meta/18_files_binary_data/index
chunk_id: meta/18_files_binary_data/index#chunk-1
heading_path: ["Handling files and binary data"]
chunk_type: prose
tokens: 143
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Handling files and binary data

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

In Windmill, JSON is the primary data format used for representing information.
Binary data, such as files, are not easy to handle. Windmill provides two options.

1. Have a dedicated storage for binary data: S3, Azure Blob, or Google Cloud Storage. Windmill has a first class integration with S3 buckets, Azure Blob containers, or Google Cloud Storage buckets.
2. If the above is not an option, there's always the possibility to store the binary as base64 encoded string.
