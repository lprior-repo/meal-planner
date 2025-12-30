---
doc_id: meta/36_service_logs/index
chunk_id: meta/36_service_logs/index#chunk-3
heading_path: ["Service logs", "Log storage"]
chunk_type: prose
tokens: 157
summary: "Log storage"
---

## Log storage

Windmill provides a flexible solution for log storage depending on your setup:

- **Standard Setup** (without [Enterprise Edition](/pricing)):
  Logs are stored locally on disk. For this to work, there must be a dedicated log disk, which is pre-configured in the Docker Compose setup.
  
- **Enterprise Edition** (with [Instance object storage](./meta-38_object_storage_in_windmill-index.md#instance-object-storage)):
  For users with the Enterprise Edition (EE), logs can be stored in S3 if instance object storage is configured. This option provides more scalable storage and is ideal for larger-scale deployments or where long-term log retention is important.

### Log retention

Windmill retains logs no older than two weeks. You can decide if this retention policy also applies to the logs stored on s3 through the Instance Settings.
