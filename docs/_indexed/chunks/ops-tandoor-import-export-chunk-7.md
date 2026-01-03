---
doc_id: ops/tandoor/import-export
chunk_id: ops/tandoor/import-export#chunk-7
heading_path: ["Import Export", "Chowdown"]
chunk_type: prose
tokens: 120
summary: "Chowdown"
---

## Chowdown

Chowdown stores all your recipes in plain text markdown files in a directory called `_recipes`.
Images are saved in a directory called `images`.

In order to import your Chowdown recipes simply create a `.zip` file from those two folders and import them.
The folder structure should look as follows

!!! info "_recipes"
    For some reason chowdown uses `_`before the`recipes`folder. To avoid confusion the import supports both `\_recipes`and`recipes`

```text
Recipes.zip/
    ├── _recipes/
    │   ├── recipe one.md
    │   ├── recipe two.md
    │   └── ...
    └── images/
        ├── image-name.jpg
        ├── second-image-name.jpg
        └── ...
```javascript
