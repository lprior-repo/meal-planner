---
doc_id: ops/2_clients/python-client
chunk_id: ops/2_clients/python-client#chunk-9
heading_path: ["Python client", "Notes"]
chunk_type: prose
tokens: 72
summary: "Notes"
---

## Notes

- The Python client automatically uses the `WM_TOKEN` environment variable for authentication when running inside Windmill
- The client is not thread or multi-processing safe. When using multithreading or multiprocessing, create a separate client instance per thread/process using `wmill.Windmill()`
- For complete API reference with all methods and parameters, see the [Python SDK documentation](https://app.windmill.dev/pydocs/wmill.html)
