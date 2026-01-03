---
doc_id: ops/tandoor/backup
chunk_id: ops/tandoor/backup#chunk-3
heading_path: ["Backup", "Mediafiles"]
chunk_type: prose
tokens: 93
summary: "Mediafiles"
---

## Mediafiles
The only Data this application stores apart from the database are the media files (e.g. images) used in your
recipes.

They can be found in the mediafiles mounted directory (depending on your installation).

To create a backup of those files simply copy them elsewhere. Do it the other way around for restoring.

The filenames consist of `<random uuid4>_<recipe_id>`. In case you screw up really badly this can help restore data.
