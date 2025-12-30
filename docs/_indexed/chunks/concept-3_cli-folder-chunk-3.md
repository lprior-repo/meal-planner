---
doc_id: concept/3_cli/folder
chunk_id: concept/3_cli/folder#chunk-3
heading_path: ["Folder", "Push"]
chunk_type: prose
tokens: 89
summary: "Push"
---

## Push

The `wmill folder push` command is used to push a local folder specification to a remote location, overriding any existing remote versions.

```bash
wmill folder push <folder_path:string> <remote_path:string>
```

### Arguments

| Argument      | Description                                                      |
| ------------- | ---------------------------------------------------------------- |
| `folder_path` | The path to the local folder.                                    |
| `remote_path` | The path to the remote location where the folder will be pushed. |
