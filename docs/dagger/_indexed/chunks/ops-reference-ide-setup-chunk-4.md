---
doc_id: ops/reference/ide-setup
chunk_id: ops/reference/ide-setup#chunk-4
heading_path: ["ide-setup", "Python"]
chunk_type: mixed
tokens: 74
summary: "To get your IDE to recognize a Dagger Python module, all dependencies must be installed in an act..."
---
To get your IDE to recognize a Dagger Python module, all dependencies must be installed in an activated virtual environment.

```bash
dagger develop
uv run code .
```

### Package Managers

- **uv**: `uv sync`
- **pip**: `pip install -r requirements.lock -e ./sdk -e .`
- **poetry**: `poetry run vim .`
- **hatch**: `hatch run dev:vim .`
