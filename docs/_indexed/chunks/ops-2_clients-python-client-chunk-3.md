---
doc_id: ops/2_clients/python-client
chunk_id: ops/2_clients/python-client#chunk-3
heading_path: ["Python client", "Usage"]
chunk_type: prose
tokens: 101
summary: "Usage"
---

## Usage

The Python client provides several functions that you can use to interact with the Windmill platform. Here's an example of how to use the client to get a resource from Windmill:

```python
import wmill

def main():
    # Get a resource
    db_config = wmill.get_resource('u/user/db_config')

    # Get a variable
    api_key = wmill.get_variable('u/user/api_key')

    # Run a script asynchronously
    job_id = wmill.run_script_by_path_async('f/scripts/process_data', args={'input': 'value'})

    # Run a script synchronously and get result
    result = wmill.run_script_by_path('f/scripts/calculate', args={'x': 10, 'y': 20})
```
