---
doc_id: tutorial/reference/troubleshooting
chunk_id: tutorial/reference/troubleshooting#chunk-6
heading_path: ["troubleshooting", "Debugging Tips"]
chunk_type: mixed
tokens: 100
summary: "Run `dagger call` with the `--interactive` (`-i` for short) flag to open a terminal in the contex..."
---
### Rerun commands with `--interactive`

Run `dagger call` with the `--interactive` (`-i` for short) flag to open a terminal in the context of a workflow failure.

### Rerun commands with `--debug`

Run any `dagger` subcommand with the `--debug` flag for more detailed output.

### Access the Dagger Engine logs

```bash
DAGGER_ENGINE_DOCKER_CONTAINER="$(docker container list --all --filter 'name=^dagger-engine-*' --format '{{.Names}}')"
docker logs $DAGGER_ENGINE_DOCKER_CONTAINER
```

### Enable SDK debug logs (Python)

```python
import logging
from dagger.log import configure_logging

configure_logging(logging.DEBUG)
```
