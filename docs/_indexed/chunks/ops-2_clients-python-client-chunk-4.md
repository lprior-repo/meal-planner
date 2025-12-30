---
doc_id: ops/2_clients/python-client
chunk_id: ops/2_clients/python-client#chunk-4
heading_path: ["Python client", "API reference"]
chunk_type: prose
tokens: 195
summary: "API reference"
---

## API reference

For detailed API documentation including all available methods, parameters, and return types, see the [Python SDK documentation](https://app.windmill.dev/pydocs/wmill.html).

### Core functions

The client provides both module-level convenience functions and a `Windmill` class for advanced usage:

#### Module-level functions

- `get_resource(path)` - Get a resource from Windmill
- `get_variable(path)` - Get a variable value
- `set_variable(path, value)` - Set a variable value
- `run_script_by_path(path, args)` - Run a script synchronously by path
- `run_script_by_hash(hash_, args)` - Run a script synchronously by hash
- `run_script_by_path_async(path, args)` - Run a script asynchronously by path
- `run_flow_async(path, args)` - Run a flow asynchronously
- `get_result(job_id)` - Get the result of a completed job
- `get_state()` - Get the script's state
- `set_state(value)` - Set the script's state

#### Windmill class

For advanced usage, you can instantiate the `Windmill` class directly:

```python
from wmill import Windmill

client = Windmill(
    base_url='http://localhost:8000',
    token='your_token',
    workspace='your_workspace'
)
