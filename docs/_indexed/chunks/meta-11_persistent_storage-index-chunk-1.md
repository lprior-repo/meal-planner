---
doc_id: meta/11_persistent_storage/index
chunk_id: meta/11_persistent_storage/index#chunk-1
heading_path: ["Persistent storage & databases"]
chunk_type: prose
tokens: 283
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Persistent storage & databases

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

Persistent storage refers to any method of storing data that remains intact and accessible even after a system is powered off, restarted, or experiences a crash.

In the context of Windmill, the stakes are: **where to effectively store and manage the data manipulated by Windmill** (ETL, data ingestion and preprocessing, data migration and sync etc.) ?

:::info TLDR

We recommend using **data tables** to store relational data, and **ducklakes** to store massive datasets.
Alternatively, you can connect your own database or S3 storage as a [resource](./meta-3_resources_and_types-index.md).

<br />

This present document gives a list of trusted services to use alongside Windmill.

:::

<br />

There are 5 kinds of persistent storage in Windmill:

1. [Data tables](#data-tables) for out-of-the-box relational data storage.

2. [Ducklakes](#ducklake) for data lakehouse storage.

3. [Small data](#within-windmill-not-recommended) that is relevant in between script/flow execution and can be persisted on Windmill itself.

4. [Object storage for large data](#large-data-s3-r2-minio-azure-blob-google-cloud-storage) such as S3.

5. [Big structured SQL data](#structured-sql-data-postgres-supabase-neontech) that is critical to your services and that is stored externally on an SQL Database or Data Warehouse.

6. [NoSQL and document database](#nosql--document-databases-mongodb-key-value-stores) such as MongoDB and Key-Value stores.
