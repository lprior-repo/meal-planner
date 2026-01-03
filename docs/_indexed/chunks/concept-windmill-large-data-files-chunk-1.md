---
doc_id: concept/windmill/large-data-files
chunk_id: concept/windmill/large-data-files#chunk-1
heading_path: ["Large data: S3, R2, MinIO, Azure Blob, Google Cloud Storage"]
chunk_type: prose
tokens: 336
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Large data: S3, R2, MinIO, Azure Blob, Google Cloud Storage</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;; import Tabs from &apos;@theme/Tabs&apos;; import TabItem from &apos;@theme/TabItem&apos;;</description>
  <created_at>2026-01-02T19:55:27.594723</created_at>
  <updated_at>2026-01-02T19:55:27.594723</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Workspace object storage" level="2"/>
    <section name="Windmill integration with Polars and DuckDB for data pipelines" level="2"/>
    <section name="Use Amazon S3, R2, MinIO, Azure Blob, and Google Cloud Storage directly" level="2"/>
  </sections>
  <features>
    <feature>python_main</feature>
    <feature>workspace_object_storage</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="feature">meta/windmill/index-25</dependency>
    <dependency type="feature">meta/windmill/index-55</dependency>
    <dependency type="feature">meta/windmill/index-43</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./index.mdx</entity>
    <entity relationship="uses">../38_object_storage_in_windmill/index.mdx</entity>
    <entity relationship="uses">/pricing</entity>
    <entity relationship="uses">../11_persistent_storage/s3_infographics.png &apos;Workspace object storage infographic&apos;</entity>
    <entity relationship="uses">../38_object_storage_in_windmill/index.mdx</entity>
    <entity relationship="uses">../27_data_pipelines/index.mdx</entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>windmill,large,advanced,concept</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Large data: S3, R2, MinIO, Azure Blob, Google Cloud Storage

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

This page is part of our section on [Persistent storage & databases](./meta-windmill-index-25.md) which covers where to effectively store and manage the data manipulated by Windmill. Check that page for more options on data storage.

On heavier data objects & unstructured data storage, [Amazon S3](https://aws.amazon.com/s3/) (Simple Storage Service) and its alternatives [Cloudflare R2](https://www.cloudflare.com/developer-platform/r2/) and [MinIO](https://min.io/) as well as [Azure Blob Storage](https://azure.microsoft.com/en-us/products/storage/blobs) and [Google Cloud Storage](https://cloud.google.com/storage) are highly scalable and durable object storage services that provide secure, reliable, and cost-effective storage for a wide range of data types and use cases.

Windmill comes with a [native integration with S3, Azure Blob, and Google Cloud Storage](./meta-windmill-index-55.md), making them the recommended storage for large objects like files and binary data.
