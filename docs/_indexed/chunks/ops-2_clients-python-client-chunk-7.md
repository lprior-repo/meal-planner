---
doc_id: ops/2_clients/python-client
chunk_id: ops/2_clients/python-client#chunk-7
heading_path: ["Python client", "Load a file from S3"]
chunk_type: prose
tokens: 15
summary: "Load a file from S3"
---

## Load a file from S3
s3_obj = S3Object(s3='/path/to/file.txt')
content = wmill.load_s3_file(s3_obj)
