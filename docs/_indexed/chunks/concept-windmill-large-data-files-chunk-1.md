---
doc_id: concept/windmill/large-data-files
chunk_id: concept/windmill/large-data-files#chunk-1
heading_path: ["Large data: S3, R2, MinIO, Azure Blob, Google Cloud Storage"]
chunk_type: prose
tokens: 198
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Large data: S3, R2, MinIO, Azure Blob, Google Cloud Storage

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

This page is part of our section on [Persistent storage & databases](./meta-windmill-index-25.md) which covers where to effectively store and manage the data manipulated by Windmill. Check that page for more options on data storage.

On heavier data objects & unstructured data storage, [Amazon S3](https://aws.amazon.com/s3/) (Simple Storage Service) and its alternatives [Cloudflare R2](https://www.cloudflare.com/developer-platform/r2/) and [MinIO](https://min.io/) as well as [Azure Blob Storage](https://azure.microsoft.com/en-us/products/storage/blobs) and [Google Cloud Storage](https://cloud.google.com/storage) are highly scalable and durable object storage services that provide secure, reliable, and cost-effective storage for a wide range of data types and use cases.

Windmill comes with a [native integration with S3, Azure Blob, and Google Cloud Storage](./meta-windmill-index-55.md), making them the recommended storage for large objects like files and binary data.
