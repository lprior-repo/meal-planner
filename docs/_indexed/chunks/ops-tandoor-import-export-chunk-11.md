---
doc_id: ops/tandoor/import-export
chunk_id: ops/tandoor/import-export#chunk-11
heading_path: ["Import Export", "ChefTap"]
chunk_type: prose
tokens: 169
summary: "ChefTap"
---

## ChefTap

ChefTaps allows you to export your recipes from the app (I think). The export is a zip file containing a folder called
`cheftap_export` which in turn contains `.txt` files with your recipes.

This format is basically completely unstructured and every export looks different. This makes importing it very hard
and leads to suboptimal results. Images are also not supported as they are not included in the export (at least
the tests I had).

Usually the import should recognize all ingredients and put everything else into the instructions. If your import fails
or is worse than this feel free to provide me with more example data and I can try to improve the importer.

As ChefTap cannot import these files anyway there won't be an exporter implemented in Tandoor.
