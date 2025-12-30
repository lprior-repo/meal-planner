---
doc_id: ops/2_clients/python-client
chunk_id: ops/2_clients/python-client#chunk-8
heading_path: ["Python client", "Write a file to S3"]
chunk_type: prose
tokens: 16
summary: "Write a file to S3"
---

## Write a file to S3
file_content = b'Hello Windmill!'
wmill.write_s3_file(s3_obj, file_content)
```
