---
doc_id: ops/fatsecret/guides-libraries
chunk_id: ops/fatsecret/guides-libraries#chunk-3
heading_path: ["FatSecret Platform API - Third-Party Libraries", "Third-Party Libraries"]
chunk_type: code
tokens: 45
summary: "Third-Party Libraries"
---

## Third-Party Libraries

### Python

#### pyfatsecret

A Python wrapper for the FatSecret Platform API.

**Installation:**
```bash
pip install fatsecret
```text

**Repository:** [pyfatsecret on GitHub](https://github.com/borucsan/pyfatsecret)

**Usage:**
```python
from fatsecret import Fatsecret

fs = Fatsecret(consumer_key, consumer_secret)
