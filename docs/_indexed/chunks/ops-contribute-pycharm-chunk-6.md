---
doc_id: ops/contribute/pycharm
chunk_id: ops/contribute/pycharm#chunk-6
heading_path: ["Pycharm", "Setup prettier"]
chunk_type: prose
tokens: 93
summary: "Setup prettier"
---

## Setup prettier

1. Navigate to File -> Settings -> Tools -> File Watchers
2. Click the '+' to add a new watcher.
3. Change 'File Type' to 'Any'.
4. Click the three dots next to 'Scope' to create a custom scope.
5. Click '+' to add a new scope

- Name: prettier
- Pattern: `file:vue/src//*||file:vue3/src//*||file:docs//*`

6. Configure the watcher as below.

   ![perttier_watcher](assets/prettier_watcher.png)

- Arguments: `--cwd $ProjectFileDir$\vue prettier -w --config $ProjectFileDir$\.prettierrc $FilePath$`
