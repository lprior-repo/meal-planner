---
doc_id: ops/features/import-export
chunk_id: ops/features/import-export#chunk-5
heading_path: ["Import Export", "Nextcloud"]
chunk_type: prose
tokens: 184
summary: "Nextcloud"
---

## Nextcloud

Importing recipes from Nextcloud cookbook is very easy and since Nextcloud Cookbook provides nice, standardized and
structured information most of your recipe is going to be intact.

Follow these steps to import your recipes

1. Go to your Nextcloud Webinterface
2. Find the `Recipes` folder (usually located in the root directory of your account)
3. Download that folder to get your `Recipes.zip` which includes the folder `Recipes` and in that a folder for each recipe
4. Upload the `Recipes.zip` to Tandoor and import it


!!! WARNING "Folder Structure"
    Importing only works if the folder structure is correct. If you do not use the standard path or create the
    zip file in any other way make sure the structure is as follows
    `  Recipes.zip/
        └── Recipes/
            ├── Recipe1/
            │   ├── recipe.json
            │   └── full.jpg
            └── Recipe2/
                ├── recipe.json
                └── full.jpg
    `
