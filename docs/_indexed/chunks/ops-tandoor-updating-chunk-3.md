---
doc_id: ops/tandoor/updating
chunk_id: ops/tandoor/updating#chunk-3
heading_path: ["Updating", "Manual"]
chunk_type: prose
tokens: 75
summary: "Manual"
---

## Manual

For all setups using a manual installation updates usually involve downloading the latest source code from GitHub.
After that make sure to run:

1. `pip install -r requirements.txt`
2. `manage.py collectstatic`
3. `manage.py migrate`
4. `cd ./vue`
5. `yarn install`
6. `yarn build`

To install latest libraries, apply all new migrations and collect new static files.
