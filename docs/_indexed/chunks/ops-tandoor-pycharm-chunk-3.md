---
doc_id: ops/tandoor/pycharm
chunk_id: ops/tandoor/pycharm#chunk-3
heading_path: ["Pycharm", "Setup flake8 Watcher"]
chunk_type: prose
tokens: 94
summary: "Setup flake8 Watcher"
---

## Setup flake8 Watcher

1. Navigate to File -> Settings -> Tools -> File Watchers
2. Click the '+' to add a new watcher.
3. Configure the watcher as below.

   ![flake8_watcher](assets/flake8_watcher.png)

4. Navigate to File -> Settings -> Editor -> Inspections -> File watcher problems
5. Under Severity select 'Edit Severities'
6. Click the '+' to add a severity calling it 'Linting Error'
7. Configure a background and effect as below.

   ![linting error](assets/linting_error.png)
