---
doc_id: tutorial/11_persistent_storage/ducklake
chunk_id: tutorial/11_persistent_storage/ducklake#chunk-6
heading_path: ["Ducklake", "What Ducklake does behind the scenes"]
chunk_type: prose
tokens: 87
summary: "What Ducklake does behind the scenes"
---

## What Ducklake does behind the scenes

If you explore your catalog database, you will see that Ducklake created some tables for you. These metadata tables store information about your data and where it is located in S3 :

![Catalog database](./ducklake_images/ducklake_catalog_db.png 'Catalog database')

If you explore your selected workspace storage you will see your tables and their contents as columnar, parquet files :

![S3 content](./ducklake_images/ducklake_s3_content.png 'S3 content')
